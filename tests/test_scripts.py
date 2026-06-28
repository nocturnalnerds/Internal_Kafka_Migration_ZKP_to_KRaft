import os
import pathlib
import subprocess
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPTS = [
    "scripts/precheck.sh",
    "scripts/migrate.sh",
    "scripts/verify.sh",
    "scripts/finalize.sh",
    "scripts/rollback.sh",
]


class MigrationScriptsContract(unittest.TestCase):
    def test_scripts_exist_and_are_executable(self):
        for script in SCRIPTS:
            path = ROOT / script
            with self.subTest(script=script):
                self.assertTrue(path.exists())
                self.assertTrue(os.access(path, os.X_OK))

    def test_scripts_parse_as_bash(self):
        for script in SCRIPTS + ["scripts/lib/common.sh"]:
            with self.subTest(script=script):
                subprocess.run(["bash", "-n", str(ROOT / script)], check=True)

    def test_dry_run_paths_do_not_require_cluster(self):
        env = os.environ.copy()
        env["CONFIRM_FINALIZE"] = "yes"
        env["CONFIRM_ROLLBACK"] = "yes"
        env["DRY_RUN"] = "true"
        for script in SCRIPTS:
            with self.subTest(script=script):
                subprocess.run(
                    [str(ROOT / script), "--dry-run", "--skip-live-checks"],
                    cwd=ROOT,
                    env=env,
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )

    def test_compose_overrides_are_present(self):
        for path in ["docker-compose.migration.yml", "docker-compose.kraft.yml"]:
            with self.subTest(path=path):
                self.assertTrue((ROOT / path).exists())

