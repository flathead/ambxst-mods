#!/usr/bin/env python3
"""KDE Connect bridge for the Ambxst helper mod.

The process accepts one JSON object per line on stdin and returns one JSON
object per line on stdout. It never writes device names, shared text, or file
paths to logs.
"""

from __future__ import annotations

import json
import os
import pathlib
import re
import resource
import shutil
import subprocess
import sys
import tempfile
from typing import Any

try:
    import dbus
except ImportError:
    dbus = None


SERVICE = "org.kde.kdeconnect"
DAEMON_PATH = "/modules/kdeconnect"
OWNER_MARKER = "# Managed by Ambxst KDE Connect helper"
DEVICE_ID_RE = re.compile(r"^[A-Za-z0-9._:-]{1,128}$")
MAX_CAPTURE = 65536
MAX_TEXT = 4096
PRIVILEGED_EXECUTABLES = {
    "pkexec": ("/usr/bin/pkexec",),
    "pacman": ("/usr/bin/pacman",),
    "dnf": ("/usr/bin/dnf", "/usr/bin/dnf5"),
}


def stable_environment() -> dict[str, str]:
    environment = os.environ.copy()
    environment["LC_ALL"] = "C"
    environment["LANG"] = "C"
    return environment


def limit_output_files() -> None:
    resource.setrlimit(resource.RLIMIT_FSIZE, (MAX_CAPTURE, MAX_CAPTURE))


class CommandFailure(Exception):
    def __init__(self, code: str, detail: str = "") -> None:
        super().__init__(code)
        self.code = code
        self.detail = detail


def executable(name: str) -> str:
    candidate = shutil.which(name) or ""
    if not candidate:
        return ""
    path = pathlib.Path(candidate).resolve()
    if not path.is_absolute() or not path.is_file() or not os.access(path, os.X_OK):
        return ""
    return str(path)


def privileged_executable(name: str) -> str:
    for candidate in PRIVILEGED_EXECUTABLES.get(name, ()):
        path = pathlib.Path(candidate)
        try:
            resolved = path.resolve(strict=True)
            parent = resolved.parent.stat()
            metadata = resolved.stat()
        except OSError:
            continue
        if (
            resolved.is_file()
            and os.access(resolved, os.X_OK)
            and metadata.st_uid == 0
            and parent.st_uid == 0
            and parent.st_mode & 0o022 == 0
        ):
            return str(resolved)
    return ""


def run_bounded(
    argv: list[str], timeout: float = 8.0, input_text: str | None = None,
    capture: bool = True,
) -> tuple[int, str, str]:
    if not argv or not pathlib.Path(argv[0]).is_absolute():
        raise CommandFailure("invalid_executable")
    with tempfile.TemporaryFile() as stdout_file, tempfile.TemporaryFile() as stderr_file:
        process = subprocess.Popen(
            argv,
            stdin=subprocess.PIPE if input_text is not None else subprocess.DEVNULL,
            stdout=stdout_file if capture else subprocess.DEVNULL,
            stderr=stderr_file if capture else subprocess.DEVNULL,
            text=True,
            env=stable_environment(),
            preexec_fn=limit_output_files if capture else None,
        )
        try:
            if input_text is not None and process.stdin is not None:
                process.stdin.write(input_text)
                process.stdin.close()
            process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=2)
            raise CommandFailure("operation_timeout")
        stdout = ""
        stderr = ""
        if capture:
            stdout_file.seek(0)
            stderr_file.seek(0)
            stdout = stdout_file.read(MAX_CAPTURE).decode("utf-8", "replace")
            stderr = stderr_file.read(4096).decode("utf-8", "replace")
        return process.returncode, stdout, stderr


def qdbus_path() -> str:
    return executable("qdbus6") or executable("qdbus")


def qdbus_call(path: str, member: str, *args: str, timeout: float = 5.0) -> str:
    qdbus = qdbus_path()
    if not qdbus:
        raise CommandFailure("dbus_missing")
    code, stdout, _ = run_bounded(
        [qdbus, SERVICE, path, member, *args], timeout=timeout
    )
    if code != 0:
        raise CommandFailure("dbus_call_failed")
    return stdout.strip()


