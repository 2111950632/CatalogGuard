"""Independent parser checks against polib; optional GNU msgfmt checks."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import polib

ROOT = Path(__file__).resolve().parents[1]


def cli(*args):
    result = subprocess.run(["node", str(ROOT / "cli.mjs"), *map(str, args)], cwd=ROOT,
                            text=True, encoding="utf-8", capture_output=True, timeout=30)
    if result.returncode not in (0, 1):
        raise AssertionError(result.stderr or result.stdout)
    return json.loads(result.stdout)


def compare(path):
    expected = polib.pofile(str(path), encoding="utf-8", check_for_duplicates=True)
    actual = cli("inspect", path, "--json")["files"][0]
    errors = [d for d in actual["diagnostics"] if d["severity"] == "error"]
    assert not errors, errors
    entries = [e for e in actual["entries"] if not (e["id"] == "" and e["context"] is None)]
    assert len(entries) == len(expected), (path, len(entries), len(expected))
    for got, wanted in zip(entries, expected):
        assert got["id"] == wanted.msgid, (path, wanted.msgid)
        assert got["context"] == wanted.msgctxt, (path, wanted.msgid, "context")
        assert got["plural"] == (wanted.msgid_plural or None), (path, wanted.msgid, "plural")
        translations = {t["index"]: t["value"] for t in got["translations"]}
        wanted_translations = {int(k): v for k, v in wanted.msgstr_plural.items()} if wanted.msgid_plural else {0: wanted.msgstr}
        assert translations == wanted_translations, (path, wanted.msgid, "translations")
        assert got["obsolete"] == bool(wanted.obsolete), (path, wanted.msgid, "obsolete")
        assert set(got["flags"]) == set(wanted.flags), (path, wanted.msgid, "flags")
    print(f"polib agrees: {path.name}, {len(entries)} entries")
    return len(entries)


def gnu(executable=None):
    executable = executable or shutil.which("msgfmt")
    if not executable:
        raise RuntimeError("--gnu requires GNU msgfmt on PATH")
    version = subprocess.run([executable, "--version"], text=True, capture_output=True, check=True).stdout.splitlines()[0]
    print(version)
    cases = [(ROOT / "examples" / "zh_CN.po", True),
             (ROOT / "examples" / "broken.po", False),
             (ROOT / "tests" / "fixtures" / "gnu-format-mismatch.po", False)]
    for path, expected_success in cases:
        # GNU normally skips fuzzy translations. Include drafts so that the
        # deliberately broken plural/format entry is actually checked.
        result = subprocess.run([str(executable), "--check", "--check-format", "--use-fuzzy", "-o", "-", str(path)],
                                stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=30)
        diagnostics = cli(path, "--json")["files"][0]["diagnostics"]
        szs_success = not any(d["severity"] == "error" for d in diagnostics)
        assert szs_success == expected_success, (path.name, diagnostics)
        assert (result.returncode == 0) == expected_success, (path.name, result.stderr.decode("utf8", "replace"))
        print(f"GNU outcome agrees: {path.name}, success={expected_success}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="*", type=Path)
    parser.add_argument("--gnu", action="store_true")
    parser.add_argument("--msgfmt", default=os.environ.get("SZS_MSGFMT"),
                        help="GNU msgfmt executable (default: search PATH)")
    args = parser.parse_args()
    paths = [ROOT / "examples" / "zh_CN.po", ROOT / "examples" / "messages.pot", *args.paths]
    total = sum(compare(path) for path in paths)
    print(f"Independent parser comparison passed: {len(paths)} files, {total} entries")
    if args.gnu:
        gnu(args.msgfmt)
