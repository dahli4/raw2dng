"""Locate dnglab and run RAW → DNG conversions."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

RAW_EXTENSIONS = {
    ".arw",
    ".cr2",
    ".cr3",
    ".crw",
    ".dng",
    ".erf",
    ".iiq",
    ".kdc",
    ".mef",
    ".mos",
    ".mrw",
    ".nef",
    ".nrw",
    ".orf",
    ".pef",
    ".raf",
    ".raw",
    ".rw2",
    ".rwl",
    ".sr2",
    ".srf",
    ".srw",
    ".x3f",
}


class DnglabNotFoundError(RuntimeError):
    pass


def _candidate_bins() -> list[Path]:
    env = os.environ.get("RAW2DNG_DNGLAB") or os.environ.get("DNGLAB")
    here = Path(__file__).resolve().parent
    # Next to installed package, next to frozen exe, cwd, PATH
    candidates: list[Path] = []
    if env:
        candidates.append(Path(env))
    if getattr(sys, "frozen", False):
        candidates.append(Path(sys.executable).resolve().parent / "dnglab")
        candidates.append(Path(sys.executable).resolve().parent / "dnglab.exe")
    candidates.extend(
        [
            Path.cwd() / "dnglab",
            Path.cwd() / "dnglab.exe",
            here.parent.parent.parent / "vendor" / "dnglab",
            Path.home() / ".local" / "bin" / "dnglab",
        ]
    )
    return candidates


def find_dnglab() -> str:
    for path in _candidate_bins():
        if path.is_file() and os.access(path, os.X_OK):
            return str(path)
        # Windows .exe may not have X_OK the same way
        if path.is_file() and path.suffix.lower() == ".exe":
            return str(path)
    which = shutil.which("dnglab")
    if which:
        return which
    raise DnglabNotFoundError(
        "dnglab 실행 파일을 찾지 못했습니다.\n"
        "  1) GitHub Release에서 OS용 패키지를 받거나\n"
        "  2) https://github.com/dnglab/dnglab/releases 에서 dnglab을 받아 PATH에 두거나\n"
        "  3) RAW2DNG_DNGLAB=/path/to/dnglab 환경변수를 설정하세요.\n"
        "설치 도우미: bash scripts/install_dnglab.sh"
    )


def is_raw_file(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in RAW_EXTENSIONS


def collect_inputs(path: Path, recursive: bool) -> list[Path]:
    if path.is_file():
        return [path]
    if not path.is_dir():
        raise FileNotFoundError(f"입력 경로가 없습니다: {path}")
    pattern = "**/*" if recursive else "*"
    files = [p for p in sorted(path.glob(pattern)) if is_raw_file(p)]
    return files


def default_output_for(inp: Path, output: Path | None, batch: bool) -> Path:
    if output is None:
        return inp.with_suffix(".dng")
    if batch or output.is_dir() or (not output.suffix and not output.exists()):
        # treat as directory target
        out_dir = output
        out_dir.mkdir(parents=True, exist_ok=True)
        return out_dir / (inp.stem + ".dng")
    return output


def convert(
    inputs: list[Path],
    output: Path | None,
    *,
    recursive: bool = False,
    force: bool = False,
    compression: str = "lossless",
    jobs: int | None = None,
    embed_raw: bool = True,
    extra_args: list[str] | None = None,
) -> int:
    dnglab = find_dnglab()
    if len(inputs) == 1 and inputs[0].is_dir():
        # pass directory straight through to dnglab
        inp = inputs[0]
        if output is None:
            raise ValueError("폴더 변환 시 출력 폴더를 지정하세요: raw2dng <입력폴더> <출력폴더>")
        output.mkdir(parents=True, exist_ok=True)
        cmd = [dnglab, "convert"]
        if force:
            cmd.append("-f")
        if recursive:
            cmd.append("-r")
        if compression:
            cmd.extend(["-c", compression])
        if jobs is not None:
            cmd.extend(["-j", str(jobs)])
        cmd.extend(["--embed-raw", "true" if embed_raw else "false"])
        if extra_args:
            cmd.extend(extra_args)
        cmd.extend([str(inp), str(output)])
        return subprocess.call(cmd)

    files: list[Path] = []
    for item in inputs:
        if item.is_dir():
            files.extend(collect_inputs(item, recursive))
        else:
            files.append(item)

    if not files:
        print("변환할 RAW 파일이 없습니다.", file=sys.stderr)
        return 1

    batch = len(files) > 1 or (output is not None and (output.is_dir() or not output.suffix))
    failures = 0
    for inp in files:
        out = default_output_for(inp, output, batch=batch)
        out.parent.mkdir(parents=True, exist_ok=True)
        if out.exists() and not force:
            print(f"건너뜀 (이미 있음, -f로 덮어쓰기): {out}", file=sys.stderr)
            continue
        cmd = [dnglab, "convert"]
        if force:
            cmd.append("-f")
        if compression:
            cmd.extend(["-c", compression])
        cmd.extend(["--embed-raw", "true" if embed_raw else "false"])
        if extra_args:
            cmd.extend(extra_args)
        cmd.extend([str(inp), str(out)])
        print(f"{inp.name} → {out}")
        rc = subprocess.call(cmd)
        if rc != 0:
            failures += 1
    return 1 if failures else 0
