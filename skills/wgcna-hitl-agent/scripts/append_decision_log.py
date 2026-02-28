#!/usr/bin/env python3
"""Append structured WGCNA checkpoint decisions to a markdown log.

Purpose:
- Record one human-approved decision per invocation.
- Keep a consistent format across pipeline gates (A-F).

Inputs:
- --stage: Name of the checkpoint/stage.
- --approved-option: Human-approved option text.
- --rationale: Why the option was selected.
- --option: Repeatable list of options that were presented.
- --deferred-risk: Repeatable list of known deferred risks.
- --timestamp: Optional ISO timestamp override.
- --log-path: Output markdown file path (default: wgcna_decision_log.md).

Output:
- Appends a markdown entry under the decision log file.

Example:
  python append_decision_log.py \
    --stage "Gate C: Power and Network Type" \
    --option "signed-hybrid, power=5" \
    --option "signed, power=11" \
    --approved-option "signed-hybrid, power=5" \
    --rationale "Better fit/connectivity tradeoff." \
    --deferred-risk "May differ from strict signed-network conventions."
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


def _bulletize(values: list[str]) -> str:
    return "\n".join(f"- {v.strip()}" for v in values if v.strip())


def build_entry(
    *,
    timestamp: str,
    stage: str,
    approved_option: str,
    rationale: str,
    options_presented: list[str],
    deferred_risks: list[str],
) -> str:
    options_block = _bulletize(options_presented) or "- [not provided]"
    risks_block = _bulletize(deferred_risks) or "- None noted"
    lines = [
        f"## {timestamp} - {stage}",
        "",
        "### Options presented",
        options_block,
        "",
        "### Approved option",
        f"- {approved_option.strip()}",
        "",
        "### Rationale",
        rationale.strip(),
        "",
        "### Deferred risks",
        risks_block,
        "",
    ]
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Append a structured decision entry to wgcna_decision_log.md.",
        epilog=(
            "Tip: repeat --option and --deferred-risk to capture full checkpoint context."
        ),
    )
    parser.add_argument(
        "--log-path",
        default="wgcna_decision_log.md",
        help="Path to decision log markdown file (default: wgcna_decision_log.md).",
    )
    parser.add_argument("--stage", required=True, help="Pipeline stage name.")
    parser.add_argument(
        "--approved-option",
        required=True,
        help="Option approved by the human reviewer.",
    )
    parser.add_argument(
        "--rationale",
        required=True,
        help="Short reason for why the approved option was selected.",
    )
    parser.add_argument(
        "--option",
        action="append",
        default=[],
        help="An option that was presented. Repeat for multiple options.",
    )
    parser.add_argument(
        "--deferred-risk",
        action="append",
        default=[],
        help="A risk deferred or accepted. Repeat for multiple risks.",
    )
    parser.add_argument(
        "--timestamp",
        default=None,
        help="ISO timestamp override (default: now in local time).",
    )
    return parser.parse_args()


def ensure_header(path: Path) -> None:
    if path.exists():
        return
    header = "# WGCNA Decision Log\n\n"
    path.write_text(header, encoding="utf-8")


def main() -> int:
    args = parse_args()
    log_path = Path(args.log_path)
    ensure_header(log_path)

    timestamp = args.timestamp or datetime.now().replace(microsecond=0).isoformat()
    entry = build_entry(
        timestamp=timestamp,
        stage=args.stage,
        approved_option=args.approved_option,
        rationale=args.rationale,
        options_presented=args.option,
        deferred_risks=args.deferred_risk,
    )

    with log_path.open("a", encoding="utf-8") as f:
        if log_path.stat().st_size > 0:
            f.write("\n")
        f.write(entry)

    print(f"Appended decision entry to {log_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
