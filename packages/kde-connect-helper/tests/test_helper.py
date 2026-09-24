from __future__ import annotations

import importlib.util
import json
import os
import pathlib
import shutil
import tempfile
import types
import unittest
from unittest import mock


PACKAGE = pathlib.Path(__file__).resolve().parents[1]
HELPER_PATH = PACKAGE / "payload/scripts/kde_connect_helper.py"
SPEC = importlib.util.spec_from_file_location("kde_connect_helper", HELPER_PATH)
assert SPEC and SPEC.loader
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


class HelperTests(unittest.TestCase):
    def install_plan(self, content: str) -> dict[str, object]:
        with tempfile.TemporaryDirectory() as directory:
            release = pathlib.Path(directory) / "os-release"
            release.write_text(content, encoding="utf-8")
            with mock.patch.dict(os.environ, {"KCH_OS_RELEASE": str(release)}, clear=False):
                return helper.install_plan({})

    def test_distribution_families(self) -> None:
        cases = (
            ("ID=arch\nPRETTY_NAME=Arch Linux\n", "arch", "pacman", "kdeconnect"),
            ("ID=endeavouros\nID_LIKE=arch\n", "arch", "pacman", "kdeconnect"),
            ("ID=fedora\n", "fedora", "dnf", "kde-connect"),
            ("ID=ultramarine\nID_LIKE=fedora\n", "fedora", "dnf", "kde-connect"),
            ("ID=nixos\n", "nixos", "nixos", "kdePackages.kdeconnect-kde"),
            ("ID=unknown-linux\n", "unknown", "unknown", ""),
        )
        for content, family, manager, package in cases:
            with self.subTest(family=family, content=content):
                plan = self.install_plan(content)
                self.assertEqual(plan["family"], family)
                self.assertEqual(plan["manager"], manager)
                self.assertEqual(plan["package"], package)

    def test_fixture_states(self) -> None:
        fixture_dir = PACKAGE / "tests/fixtures"
        expected_counts = {
            "missing.json": 0,
            "daemon-stopped.json": 0,
            "no-devices.json": 0,
            "offline.json": 1,
            "connected.json": 1,
            "multiple.json": 2,
        }
        with mock.patch.dict(os.environ, {"KCH_ALLOW_FIXTURES": "1"}, clear=False):
            for name, count in expected_counts.items():
                with self.subTest(name=name):
                    result = helper.scan({"fixture": str(fixture_dir / name)})
                    self.assertEqual(len(result["devices"]), count)
            multiple = helper.scan({"fixture": str(fixture_dir / "multiple.json")})
            self.assertTrue(multiple["devices"][0]["hasBattery"])
            self.assertFalse(multiple["devices"][1]["hasBattery"])
            stopped = helper.scan({"fixture": str(fixture_dir / "daemon-stopped.json")})
            self.assertTrue(stopped["installed"])
            self.assertFalse(stopped["daemonRunning"])

    def test_malformed_fixture_is_rejected(self) -> None:
        with tempfile.NamedTemporaryFile("w", encoding="utf-8") as fixture:
            fixture.write("not json")
            fixture.flush()
            with mock.patch.dict(os.environ, {"KCH_ALLOW_FIXTURES": "1"}, clear=False):
                response = helper.respond({"id": 7, "command": "scan", "fixture": fixture.name})
        self.assertFalse(response["ok"])
        self.assertEqual(response["code"], "operation_failed")

    def test_invalid_device_id_is_rejected_before_dbus(self) -> None:
        response = helper.respond({"id": 8, "command": "action", "kind": "ping", "deviceId": "bad id;"})
        self.assertFalse(response["ok"])
        self.assertEqual(response["code"], "invalid_device_id")

    def test_timeout_is_bounded(self) -> None:
        sleep = pathlib.Path("/usr/bin/sleep")
        if not sleep.exists():
            self.skipTest("sleep is unavailable")
        with self.assertRaisesRegex(helper.CommandFailure, "operation_timeout"):
            helper.run_bounded([str(sleep), "1"], timeout=0.01)

    def test_command_output_is_bounded(self) -> None:
        python = shutil.which("python3")
        if not python:
            self.skipTest("python3 is unavailable")
        _, stdout, _ = helper.run_bounded(
            [python, "-c", "import sys; sys.stdout.write('x' * 200000)"], timeout=2
        )
        self.assertLessEqual(len(stdout.encode("utf-8")), helper.MAX_CAPTURE)

    def test_non_captured_process_does_not_inherit_capture_file_limit(self) -> None:
        process = mock.Mock()
        process.returncode = 0
        with mock.patch.object(helper.subprocess, "Popen", return_value=process) as popen:
            helper.run_bounded(["/usr/bin/true"], capture=False)
        self.assertIsNone(popen.call_args.kwargs["preexec_fn"])

    def test_privileged_discovery_ignores_path_injection(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            fake = pathlib.Path(directory) / "pkexec"
            fake.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
            fake.chmod(0o755)
            with mock.patch.dict(os.environ, {"PATH": directory}, clear=False):
                self.assertNotEqual(helper.privileged_executable("pkexec"), str(fake))

    def test_autostart_only_removes_owned_files(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            for name in ("kdeconnectd", "systemctl"):
                path = bin_dir / name
                path.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
                path.chmod(0o755)
            environment = {
                "PATH": str(bin_dir),
                "KCH_HOME": str(root),
                "KCH_XDG_CONFIG_HOME": str(root / "config"),
                "KCH_SYSTEM_AUTOSTART": str(root / "missing-system-entry.desktop"),
                "KCH_TEST_SYSTEMD": "1",
            }
            with mock.patch.dict(os.environ, environment, clear=False):
                result = helper.enable_autostart({})
                service = pathlib.Path(result["path"])
                self.assertTrue(helper.owned(service))
                helper.disable_autostart({})
                self.assertFalse(service.exists())

                foreign = service
                foreign.parent.mkdir(parents=True, exist_ok=True)
                foreign.write_text("foreign content\n", encoding="utf-8")
                with self.assertRaisesRegex(helper.CommandFailure, "autostart_unavailable"):
                    helper.disable_autostart({})
                self.assertEqual(foreign.read_text(encoding="utf-8"), "foreign content\n")

    def test_system_xdg_autostart_is_restored_without_duplicate_service(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            for name in ("kdeconnectd", "systemctl"):
                path = bin_dir / name
                path.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
                path.chmod(0o755)
            system_entry = root / "system-kdeconnect.desktop"
            system_entry.write_text("[Desktop Entry]\nType=Application\n", encoding="utf-8")
            environment = {
                "PATH": str(bin_dir),
                "KCH_HOME": str(root),
                "KCH_XDG_CONFIG_HOME": str(root / "config"),
                "KCH_SYSTEM_AUTOSTART": str(system_entry),
                "KCH_TEST_SYSTEMD": "1",
            }
            with mock.patch.dict(os.environ, environment, clear=False):
                helper.disable_autostart({})
                paths = helper.autostart_paths()
                self.assertTrue(helper.owned(paths["mask"]))
                result = helper.enable_autostart({})
                self.assertEqual(result["method"], "system")
                self.assertFalse(paths["mask"].exists())
                self.assertFalse(paths["service"].exists())

    def test_autostart_rejects_unrepresentable_daemon_path(self) -> None:
        for directory_name in ("bin with space", "bin%specifier"):
            with self.subTest(directory_name=directory_name), tempfile.TemporaryDirectory() as directory:
                root = pathlib.Path(directory)
                bin_dir = root / directory_name
                bin_dir.mkdir()
                daemon = bin_dir / "kdeconnectd"
                daemon.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
                daemon.chmod(0o755)
                with mock.patch.dict(os.environ, {"PATH": str(bin_dir)}, clear=False):
                    with self.assertRaisesRegex(helper.CommandFailure, "autostart_path_unsafe"):
                        helper.enable_autostart({})

    def test_json_response_does_not_echo_sensitive_fields(self) -> None:
        response = helper.respond({"id": 9, "command": "unknown", "text": "private text", "path": "/private/file"})
        encoded = json.dumps(response)
        self.assertNotIn("private text", encoded)
        self.assertNotIn("/private/file", encoded)

    def test_private_text_uses_dbus_without_process_arguments(self) -> None:
        method = mock.Mock()
        proxy = mock.Mock()
        proxy.get_dbus_method.return_value = method
        bus = mock.Mock()
        bus.get_object.return_value = proxy
        binding = types.SimpleNamespace(
            SessionBus=mock.Mock(return_value=bus),
            DBusException=RuntimeError,
        )
        with mock.patch.object(helper, "dbus", binding):
            helper.private_dbus_call("/fixture/share", "fixture.interface", "shareText", "private text")
        method.assert_called_once_with("private text", timeout=5)

    def test_multiple_file_share_validates_and_sends_each_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            first = pathlib.Path(directory) / "first.txt"
            second = pathlib.Path(directory) / "second.txt"
            first.write_text("first", encoding="utf-8")
            second.write_text("second", encoding="utf-8")
            with mock.patch.object(helper, "daemon_running", return_value=True), mock.patch.object(
                helper, "has_plugin", return_value=True
            ), mock.patch.object(helper, "qdbus_call") as call:
                helper.action({
                    "kind": "share_files",
                    "deviceId": "valid-device-id",
                    "paths": [str(first), str(second)],
                })
        self.assertEqual(call.call_count, 2)


class PackageIntegrationTests(unittest.TestCase):
    def test_bar_widget_exports_loader_dimensions(self) -> None:
        widget = (PACKAGE / "payload/modules/bar/KdeConnectHelper.qml").read_text(encoding="utf-8")
        feature_patch = (PACKAGE / "patches/feature.patch").read_text(encoding="utf-8")
        self.assertIn("implicitWidth: vertical ? 36", widget)
        self.assertIn("implicitHeight: 36", widget)
        self.assertEqual(feature_patch.count("Layout.preferredWidth: active ?"), 4)
        self.assertEqual(feature_patch.count("Layout.preferredHeight: active ?"), 4)

    def test_bar_widget_uses_native_ambxst_states(self) -> None:
        widget = (PACKAGE / "payload/modules/bar/KdeConnectHelper.qml").read_text(encoding="utf-8")
        self.assertIn('variant: helperPopup.isOpen ? "primary" : "bg"', widget)
        self.assertIn('color: Styling.srItem("overprimary")', widget)
        self.assertIn("barButton.hovered || barButton.activeFocus", widget)
        self.assertIn("anchorItem: buttonBackground", widget)
        self.assertIn("function buttonOutlinePoints", widget)
        self.assertIn("function strokeFraction", widget)
        self.assertIn("const topLeft = buttonBackground.topLeftRadius", widget)
        self.assertIn("const bottomRight = buttonBackground.bottomRightRadius", widget)
        self.assertNotIn("setLineDash", widget)
        self.assertIn("strokeFraction(context, points, value / 100)", widget)
        self.assertIn(
            "anchors.fill: parent\n                visible: root.showBatteryOutline && root.hasBattery",
            widget,
        )
        self.assertIn("readonly property string buttonLabel", widget)
        self.assertIn("readonly property string selectedContent", widget)
        self.assertIn('KdeConnectService.appearance === "compact"', widget)
        self.assertIn("readonly property bool batteryGlyphIsPercentage", widget)
        self.assertIn(
            'KdeConnectService.displayMode === "battery"\n        && batteryPercentage.length > 0',
            widget,
        )
        self.assertIn("? batteryPercentage", widget)
        self.assertIn("? Icons.lightning : Icons.deviceMobile", widget)
        self.assertIn('&& KdeConnectService.displayMode !== "battery"', widget)
        self.assertIn("return device.name;", widget)
        self.assertIn("KdeConnectService.warningBatteryColor", widget)
        self.assertIn("text: root.mainGlyph", widget)
        self.assertIn("id: helperButtonBackground", widget)
        self.assertIn("color: helperButtonBackground.item", widget)
        self.assertIn("control.danger ? Colors.red : helperButtonBackground.item", widget)
        self.assertIn("function onStartRadiusChanged()", widget)
        self.assertIn("function onEndRadiusChanged()", widget)
        self.assertIn("function onVerticalChanged()", widget)
        self.assertIn(
            'variant: shareText.hovered || shareText.activeFocus ? "focus" : "internalbg"',
            widget,
        )

    def test_zero_low_battery_threshold_remains_valid(self) -> None:
        service = (PACKAGE / "payload/modules/services/KdeConnectService.qml").read_text(
            encoding="utf-8"
        )
        self.assertIn("Number.isFinite(threshold) ? threshold : 20", service)

    def test_tray_setting_hides_only_kde_connect_items(self) -> None:
        feature_patch = (PACKAGE / "patches/feature.patch").read_text(encoding="utf-8")
        service = (PACKAGE / "payload/modules/services/KdeConnectService.qml").read_text(
            encoding="utf-8"
        )
        self.assertIn("function isKdeConnectItem", feature_patch)
        self.assertIn('identity.includes("kde connect")', feature_patch)
        self.assertIn("hideKdeConnectTrayIcon", service)

    def test_file_sharing_uses_the_desktop_portal(self) -> None:
        widget = (PACKAGE / "payload/modules/bar/KdeConnectHelper.qml").read_text(encoding="utf-8")
        service = (PACKAGE / "payload/modules/services/KdeConnectService.qml").read_text(
            encoding="utf-8"
        )
        helper_source = HELPER_PATH.read_text(encoding="utf-8")
        self.assertNotIn("QtQuick.Dialogs", widget)
        self.assertNotIn("FileDialog {", widget)
        self.assertIn('send("choose_files", { title:', service)
        self.assertIn('I18n.t("kde_connect_helper.choose_file")', widget)
        self.assertIn('"org.freedesktop.portal.FileChooser"', helper_source)
        self.assertIn('"multiple": dbus.Boolean(True)', helper_source)
        self.assertIn('request_object.Close(dbus_interface="org.freedesktop.portal.Request")', helper_source)

    def test_mod_text_fields_have_a_distinct_resting_surface(self) -> None:
        feature_patch = (PACKAGE / "patches/feature.patch").read_text(encoding="utf-8")
        self.assertIn('sourceInput.activeFocus ? 2 : 0', feature_patch)
        self.assertIn('settingInput.activeFocus ? 2 : 0', feature_patch)
        self.assertIn(
            'variant: sourceInput.hovered || sourceInput.activeFocus ? "focus" : "internalbg"',
            feature_patch,
        )
        self.assertIn(
            'variant: settingInput.hovered || settingInput.activeFocus ? "focus" : "internalbg"',
            feature_patch,
        )

    def test_follow_up_scan_keeps_action_feedback(self) -> None:
        service = (PACKAGE / "payload/modules/services/KdeConnectService.qml").read_text(
            encoding="utf-8"
        )
        widget = (PACKAGE / "payload/modules/bar/KdeConnectHelper.qml").read_text(
            encoding="utf-8"
        )
        self.assertIn('if (command !== "scan")', service)
        self.assertIn('kde_connect_helper.message.daemon_executable_missing', widget)


if __name__ == "__main__":
    unittest.main()
