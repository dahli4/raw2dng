import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_help():
    env = {**dict(**__import__("os").environ), "PYTHONPATH": str(ROOT / "src")}
    r = subprocess.run(
        [sys.executable, "-m", "raw2dng", "-h"],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
    )
    assert r.returncode == 0
    assert "RAW" in r.stdout or "dng" in r.stdout.lower()
