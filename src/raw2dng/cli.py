"""raw2dng command-line interface."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from raw2dng import __version__
from raw2dng.converter import DnglabNotFoundError, convert, find_dnglab


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="raw2dng",
        description="카메라 RAW 파일을 Adobe DNG로 변환합니다 (dnglab 사용).",
    )
    p.add_argument("input", nargs="+", help="RAW 파일 또는 폴더")
    p.add_argument(
        "output",
        nargs="?",
        default=None,
        help="출력 .dng 경로 또는 폴더 (생략 시 입력과 같은 이름 .dng)",
    )
    p.add_argument("-r", "--recursive", action="store_true", help="폴더를 재귀적으로 변환")
    p.add_argument("-f", "--force", action="store_true", help="기존 .dng 덮어쓰기")
    p.add_argument(
        "-c",
        "--compression",
        choices=("lossless", "uncompressed"),
        default="lossless",
        help="DNG 압축 (기본: lossless)",
    )
    p.add_argument("-j", "--jobs", type=int, default=None, help="병렬 작업 수 (폴더 변환 시)")
    p.add_argument(
        "--no-embed-raw",
        action="store_true",
        help="원본 RAW를 DNG 안에 넣지 않음",
    )
    p.add_argument("--which-dnglab", action="store_true", help="사용할 dnglab 경로만 출력")
    p.add_argument("-V", "--version", action="version", version=f"raw2dng {__version__}")
    return p


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.which_dnglab:
        try:
            print(find_dnglab())
            return 0
        except DnglabNotFoundError as e:
            print(e, file=sys.stderr)
            return 2

    inputs = [Path(x).expanduser().resolve() for x in args.input]
    output = Path(args.output).expanduser().resolve() if args.output else None

    # If last positional looks like output when multiple inputs given via nargs+
    # argparse already split input... output. For `raw2dng a.CR2 b.CR2 outdir`
    # user should pass outdir as output — with nargs+ on input, they need:
    # raw2dng a.CR2 b.CR2 -o outdir  OR we support trailing dir.
    # Current signature: input+ [output] so: raw2dng a.CR2 b.CR2 outdir works
    # only if we put all but last in input when last is dir-like.
    # Fix: if multiple inputs and no output, and last has no raw suffix / is dir, treat as output.
    if output is None and len(inputs) >= 2:
        last = inputs[-1]
        raw_exts = {".cr2", ".cr3", ".nef", ".arw", ".raf", ".orf", ".rw2", ".dng", ".raw"}
        if last.is_dir() or last.suffix.lower() not in raw_exts:
            output = last
            inputs = inputs[:-1]

    try:
        return convert(
            inputs,
            output,
            recursive=args.recursive,
            force=args.force,
            compression=args.compression,
            jobs=args.jobs,
            embed_raw=not args.no_embed_raw,
        )
    except DnglabNotFoundError as e:
        print(e, file=sys.stderr)
        return 2
    except (FileNotFoundError, ValueError) as e:
        print(e, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
