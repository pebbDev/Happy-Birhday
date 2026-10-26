"""Offline package contract tests. No Tencent API or Docker dependency."""
import importlib.util
from pathlib import Path
import stat
import tempfile
import unittest
import zipfile

SCRIPT = Path(__file__).resolve().parents[1] / "tools" / "package_scf.py"
spec = importlib.util.spec_from_file_location("package_scf", SCRIPT)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ScfZipContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / "stage"
        for name in module.REQUIRED:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("// compiled test fixture\n", encoding="utf-8")
        self.out = Path(self.tmp.name) / "artifact.zip"

    def test_bootstrap_and_compiled_files_have_expected_layout(self) -> None:
        count, digest = module.package(self.root, self.out)
        self.assertEqual(len(digest), 64)
        self.assertGreaterEqual(count, 3)
        with zipfile.ZipFile(self.out) as archive:
            self.assertIsNone(archive.testzip())
            for name in ("scf_bootstrap", *module.REQUIRED):
                self.assertIn(name, archive.namelist())
            self.assertTrue(archive.read("scf_bootstrap").startswith(b"#!/bin/sh\n"))
            self.assertTrue(archive.getinfo("scf_bootstrap").external_attr >> 16 & stat.S_IXUSR)

    def test_rejects_dotenv_or_secret_like_material(self) -> None:
        (self.root / ".env").write_text("TEST_SECRET=dummy\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Sensitive file name"):
            module.package(self.root, self.out)

    def test_existing_artifact_cannot_be_overwritten(self) -> None:
        self.out.write_bytes(b"existing-artifact")
        with self.assertRaisesRegex(ValueError, "already exists"):
            module.package(self.root, self.out)
        self.assertEqual(self.out.read_bytes(), b"existing-artifact")


if __name__ == "__main__":
    unittest.main()
