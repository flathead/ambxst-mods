### Task 8: Fix the i18n loading race

**Files:**
- Modify: `modules/services/I18n.qml`

**Root cause:** translations load through an async `FileView` while `t()` returns the key itself when the map is empty. Anything rendered before the JSON arrives keeps the key. In Quickshell 0.3.0 `blockLoading` applies only to an explicit `text()` or `data()` call, so waiting on `onLoaded` stays asynchronous no matter what the flag says.

- [ ] **Step 1: Add the revision counter and a humanized fallback**

Replace the property block and `t()`:

```qml
    property var strings: ({})
    property var fallback: ({})
    property var availableLanguages: ({})
    property bool ready: false
    // Bumped after every successful load. t() reads it so that every binding
    // which calls t() takes a dependency and re-evaluates on language change.
    property int revision: 0

    // Last resort when a key is missing entirely: "notifications.clear_all"
    // renders as "Clear all" rather than leaking the key into the UI.
    function humanize(key) {
        const seg = key.substring(key.lastIndexOf(".") + 1).replace(/_/g, " ");
        return seg.charAt(0).toUpperCase() + seg.slice(1);
    }

    function t(key) {
        const rev = root.revision; // dependency capture, do not remove
        let str = root.strings[key] ?? root.fallback[key] ?? root.humanize(key);
        for (let i = 1; i < arguments.length; i++)
            str = str.replace("%" + i, arguments[i]);
        return str;
    }
```

- [ ] **Step 2: Make the loaders synchronous**

Replace all three `FileView` blocks and the `onResolvedLanguageChanged` handler:

```qml
    FileView {
        id: languagesLoader
        path: Qt.resolvedUrl("../../translations/languages.json")
        blockLoading: true
    }

    FileView {
        id: fallbackLoader
        path: Qt.resolvedUrl("../../translations/en.json")
        blockLoading: true
    }

    FileView {
        id: langLoader
        path: root.resolvedLanguage !== "en"
              ? Qt.resolvedUrl("../../translations/" + root.resolvedLanguage + ".json")
              : ""
        blockLoading: true
    }

    // blockLoading only takes effect on an explicit text() call, so read the
    // files here rather than waiting for onLoaded. The maps must be populated
    // before the first binding evaluates, otherwise raw keys reach the screen.
    function loadAll() {
        try {
            root.availableLanguages = JSON.parse(languagesLoader.text());
        } catch (e) {
            console.warn("I18n: failed to parse languages.json:", e);
            root.availableLanguages = { "en": "English" };
        }

        try {
            root.fallback = JSON.parse(fallbackLoader.text());
        } catch (e) {
            console.warn("I18n: failed to parse en.json:", e);
            root.fallback = ({});
        }

        root.resolvedLanguage = root.resolveLanguage();

        if (root.resolvedLanguage === "en") {
            root.strings = root.fallback;
        } else {
            try {
                root.strings = JSON.parse(langLoader.text());
            } catch (e) {
                console.warn("I18n: failed to parse " + root.resolvedLanguage + ".json:", e);
                root.strings = root.fallback;
            }
        }

        root.ready = Object.keys(root.fallback).length > 0;
        root.revision++;
    }

    Component.onCompleted: root.loadAll()

    onConfigLanguageChanged: root.loadAll()
```

Remove the old `onConfigLanguageChanged` and `onResolvedLanguageChanged` handlers that only assigned `resolvedLanguage`, since `loadAll()` now owns that.

- [ ] **Step 3: Verify the tree loads**

```bash
~/.local/src/ambxst-mods/qml-check.sh ~/.local/src/ambxst
```

Expected: `PASS`

- [ ] **Step 4: Verify no raw keys at startup**

The system locale is `ru_RU.UTF-8`, so a cold start exercises the non-English path.

```bash
ambxst reload
```

Expected: the bar, dashboard and settings show Russian text immediately, with no dotted identifiers anywhere. Open the settings window and scan the sidebar and every panel heading.

- [ ] **Step 5: Verify runtime language switching**

In settings, switch language to English, then to Spanish, then back to Russian. Expected: every visible string updates without restarting the shell. Before the revision counter, strings assembled once kept the previous language.

- [ ] **Step 6: Commit**

```bash
git add modules/services/I18n.qml
git commit -m "fix(i18n): load translations synchronously and re-evaluate on change

Translations loaded through an async FileView while t() returned the key when
the map was empty, so anything rendered before the JSON arrived kept the key on
screen. In Quickshell 0.3.0 blockLoading applies only to an explicit text() or
data() call, so waiting on onLoaded stayed asynchronous regardless of the flag.

Read the files explicitly during initialization, bump a revision counter that
t() reads so bindings re-evaluate on language change, and humanize the last
segment when a key is missing instead of leaking the identifier."
```

---