def private_dbus_call(path: str, interface: str, member: str, argument: str) -> None:
    if dbus is None:
        raise CommandFailure("python_dbus_missing")
    try:
        bus = dbus.SessionBus()
        proxy = bus.get_object(SERVICE, path, introspect=False)
        method = proxy.get_dbus_method(member, interface)
        method(argument, timeout=5)
    except dbus.DBusException as error:
        raise CommandFailure("dbus_call_failed") from error


def daemon_running() -> bool:
    qdbus = qdbus_path()
    if not qdbus:
        return False
    code, stdout, _ = run_bounded(
        [
            qdbus,
            "org.freedesktop.DBus",
            "/org/freedesktop/DBus",
            "org.freedesktop.DBus.NameHasOwner",
            SERVICE,
        ]
    )
    return code == 0 and stdout.strip() == "true"


def launcher_info() -> dict[str, str]:
    candidates = (
        ("kdeconnect-app", "application", []),
        ("kdeconnect-settings", "settings", []),
        ("kcmshell6", "system_settings", ["kcm_kdeconnect"]),
    )
    for name, kind, arguments in candidates:
        path = executable(name)
        if path:
            return {"path": path, "kind": kind, "arguments": arguments}
    return {"path": "", "kind": "none", "arguments": []}


def autostart_paths() -> dict[str, pathlib.Path]:
    home = pathlib.Path(os.environ.get("KCH_HOME") or pathlib.Path.home())
    config_home = pathlib.Path(
        os.environ.get("KCH_XDG_CONFIG_HOME") or os.environ.get("XDG_CONFIG_HOME") or home / ".config"
    )
    return {
        "service": config_home / "systemd/user/community-kde-connect-helper.service",
        "desktop": config_home / "autostart/community-kde-connect-helper.desktop",
        "mask": config_home / "autostart/org.kde.kdeconnect.daemon.desktop",
    }


def owned(path: pathlib.Path) -> bool:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return handle.readline().rstrip("\n") == OWNER_MARKER
    except OSError:
        return False


def require_owned_or_missing(path: pathlib.Path) -> None:
    if path.exists() and not owned(path):
        raise CommandFailure("autostart_conflict")


def system_autostart_path() -> pathlib.Path:
    return pathlib.Path(
        os.environ.get("KCH_SYSTEM_AUTOSTART")
        or "/etc/xdg/autostart/org.kde.kdeconnect.daemon.desktop"
    )


def systemd_user_available() -> bool:
    systemctl = executable("systemctl")
    if not systemctl:
        return False
    if os.environ.get("KCH_TEST_SYSTEMD") == "1":
        return True
    code, _, _ = run_bounded([systemctl, "--user", "show-environment"], timeout=4)
    return code == 0


def autostart_status() -> dict[str, str]:
    paths = autostart_paths()
    if owned(paths["mask"]):
        return {"state": "disabled", "method": "xdg_override", "path": str(paths["mask"])}
    if owned(paths["service"]):
        return {"state": "enabled", "method": "systemd", "path": str(paths["service"])}
    if owned(paths["desktop"]):
        return {"state": "enabled", "method": "xdg", "path": str(paths["desktop"])}
    system_entry = system_autostart_path()
    if system_entry.is_file():
        return {"state": "enabled", "method": "system", "path": str(system_entry)}
    if systemd_user_available():
        return {"state": "disabled", "method": "systemd", "path": str(paths["service"])}
    if str(paths["desktop"]):
        return {"state": "disabled", "method": "xdg", "path": str(paths["desktop"])}
    return {"state": "unavailable", "method": "manual", "path": ""}


def device_value(device_id: str, member: str, suffix: str = "") -> str:
    path = f"/modules/kdeconnect/devices/{device_id}{suffix}"
    return qdbus_call(path, member)


def has_plugin(device_id: str, plugin: str) -> bool:
    path = f"/modules/kdeconnect/devices/{device_id}"
    return qdbus_call(path, "org.kde.kdeconnect.device.hasPlugin", plugin) == "true"


def scan_fixture(path_value: str) -> dict[str, Any]:
    path = pathlib.Path(path_value)
    if not path.is_file() or path.stat().st_size > MAX_CAPTURE:
        raise CommandFailure("fixture_invalid")
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict) or not isinstance(data.get("devices", []), list):
        raise CommandFailure("fixture_invalid")
    return data


