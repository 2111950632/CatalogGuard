"""Check a separately extracted Mooncakes package through a new consumer."""
import argparse
from pathlib import Path
import os
import re
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--moon", default=os.environ.get("SZS_MOON", "moon"))
    args = parser.parse_args()
    if Path(args.moon).is_file():
        args.moon = str(Path(args.moon).resolve())
    manifest = (ROOT / "moon.mod").read_text(encoding="utf8")
    version = re.search(r'version\s*=\s*"([^"]+)"', manifest).group(1)
    archive_path = ROOT / "_build" / "publish" / f"2111950632-szs-{version}.zip"
    if not archive_path.is_file():
        raise SystemExit("Build the package first: moon package")
    parent = ROOT / "_build" / "consumer-check"
    parent.mkdir(parents=True, exist_ok=True)
    workspace = Path(tempfile.mkdtemp(prefix="case-", dir=parent))
    package = workspace / "package"
    package.mkdir()
    with zipfile.ZipFile(archive_path) as archive:
        for member in archive.infolist():
            if not (package / member.filename).resolve().is_relative_to(package.resolve()):
                raise RuntimeError("Package archive leaves its extraction directory")
        archive.extractall(package)
    candidates = list(package.rglob("moon.mod"))
    if len(candidates) != 1:
        raise RuntimeError("Expected one packaged module")
    module = candidates[0].parent
    consumer = workspace / "consumer"
    consumer.mkdir()
    module_relative = module.relative_to(workspace).as_posix()
    (workspace / "moon.work").write_text(f'members = ["{module_relative}", "consumer"]\n', encoding="utf8")
    (consumer / "moon.mod").write_text(f'name = "szs-validation/consumer"\nversion = "0.1.0"\nimport {{ "2111950632/szs@{version}" }}\n', encoding="utf8")
    (consumer / "moon.pkg").write_text('import { "2111950632/szs", }\n', encoding="utf8")
    (consumer / "consumer.mbt").write_text('pub fn translated_count(source : String) -> Int { @szs.check_text(source).stats.translated }\n', encoding="utf8")
    (consumer / "consumer_wbtest.mbt").write_text('''test "packaged library public API" {
  let catalog = @szs.parse_catalog("msgid \\"file\\"\\nmsgstr \\"文件\\"\\n", file="consumer.po")
  assert_eq(catalog.entries[0].translation(0), Some("文件"))
  assert_eq(@szs.check_catalog(catalog).stats.translated, 1)
  assert_eq(translated_count("msgid \\"x\\"\\nmsgstr \\"X\\"\\n"), 1)
  assert_true(@szs.serialize_catalog(catalog) is Ok(_))
  let tree = @szs.parse_plural_expression("n != 1").unwrap()
  assert_eq(@szs.evaluate_plural(tree, 1), Ok(0))
  assert_eq(@szs.evaluate_plural(tree, 2), Ok(1))
}
''', encoding="utf8")
    for target in ["js", "wasm-gc"]:
        subprocess.run([args.moon, "test", "--target", target, "--deny-warn"], cwd=consumer, check=True, timeout=180)
    print(f"Independent packaged consumer passed on JS and Wasm GC: {workspace}")


if __name__ == "__main__":
    main()
