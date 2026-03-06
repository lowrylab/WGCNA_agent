#!/usr/bin/env python3
"""Initialize a run-specific WGCNA output directory near source data files.

Purpose:
- Resolve the source data directory from one or more input file paths.
- Create a run-specific output directory under that source directory.
- Print the absolute output directory path for downstream scripts.
"""

from __future__ import annotations

import argparse
import os
from datetime import datetime
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Create a run-specific output directory inside the source data directory."
        ),
    )
    parser.add_argument(
        "--input-file",
        action="append",
        default=[],
        help=(
            "Input file (or directory) path. Repeat for multiple inputs. "
            "Used to infer the source data directory."
        ),
    )
    parser.add_argument(
        "--source-dir",
        default=None,
        help=(
            "Explicit source data directory. If set, overrides inference from "
            "--input-file."
        ),
    )
    parser.add_argument(
        "--name-prefix",
        default="wgcna_hitl_outputs",
        help="Output directory prefix (default: wgcna_hitl_outputs).",
    )
    parser.add_argument(
        "--timestamp-format",
        default="%Y%m%d_%H%M%S",
        help="Timestamp format for run-specific suffix (default: %%Y%%m%%d_%%H%%M%%S).",
    )
    parser.add_argument(
        "--no-timestamp",
        action="store_true",
        help="Create exactly <source-dir>/<name-prefix> without a timestamp suffix.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Resolve and print output path without creating directories.",
    )
    return parser.parse_args()


def _path_for_common(path_like: str) -> Path:
    p = Path(path_like).expanduser().resolve()
    if not p.exists():
        raise FileNotFoundError(f"Input path does not exist: {p}")
    return p if p.is_dir() else p.parent


def resolve_source_dir(args: argparse.Namespace) -> Path:
    if args.source_dir:
        p = Path(args.source_dir).expanduser().resolve()
        if not p.exists():
            raise FileNotFoundError(f"--source-dir does not exist: {p}")
        if not p.is_dir():
            raise NotADirectoryError(f"--source-dir is not a directory: {p}")
        return p

    if not args.input_file:
        raise ValueError("Provide --source-dir or at least one --input-file.")

    parents = [_path_for_common(p) for p in args.input_file]
    common = Path(os.path.commonpath([str(p) for p in parents])).resolve()
    return common if common.is_dir() else common.parent


def build_output_dir(source_dir: Path, args: argparse.Namespace) -> Path:
    if args.no_timestamp:
        return source_dir / args.name_prefix
    stamp = datetime.now().strftime(args.timestamp_format)
    return source_dir / f"{args.name_prefix}_{stamp}"


def main() -> int:
    args = parse_args()
    source_dir = resolve_source_dir(args)
    output_dir = build_output_dir(source_dir, args)

    if not args.dry_run:
        output_dir.mkdir(parents=True, exist_ok=False)

    print(str(output_dir))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
