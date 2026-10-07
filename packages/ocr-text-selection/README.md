# OCR text selection

Select an area from the toolbar OCR action, review the recognized text, and copy a selection or the full result. You can edit mistakes before copying, cancel a pending request, and drag the window by its header. The screenshot preview also has a text recognition button; that action copies text from the saved PNG.

The helper passes each enabled language flag from Ambxst settings to Tesseract. It uses the LSTM engine and retries uncertain images after dark-background normalization, nearest-neighbor enlargement, and border padding. It replaces a matching line only when confidence improves by at least ten points. Recognition can still produce incorrect characters and numbers, especially with several script models enabled.

## Install

Requires stock Ambxst 1.3.9, Python 3 with Pillow, Tesseract, `wl-copy`, and the traineddata files for your selected languages. This mod uses the stock screenshot IPC service and a Python helper; you do not need a patched Ambxst binary. Install Pillow through your distribution, for example `python-pillow` on Arch or `python3-pillow` on Fedora. The manager checks executables; it cannot check Python imports or traineddata files. The review window reports missing dependencies when you run OCR.

```bash
ambxst mods install https://github.com/flathead/ambxst-mods/tree/main/packages/ocr-text-selection
ambxst mods enable community.ocr-text-selection
ambxst reload
```

Run this package with the stock source tree. Its compatibility range covers the version tested here; an upstream release that incorporates the feature should use the core implementation instead.

## Validation

```bash
python3 -m unittest discover -s packages/ocr-text-selection/tests -v
```

The tests cover TSV Unicode and paragraphs, conservative line replacement, image preparation, invalid files and models, capture without clipboard writes, and explicit text copying. Tests with real Tesseract require installed language models. Native QML checks cover helper requests, callback cancellation, and dragging the result window.

The upstream implementation is in [Ambxst PR #249](https://github.com/Axenide/Ambxst/pull/249).
