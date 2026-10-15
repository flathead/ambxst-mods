# Changelog

## 1.0.1 - 2026-10-15

- Verify individual and combined composition on Ambxst 1.3.9 through 1.3.12 and runtime loading on 1.3.12.
- Allow compatible 1.3.x releases; scheduled checks test the latest release and development sources.

## 1.0.0

- Pass all enabled OCR language flags through the same recognition path.
- Improve uncertain screen text with LSTM recognition, dark-background normalization, and conservative line retries.
- Add text recognition to saved screenshot previews.
- Review, edit, and select recognized text before copying from the toolbar OCR action.
- Move the result window by dragging its header.
- Run with the stock Ambxst binary through a local Python helper.
- Translate interface labels into English, Russian, and Spanish.