def scan(request: dict[str, Any]) -> dict[str, Any]:
    fixture = request.get("fixture")
    if fixture:
        if os.environ.get("KCH_ALLOW_FIXTURES") != "1":
            raise CommandFailure("fixture_disabled")
        return scan_fixture(str(fixture))

    cli = executable("kdeconnect-cli")
    daemon = executable("kdeconnectd")
    qdbus = qdbus_path()
    running = bool(qdbus) and daemon_running()
    devices: list[dict[str, Any]] = []
    if running:
        ids = qdbus_call(DAEMON_PATH, "org.kde.kdeconnect.daemon.devices").splitlines()
        for device_id in ids[:64]:
            device_id = device_id.strip()
            if not DEVICE_ID_RE.fullmatch(device_id):
                continue
            paired = device_value(device_id, "org.kde.kdeconnect.device.isPaired") == "true"
            reachable = device_value(device_id, "org.kde.kdeconnect.device.isReachable") == "true"
            name = device_value(device_id, "org.kde.kdeconnect.device.name")[:160]
            battery_plugin = has_plugin(device_id, "kdeconnect_battery")
            has_battery = False
            battery = -1
            charging = False
            if battery_plugin:
                has_battery = device_value(
                    device_id, "org.kde.kdeconnect.device.battery.hasBattery", "/battery"
                ) == "true"
                if has_battery:
                    charge_text = device_value(
                        device_id, "org.kde.kdeconnect.device.battery.charge", "/battery"
                    )
                    battery = int(charge_text) if charge_text.isdigit() else -1
                    charging = device_value(
                        device_id, "org.kde.kdeconnect.device.battery.isCharging", "/battery"
                    ) == "true"
            devices.append(
                {
                    "id": device_id,
                    "name": name,
                    "paired": paired,
                    "reachable": reachable,
                    "hasBattery": has_battery and 0 <= battery <= 100,
                    "battery": max(-1, min(100, battery)),
                    "charging": charging,
                    "supportsPing": has_plugin(device_id, "kdeconnect_ping"),
                    "supportsRing": has_plugin(device_id, "kdeconnect_findmyphone"),
                    "supportsShare": has_plugin(device_id, "kdeconnect_share"),
                    "supportsText": dbus is not None and has_plugin(device_id, "kdeconnect_share"),
                }
            )
    return {
        "installed": bool(cli),
        "daemonRunning": running,
        "cli": cli,
        "daemon": daemon,
        "qdbus": qdbus,
        "launcher": launcher_info(),
        "autostart": autostart_status(),
        "devices": devices,
    }


def require_device(request: dict[str, Any]) -> str:
    device_id = str(request.get("deviceId", ""))
    if not DEVICE_ID_RE.fullmatch(device_id):
        raise CommandFailure("invalid_device_id")
    if not daemon_running():
        raise CommandFailure("daemon_stopped")
    return device_id


def action(request: dict[str, Any]) -> dict[str, Any]:
    kind = str(request.get("kind", ""))
    if kind == "refresh":
        if not daemon_running():
            raise CommandFailure("daemon_stopped")
        qdbus_call(DAEMON_PATH, "org.kde.kdeconnect.daemon.forceOnNetworkChange")
        return {}
    device_id = require_device(request)
    base = f"/modules/kdeconnect/devices/{device_id}"
    if kind == "ping":
        if not has_plugin(device_id, "kdeconnect_ping"):
            raise CommandFailure("ping_unsupported")
        qdbus_call(base + "/ping", "org.kde.kdeconnect.device.ping.sendPing")
    elif kind == "ring":
        if not has_plugin(device_id, "kdeconnect_findmyphone"):
            raise CommandFailure("ring_unsupported")
        qdbus_call(base + "/findmyphone", "org.kde.kdeconnect.device.findmyphone.ring")
    elif kind == "share_file":
        if not has_plugin(device_id, "kdeconnect_share"):
            raise CommandFailure("file_unsupported")
        path = pathlib.Path(str(request.get("path", "")))
        if not path.is_absolute() or not path.is_file():
            raise CommandFailure("file_missing")
        qdbus_call(base + "/share", "org.kde.kdeconnect.device.share.shareUrl", path.as_uri())
    elif kind == "share_text":
        if not has_plugin(device_id, "kdeconnect_share"):
            raise CommandFailure("text_unsupported")
        text = str(request.get("text", ""))[:MAX_TEXT]
        if not text:
            raise CommandFailure("text_empty")
        private_dbus_call(
            base + "/share", "org.kde.kdeconnect.device.share", "shareText", text
        )
    else:
        raise CommandFailure("action_unsupported")
    return {}


