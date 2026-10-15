#!/usr/bin/env python3
"""Compose local packages with the native manager in isolated XDG directories."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


REPO = Path(__file__).resolve().parents[1]


def run(args, **kwargs):
    return subprocess.run(args, check=True, text=True, capture_output=True,
                          timeout=120, **kwargs).stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True, help="Ambxst Git checkout with release tags")
    parser.add_argument("--ambxst", default="ambxst", help="Native manager binary, version 1.3.12 or newer")
    parser.add_argument("--refs", nargs="+", default=["1.3.8", "1.3.9", "1.3.10", "1.3.11", "1.3.12"])
    parser.add_argument("--output", type=Path, help="Write the composition report as JSON")
    parser.add_argument("--require-all", action="store_true", help="Fail if any package excludes a requested base")
    parser.add_argument("--skip-command-checks", action="store_true",
                        help="Skip runtime command discovery in temporary package copies; check source composition")
    args = parser.parse_args()
    source = args.source.resolve()
    binary = shutil.which(args.ambxst)
    if not binary:
        parser.error(f"Ambxst binary not found: {args.ambxst}")
    packages = []
    for manifest_path in sorted((REPO / "packages").glob("*/ambxst.mod.json")):
        manifest = json.loads(manifest_path.read_text())
        packages.append((manifest_path.parent, manifest))
    results = []
    failed = False
    with tempfile.TemporaryDirectory(prefix="ambxst-mods-compat-") as directory:
        root = Path(directory)
        env = os.environ.copy()
        for name, folder in [("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                             ("XDG_STATE_HOME", "state"), ("XDG_CACHE_HOME", "cache"),
                             ("XDG_RUNTIME_DIR", "run")]:
            path = root / folder
            path.mkdir(mode=0o700)
            env[name] = str(path)
        env["LC_ALL"] = "C.UTF-8"
        env.pop("AMBXST_MODS_DISABLED", None)
        config = root / "config/ambxst"
        config.mkdir()
        package_root = root / "data/ambxst/mods/packages"
        package_root.mkdir(parents=True)
        for package, manifest in packages:
            destination = package_root / manifest["id"]
            shutil.copytree(package, destination,
                            ignore=shutil.ignore_patterns("__pycache__"))
            if args.skip_command_checks:
                copy_manifest = {**manifest, "commands": []}
                (destination / "ambxst.mod.json").write_text(json.dumps(copy_manifest))

        def check(base, selected):
            state = {"version": 1, "mods": [
                {"id": manifest["id"], "enabled": True, "order": index,
                 "source": str(package), "sourceType": "directory"}
                for index, (package, manifest) in enumerate(selected)
            ]}
            (config / "mods.json").write_text(json.dumps(state))
            output = run([binary, "mods", "check-compatibility", str(base)], env=env)
            # Progress belongs to stderr; stdout is the manager's JSON report.
            return json.loads(output)

        for index, ref in enumerate(args.refs):
            resolved_ref = ref
            if ref == "latest":
                tags = run(["git", "-C", str(source), "tag", "--sort=-version:refname"]).splitlines()
                resolved_ref = next((tag for tag in tags if re.fullmatch(r"\d+\.\d+\.\d+", tag)), None)
                if not resolved_ref:
                    parser.error("No stable release tags found in the Ambxst checkout")
            revision = run(["git", "-C", str(source), "rev-parse", f"{resolved_ref}^{{commit}}"]).strip()
            base = root / f"base-{index}"
            run(["git", "clone", "--shared", "--no-checkout", str(source), str(base)])
            run(["git", "-C", str(base), "checkout", "--detach", revision])
            env["AMBXST_SHELL"] = str(base)
            included = []
            for package, manifest in packages:
                report = check(base, [(package, manifest)])
                excluded = not report["composes"] and "does not match" in report.get("details", "")
                status = "outside-declared-range" if excluded else "pass" if report["composes"] else "fail"
                failed |= status == "fail" or (excluded and args.require_all)
                if status == "pass":
                    included.append((package, manifest))
                results.append({"ref": ref, "resolvedRef": resolved_ref, "revision": revision,
                                "package": package.name, "packageVersion": manifest["version"],
                                "status": status, **report})
                print(f"{ref:12} {package.name:28} {status}", flush=True)
                if status == "fail":
                    print(report.get("details", "No diagnostic returned"), flush=True)
            if included:
                report = check(base, included)
                status = "pass" if report["composes"] else "fail"
                failed |= status == "fail"
                results.append({"ref": ref, "resolvedRef": resolved_ref, "revision": revision, "package": "combined",
                                "packages": [m["id"] for _, m in included], "status": status, **report})
                print(f"{ref:12} {'combined':28} {status}", flush=True)
                if status == "fail":
                    print(report.get("details", "No diagnostic returned"), flush=True)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps({"runtimeTested": False,
                                          "runtimeCommandsChecked": not args.skip_command_checks,
                                          "results": results}, indent=2) + "\n")
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
