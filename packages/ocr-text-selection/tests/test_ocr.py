import importlib.util
import io
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image

HELPER = Path(__file__).resolve().parents[1] / "payload/scripts/ocr_text_selection.py"
spec = importlib.util.spec_from_file_location("ocr_helper", HELPER)
ocr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ocr)


def word(text, confidence, paragraph=1, line=1, left=10):
    return f"5\t1\t1\t{paragraph}\t{line}\t1\t{left}\t{10 + (line - 1) * 30}\t40\t20\t{confidence}\t{text}"


def png(color=(10, 10, 10, 255)):
    out = io.BytesIO()
    Image.new("RGBA", (20, 10), color).save(out, format="PNG")
    return out.getvalue()


class OCRTests(unittest.TestCase):
    def test_unicode_paragraphs_and_character_weight(self):
        lines = ocr.parse_tsv("\n".join([word("Открой", 90), word("页面", 60, left=60), word("상품", 80, paragraph=2)]))
        self.assertEqual(ocr.join_lines(lines), "Открой 页面\n\n상품")
        self.assertAlmostEqual(lines[0]["confidence"], 82.5)
        with self.assertRaises(ValueError):
            ocr.parse_tsv(word("bad", "nan"))

    def test_improve_only_matching_lines_with_clear_confidence_gain(self):
        original = ocr.parse_tsv("\n".join([word("old", 70), word("keep", 85, line=2)]))
        retry = ocr.parse_tsv("\n".join([word("correct", 90), word("marginal", 90, line=2)]))
        self.assertEqual(ocr.join_lines(ocr.improve_lines(original, retry)), "correct\nkeep")
        retry[0]["bounds"] = (300, 300, 340, 320)
        self.assertEqual(ocr.improve_lines(original, retry)[0]["text"], "old")

    def test_dark_background_and_transparency(self):
        for data in [png(), png((0, 0, 0, 0))]:
            prepared, scale, border = ocr.prepare_png(data)
            image = Image.open(io.BytesIO(prepared))
            self.assertEqual((scale, border, image.size), (3, 10, (80, 50)))
            self.assertEqual(image.getpixel((0, 0)), 255)
            self.assertGreaterEqual(image.getpixel((10, 10)), 245)

    def test_invalid_inputs_and_missing_model(self):
        with self.assertRaises(ValueError):
            ocr.read_png("relative.png")
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                ocr.read_png(directory)
            path = Path(directory) / "bad.png"
            path.write_bytes(b"not a PNG")
            with self.assertRaises(ValueError):
                ocr.read_png(str(path))
        with self.assertRaises(ValueError):
            ocr.recognize(png(), "eng;echo")
        result = subprocess.CompletedProcess([], 0, b"", b"Failed loading language 'rus'")
        with patch.object(ocr.subprocess, "run", return_value=result), self.assertRaises(RuntimeError):
            ocr.run_tesseract(png(), "eng+rus")

    def test_capture_before_review_without_clipboard_write(self):
        captured = []
        files = []
        def run(command, **kwargs):
            self.assertEqual(command[:4], ["ambxst", "ipc", "call", "screenshot.capture"])
            params = json.loads(command[4])
            self.assertFalse(params["clipboard"])
            self.assertEqual(params["mode"], "region")
            path = Path(params["outPath"])
            self.assertEqual(path.parent.stat().st_mode & 0o777, 0o700)
            path.write_bytes(png())
            files.append(path)
            return subprocess.CompletedProcess(command, 0, b"{}", b"")
        with patch.object(ocr.subprocess, "run", side_effect=run), patch.object(ocr, "recognize", return_value="Открой 页面 상품"), patch.object(ocr, "send", side_effect=captured.append), patch.object(ocr, "copy_text") as copy:
            result = ocr.handle(dict(command="region", x=-100, y=20, width=300, height=200, langs="eng+rus+chi_sim+kor"))
            copy.assert_not_called()
        self.assertEqual(result["text"], "Открой 页面 상품")
        self.assertEqual(captured, [{"event": "captured"}])
        self.assertFalse(files[0].exists())

    def test_explicit_copy_preserves_selected_text(self):
        text = "  Открой\n请打开\n상품  "
        with patch.object(ocr.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)) as run:
            self.assertEqual(ocr.handle(dict(command="copy", text=text)), {"copied": True})
            self.assertEqual(run.call_args.kwargs["input"].decode("utf-8"), text)
        with patch.object(ocr, "read_png", return_value=png()), patch.object(ocr, "recognize", return_value=""), patch.object(ocr, "copy_text") as copy:
            ocr.handle(dict(command="file", path="/saved.png"))
            copy.assert_not_called()

    @unittest.skipUnless(shutil.which("tesseract") and shutil.which("pango-view"), "needs Tesseract and pango-view")
    def test_real_multilingual_ocr(self):
        models = subprocess.check_output(["tesseract", "--list-langs"], text=True).splitlines()
        if not {"eng", "rus"}.issubset(models):
            self.skipTest("needs English and Russian models")
        text = "Open the product page. Order number: 1280.\nОткрой страницу продуктов. Номер заказа: 1280."
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "text.png"
            subprocess.run(["pango-view", "--no-display", "--font=Sans 18", "--background=#202020", "--foreground=#ffffff", "--margin=12", "--text=" + text, "--output=" + str(path)], check=True)
            recognized = ocr.recognize(ocr.read_png(str(path)), "eng+rus")
        self.assertIn("Open the product page", recognized)
        self.assertIn("Открой страницу продуктов", recognized)
        self.assertIn("1280", recognized)


if __name__ == "__main__":
    unittest.main()
