### Task 9: Close i18n coverage across the new upstream UI

**Files:**
- Create: `scripts/i18n-check.sh`
- Modify: `translations/en.json`, `translations/ru.json`, `translations/es.json`
- Modify: QML files reported as carrying unwrapped strings

**Measured baseline, taken on the merged tree before this task was dispatched.**
The situation is not what the spec assumed, so do not re-derive it:

- `translations/en.json` holds 751 keys; `ru.json` and `es.json` are both at full
  parity with it, missing nothing. Language files do not need backfilling.
- 592 keys are referenced from QML. Every one resolves; the only apparent misses
  are dynamic prefixes such as `I18n.t("settings.shell." + name)`, which the
  checker must not report as missing.
- 163 keys are defined but unreferenced. Leave them: they are cheap, and deleting
  keys risks breaking dynamic lookups. Report the count, do not act on it.
- The new upstream tools are ALREADY wrapped. `ScreenshotTool.qml` and
  `ToolsMenu.qml` contain zero raw literals. The spec's assumption that they
  arrived hardcoded is obsolete: the merge in Task 3 wrapped them.

The real remaining gap is about 41 unwrapped user-visible literals across
`text:`, `label:`, `title:`, `placeholderText:`, `description:` and `summary:`.
Ignore `name:` — those 48 occurrences are internal identifiers, not UI copy.

Eight of those literals are in OUR OWN feature files and will ship in the pull
requests, which makes them the priority: `BarResourceMonitor.qml` (5),
`AudioDeviceSwitcher.qml` (2), `CalendarPanel.qml` (1).

- [ ] **Step 1: Write the coverage checker**

Shell rather than Python, because upstream dropped python from its dependencies in `dc243132`.

```bash
cat > scripts/i18n-check.sh <<'EOF'
#!/usr/bin/env bash
# Report translation keys used in QML but missing from en.json, and string
# literals in QML that are still unwrapped. Run from the repository root.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EN="$ROOT/translations/en.json"
status=0

# Keys referenced from QML.
grep -rhoE 'I18n\.t\("([^"]+)"' "$ROOT/modules" \
  | sed -E 's/I18n\.t\("//' | sort -u > /tmp/i18n-used.txt

# Keys defined in en.json.
grep -oE '^\s*"[^"]+"\s*:' "$EN" | sed -E 's/^\s*"//; s/"\s*:$//' | sort -u > /tmp/i18n-defined.txt

missing=$(comm -23 /tmp/i18n-used.txt /tmp/i18n-defined.txt)
if [ -n "$missing" ]; then
  echo "Keys used in QML but missing from en.json:"
  echo "$missing" | sed 's/^/  /'
  status=1
fi

unused=$(comm -13 /tmp/i18n-used.txt /tmp/i18n-defined.txt)
if [ -n "$unused" ]; then
  echo "Keys defined but never used:"
  echo "$unused" | sed 's/^/  /'
fi

# Unwrapped user-visible literals.
echo "Unwrapped text: literals:"
grep -rnE '^\s*text:\s*"[^"]+"' "$ROOT/modules" \
  | grep -vE 'I18n\.t|text:\s*""' | sed 's/^/  /' || true

exit $status
EOF
chmod +x scripts/i18n-check.sh
```

- [ ] **Step 2: Run it and capture the gap list**

```bash
cd ~/.local/src/ambxst && ./scripts/i18n-check.sh | tee /tmp/i18n-gaps.txt
```

Expected: a list of missing keys and unwrapped literals, dominated by the new upstream tools.

- [ ] **Step 3: Wrap the reported literals**

For every file in the unwrapped list, replace `text: "Some string"` with `text: I18n.t("scope.some_string")`, adding `import qs.modules.services` where the file lacks it. Follow the existing key naming: lowercase, dot-separated scope, snake_case leaf, scope named after the feature (`screenshot.`, `recorder.`, `ocr.`, `qr.`, `colorpicker.`, `brightness.`).

- [ ] **Step 4: Add the keys to all three translation files**

Add every new key to `en.json` and `ru.json` with real translations. Add them to `es.json` machine-assisted, and note in the PR description that Spanish is machine-assisted and welcomes review from a native speaker.

- [ ] **Step 5: Verify coverage is clean**

```bash
cd ~/.local/src/ambxst && ./scripts/i18n-check.sh; echo "rc=$?"
```

Expected: `rc=0`, no missing keys, and no unwrapped literals other than deliberate non-text values.

- [ ] **Step 6: Verify all three languages render**

```bash
~/.local/src/ambxst-mods/qml-check.sh ~/.local/src/ambxst && ambxst reload
```

Open the screenshot tool, the recorder, OCR, QR and the colour picker under each language. Expected: no dotted identifiers and no untranslated English while another language is selected.

- [ ] **Step 7: Commit**

```bash
git add scripts/i18n-check.sh translations modules
git commit -m "i18n: cover the new upstream tools and add a coverage checker

Screenshots, recording, OCR, QR, the colour picker and brightness arrived with
hardcoded strings. Wrap them, add the keys to English, Russian and Spanish, and
add scripts/i18n-check.sh so missing keys and unwrapped literals are reported
instead of accumulating unnoticed.

Spanish is machine-assisted and would benefit from review by a native speaker."
```

---