def open_interface(request: dict[str, Any]) -> dict[str, Any]:
    launcher = launcher_info()
    if not launcher["path"]:
        raise CommandFailure("interface_missing")
    subprocess.Popen(
        [launcher["path"], *launcher["arguments"]],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
        env=stable_environment(),
    )
    return {"kind": launcher["kind"]}


def start_daemon(request: dict[str, Any]) -> dict[str, Any]:
    if daemon_running():
        return {"alreadyRunning": True}
    daemon = executable("kdeconnectd")
    if not daemon:
        raise CommandFailure("daemon_executable_missing")
    subprocess.Popen(
        [daemon],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
        env=stable_environment(),
    )
    return {"alreadyRunning": False}


def os_release() -> dict[str, str]:
    path = pathlib.Path(os.environ.get("KCH_OS_RELEASE") or "/etc/os-release")
    values: dict[str, str] = {}
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            values[key] = value.strip().strip('"')
    except OSError:
        pass
    return values


def install_plan(request: dict[str, Any]) -> dict[str, Any]:
    values = os_release()
    distro_id = values.get("ID", "unknown").lower()
    like = set(values.get("ID_LIKE", "").lower().split())
    family = "unknown"
    manager = "unknown"
    package = ""
    instruction = "manual"
    if distro_id in {"arch", "manjaro", "endeavouros"} or "arch" in like:
        family, manager, package, instruction = "arch", "pacman", "kdeconnect", "pacman"
    elif distro_id == "fedora" or {"fedora", "rhel"} & like:
        family, manager, package, instruction = "fedora", "dnf", "kde-connect", "dnf"
    elif distro_id == "nixos" or "nixos" in like:
        family, manager, package, instruction = "nixos", "nixos", "kdePackages.kdeconnect-kde", "nixos"
    manager_path = privileged_executable(manager) if manager in {"pacman", "dnf"} else ""
    pkexec = privileged_executable("pkexec")
    return {
        "distribution": values.get("PRETTY_NAME", values.get("NAME", ""))[:160],
        "distributionId": distro_id,
        "family": family,
        "manager": manager,
        "package": package,
        "method": instruction,
        "pkexec": bool(pkexec),
        "automatic": bool(manager_path and pkexec and family in {"arch", "fedora"}),
        "command": (
            "sudo pacman -S --needed kdeconnect"
            if family == "arch"
            else "sudo dnf install kde-connect"
            if family == "fedora"
            else "programs.kdeconnect.enable = true;"
            if family == "nixos"
            else ""
        ),
        "profileCommand": (
            "nix profile install nixpkgs#kdePackages.kdeconnect-kde" if family == "nixos" else ""
        ),
    }


def install(request: dict[str, Any]) -> dict[str, Any]:
    plan = install_plan({})
    if not plan["automatic"]:
        raise CommandFailure("install_manual_only")
    if str(request.get("family", "")) != plan["family"]:
        raise CommandFailure("install_plan_changed")
    pkexec = privileged_executable("pkexec")
    manager = privileged_executable(str(plan["manager"]))
    if not pkexec or not manager:
        raise CommandFailure("pkexec_missing")
    argv = (
        [pkexec, manager, "--sync", "--needed", "--noconfirm", "kdeconnect"]
        if plan["family"] == "arch"
        else [pkexec, manager, "install", "-y", "kde-connect"]
    )
    code, _, _ = run_bounded(argv, timeout=180, capture=False)
    if code != 0:
        raise CommandFailure("install_failed")
    if not executable("kdeconnect-cli"):
        raise CommandFailure("install_cli_missing")
    if not launcher_info()["path"]:
        raise CommandFailure("install_interface_missing")
    return {}


