#!/usr/bin/env python3
"""OCR helper for stock Ambxst. Implements the recognition path from PR #249."""

import io
import json
import math
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile

MAX_BYTES = 32 * 1024 * 1024
MAX_PIXELS = 40_000_000


def read_png(path):
    if not isinstance(path, str) or not os.path.isabs(path):
        raise ValueError("Screenshot path must be absolute")
    info = os.stat(path)
    if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_BYTES:
        raise ValueError("Screenshot must be a regular PNG below 32 MiB")
    with open(path, "rb") as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_BYTES:
            raise ValueError("Screenshot must be a regular PNG below 32 MiB")
        data = stream.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES or not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("Screenshot must be a PNG below 32 MiB")
    return data


def parse_tsv(text):
    lines = []
    last_key = None
    for row in text.splitlines():
        fields = row.split("\t", 11)
        if len(fields) != 12 or fields[0] != "5" or not fields[11].strip():
            continue
        left, top, width, height = map(int, fields[6:10])
        confidence = float(fields[10])
        if min(left, top, width, height) < 0 or not math.isfinite(confidence) or not 0 <= confidence <= 100:
            raise ValueError("Invalid Tesseract word bounds or confidence")
        paragraph = ":".join(fields[1:4])
        key = paragraph + ":" + fields[4]
        bounds = (left, top, left + width, top + height)
        if key != last_key:
            lines.append(dict(text="", paragraph=paragraph, bounds=bounds, confidence=0, weight=0))
            last_key = key
        line = lines[-1]
        word = fields[11]
        line["text"] += (" " if line["text"] else "") + word
        line["confidence"] += confidence * len(word)
        line["weight"] += len(word)
        a, b, c, d = line["bounds"]
        line["bounds"] = (min(a, left), min(b, top), max(c, left + width), max(d, top + height))
    for line in lines:
        line["confidence"] /= line["weight"]
    return lines


def run_tesseract(data, langs):
    result = subprocess.run(
        ["tesseract", "-", "-", "-l", langs, "--oem", "1", "tsv"],
        input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30,
    )
    error = result.stderr.decode("utf-8", errors="replace").strip()
    if result.returncode or "Failed loading language" in error:
        raise RuntimeError("Tesseract: " + (error or "Recognition failed"))
    return parse_tsv(result.stdout.decode("utf-8"))


def average_confidence(lines):
    weight = sum(line["weight"] for line in lines)
    return sum(line["confidence"] * line["weight"] for line in lines) / weight if weight else 0


def prepare_png(data):
    from PIL import Image, ImageOps
    with Image.open(io.BytesIO(data)) as source:
        rgba = source.convert("RGBA")
    white = Image.new("RGBA", rgba.size, (255, 255, 255, 255))
    gray = Image.alpha_composite(white, rgba).convert("L")
    count = 0
    for median, value in enumerate(gray.histogram()):
        count += value
        if count > gray.width * gray.height // 2:
            break
    if median < 128:
        gray = ImageOps.invert(gray)
    scale = 3
    while scale > 1 and gray.width * gray.height * scale * scale > 12_000_000:
        scale -= 1
    gray = gray.resize((gray.width * scale, gray.height * scale), Image.Resampling.NEAREST)
    gray = ImageOps.expand(gray, border=10, fill=255)
    out = io.BytesIO()
    gray.save(out, format="PNG")
    return out.getvalue(), scale, 10


def improve_lines(original, retry):
    if not original:
        return retry
    out = [dict(line) for line in original]
    used = set()
    for i, line in enumerate(original):
        best, overlap = None, 0
        a, b, c, d = line["bounds"]
        for j, candidate in enumerate(retry):
            if j in used:
                continue
            e, f, g, h = candidate["bounds"]
            area = max(0, min(c, g) - max(a, e)) * max(0, min(d, h) - max(b, f))
            union = (c - a) * (d - b) + (g - e) * (h - f) - area
            match = area / union if area and union else 0
            if match > overlap:
                best, overlap = j, match
        if best is not None and overlap >= 0.5:
            used.add(best)
            if retry[best]["confidence"] >= line["confidence"] + 10:
                out[i]["text"] = retry[best]["text"]
    return out


def join_lines(lines):
    text = ""
    for i, line in enumerate(lines):
        if i:
            text += "\n\n" if line["paragraph"] != lines[i - 1]["paragraph"] else "\n"
        text += line["text"]
    return text


def recognize(data, langs):
    from PIL import Image
    if not isinstance(langs, str) or not re.fullmatch(r"[A-Za-z0-9_]+(?:\+[A-Za-z0-9_]+)*", langs):
        raise ValueError("Invalid OCR languages")
    with Image.open(io.BytesIO(data)) as image:
        if image.format != "PNG" or image.width * image.height > MAX_PIXELS:
            raise ValueError("Screenshot must be a PNG below 40 megapixels")
    original = run_tesseract(data, langs)
    if average_confidence(original) >= 95:
        return join_lines(original)
    prepared, scale, border = prepare_png(data)
    try:
        retry = run_tesseract(prepared, langs)
    except (RuntimeError, subprocess.TimeoutExpired):
        return join_lines(original)
    for line in retry:
        a, b, c, d = line["bounds"]
        # Match Go integer division, including small negative border coordinates.
        line["bounds"] = tuple(math.trunc(value / scale) for value in (a - border, b - border, c - border + scale - 1, d - border + scale - 1))
    return join_lines(improve_lines(original, retry))


def copy_text(text):
    if not isinstance(text, str) or len(text.encode("utf-8")) > MAX_BYTES:
        raise ValueError("Invalid clipboard text")
    result = subprocess.run(["wl-copy", "--type", "text/plain;charset=utf-8"],
                            input=text.encode("utf-8"), stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL, timeout=5)
    if result.returncode:
        raise RuntimeError("Could not copy text")


def send(result):
    print(json.dumps(result, ensure_ascii=False), flush=True)


def handle(request):
    command = request.get("command")
    if command == "copy":
        copy_text(request.get("text"))
        return {"copied": True}
    langs = request.get("langs", "eng")
    if command == "file":
        text = recognize(read_png(request.get("path")), langs)
        if text:
            copy_text(text)
        return {"text": text}
    if command == "region":
        rect = {key: request.get(key) for key in ("x", "y", "width", "height")}
        if any(type(value) is not int for value in rect.values()) or rect["width"] <= 0 or rect["height"] <= 0:
            raise ValueError("Invalid screenshot region")
        if rect["width"] * rect["height"] > MAX_PIXELS:
            raise ValueError("Screenshot exceeds 40 megapixels")
        with tempfile.TemporaryDirectory(prefix="ambxst-ocr-") as directory:
            path = str(Path(directory) / "capture.png")
            params = dict(rect, mode="region", clipboard=False, outPath=path)
            result = subprocess.run(["ambxst", "ipc", "call", "screenshot.capture", json.dumps(params)],
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
            if result.returncode:
                raise RuntimeError(result.stderr.decode("utf-8", errors="replace").strip() or "Screenshot failed")
            data = read_png(path)
        # Open the review window only after capture, so it stays out of the PNG.
        send({"event": "captured"})
        return {"text": recognize(data, langs)}
    raise ValueError("Unknown OCR operation")


def main():
    try:
        raw = sys.stdin.buffer.readline(MAX_BYTES + 1)
        if len(raw) > MAX_BYTES:
            raise ValueError("OCR request exceeds 32 MiB")
        request = json.loads(raw)
        if not isinstance(request, dict):
            raise ValueError("OCR request must be an object")
        send({"result": handle(request)})
    except Exception as error:
        send({"error": str(error)})
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