def atomic_write(path: pathlib.Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    descriptor, temporary_name = tempfile.mkstemp(prefix=".kde-connect-helper-", dir=path.parent)
    temporary = pathlib.Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def systemctl_user(*arguments: str, allow_failure: bool = False) -> None:
    systemctl = executable("systemctl")
    if not systemctl:
        if allow_failure:
            return
        raise CommandFailure("systemd_unavailable")
    if os.environ.get("KCH_TEST_SYSTEMD") == "1":
        return
    code, _, _ = run_bounded([systemctl, "--user", *arguments], timeout=10)
    if code != 0 and not allow_failure:
        raise CommandFailure("systemd_failed")


def enable_autostart(request: dict[str, Any]) -> dict[str, Any]:
    daemon = executable("kdeconnectd")
    if not daemon:
        raise CommandFailure("daemon_executable_missing")
    if any(character.isspace() for character in daemon):
        raise CommandFailure("autostart_path_unsafe")
    paths = autostart_paths()
    require_owned_or_missing(paths["mask"])
    if owned(paths["mask"]):
        paths["mask"].unlink()
        if system_autostart_path().is_file():
            return {"method": "system", "path": str(system_autostart_path())}
    if systemd_user_available():
        require_owned_or_missing(paths["service"])
        atomic_write(
            paths["service"],
            f"{OWNER_MARKER}\n[Unit]\nDescription=KDE Connect daemon\nAfter=graphical-session.target\n\n"
            f"[Service]\nType=dbus\nBusName={SERVICE}\nExecStart={daemon}\nRestart=on-failure\n\n"
            "[Install]\nWantedBy=default.target\n",
        )
        systemctl_user("daemon-reload")
        systemctl_user("enable", "community-kde-connect-helper.service")
        return {"method": "systemd", "path": str(paths["service"])}
    require_owned_or_missing(paths["desktop"])
    atomic_write(
        paths["desktop"],
        f"{OWNER_MARKER}\n[Desktop Entry]\nType=Application\nName=KDE Connect daemon\n"
        f"Exec={daemon}\nTerminal=false\nX-GNOME-Autostart-enabled=true\n",
    )
    return {"method": "xdg", "path": str(paths["desktop"])}


def disable_autostart(request: dict[str, Any]) -> dict[str, Any]:
    paths = autostart_paths()
    if system_autostart_path().is_file():
        require_owned_or_missing(paths["mask"])
    changed = False
    if owned(paths["service"]):
        systemctl_user("disable", "community-kde-connect-helper.service", allow_failure=True)
        paths["service"].unlink()
        systemctl_user("daemon-reload", allow_failure=True)
        changed = True
    if owned(paths["desktop"]):
        paths["desktop"].unlink()
        changed = True
    if system_autostart_path().is_file():
        atomic_write(
            paths["mask"],
            f"{OWNER_MARKER}\n[Desktop Entry]\nType=Application\n"
            "Name=KDE Connect daemon\nHidden=true\n",
        )
        changed = True
    if not changed:
        raise CommandFailure("autostart_unavailable")
    return {"method": "disabled", "path": str(paths["mask"] if paths["mask"].exists() else "")}


HANDLERS = {
    "scan": scan,
    "action": action,
    "open": open_interface,
    "start_daemon": start_daemon,
    "install_plan": install_plan,
    "install": install,
    "enable_autostart": enable_autostart,
    "disable_autostart": disable_autostart,
}


def respond(request: dict[str, Any]) -> dict[str, Any]:
    request_id = request.get("id")
    command = str(request.get("command", ""))
    handler = HANDLERS.get(command)
    if handler is None:
        return {"id": request_id, "ok": False, "code": "command_unknown"}
    try:
        return {"id": request_id, "ok": True, "code": command + "_complete", "data": handler(request)}
    except CommandFailure as error:
        return {"id": request_id, "ok": False, "code": error.code, "detail": error.detail[:160]}
    except (OSError, ValueError, json.JSONDecodeError):
        return {"id": request_id, "ok": False, "code": "operation_failed"}


def main() -> int:
    for line in sys.stdin:
        if len(line) > 16384:
            result = {"id": None, "ok": False, "code": "request_too_large"}
        else:
            try:
                request = json.loads(line)
                result = respond(request if isinstance(request, dict) else {})
            except json.JSONDecodeError:
                result = {"id": None, "ok": False, "code": "request_invalid"}
        sys.stdout.write(json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n")
        sys.stdout.flush()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
