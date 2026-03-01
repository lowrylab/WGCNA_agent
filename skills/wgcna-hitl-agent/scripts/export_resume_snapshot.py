#!/usr/bin/env python3
"""Generate a resumable markdown snapshot for a WGCNA HITL run.

The snapshot captures:
- Workspace path and generation timestamp.
- Recent approved decisions parsed from wgcna_decision_log.md.
- Key output artifacts that currently exist.
- A ready-to-paste resume prompt for the next Codex session.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


DEFAULT_ARTIFACTS = [
    "wgcna_decision_log.md",
    "stage7_run_report.md",
    "stage2_normalization_metrics.csv",
    "stage3_pickSoftThreshold_fitIndices.csv",
    "stage4_module_sizes_coarse.csv",
    "stage5_module_trait_long.csv",
    "stage6_hub_candidates_strict.csv",
    "stage6_hub_candidates_strict_capped_top50.csv",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export a markdown snapshot for reliable session resumption.",
    )
    parser.add_argument(
        "--workspace-dir",
        default=".",
        help="Run workspace directory containing outputs (default: current directory).",
    )
    parser.add_argument(
        "--decision-log",
        default="wgcna_decision_log.md",
        help="Decision log path, relative to workspace unless absolute.",
    )
    parser.add_argument(
        "--output-path",
        default="wgcna_resume_snapshot.md",
        help="Output markdown path, relative to workspace unless absolute.",
    )
    parser.add_argument(
        "--artifact",
        action="append",
        default=[],
        help="Extra artifact path to include (repeatable).",
    )
    return parser.parse_args()


def resolve_path(workspace: Path, path_like: str) -> Path:
    path = Path(path_like)
    return path if path.is_absolute() else workspace / path


def parse_decisions(log_path: Path) -> list[tuple[str, str, str]]:
    if not log_path.exists():
        return []

    lines = log_path.read_text(encoding="utf-8").splitlines()
    decisions: list[tuple[str, str, str]] = []

    current_heading = ""
    current_stage = ""
    approved = ""
    capture_approved = False

    for line in lines:
        if line.startswith("## "):
            if current_heading:
                decisions.append((current_heading, current_stage, approved or "[not recorded]"))
            current_heading = line[3:].strip()
            current_stage = current_heading.split(" - ", 1)[1] if " - " in current_heading else current_heading
            approved = ""
            capture_approved = False
            continue

        if line.strip() == "### Approved option":
            capture_approved = True
            continue

        if capture_approved and line.strip().startswith("- "):
            approved = line.strip()[2:].strip()
            capture_approved = False

    if current_heading:
        decisions.append((current_heading, current_stage, approved or "[not recorded]"))

    return decisions


def render_snapshot(
    *,
    workspace: Path,
    output_path: Path,
    decision_log_path: Path,
    decisions: list[tuple[str, str, str]],
    artifacts: list[Path],
) -> str:
    now = datetime.now().replace(microsecond=0).isoformat()
    lines: list[str] = [
        "# WGCNA Resume Snapshot",
        "",
        f"Generated: {now}",
        f"Workspace: `{workspace}`",
        f"Decision log: `{decision_log_path}`",
        "",
        "## Latest Decisions",
    ]

    if decisions:
        for _, stage, approved in decisions[-12:]:
            lines.append(f"- `{stage}` -> {approved}")
    else:
        lines.append("- No parsed decisions found.")

    lines.extend(["", "## Available Artifacts"])
    if artifacts:
        for p in artifacts:
            rel = p.relative_to(workspace) if p.is_relative_to(workspace) else p
            lines.append(f"- `{rel}`")
    else:
        lines.append("- No known artifacts found.")

    lines.extend(
        [
            "",
            "## Resume Prompt",
            "Use this prompt in a new Codex session:",
            "",
            "```text",
            f"Use `{output_path}` and `{decision_log_path}` as context and continue from the latest completed stage.",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    workspace = Path(args.workspace_dir).resolve()
    workspace.mkdir(parents=True, exist_ok=True)

    decision_log_path = resolve_path(workspace, args.decision_log).resolve()
    output_path = resolve_path(workspace, args.output_path).resolve()

    candidate_artifacts = [resolve_path(workspace, p).resolve() for p in DEFAULT_ARTIFACTS + args.artifact]
    existing_artifacts = [p for p in candidate_artifacts if p.exists()]

    decisions = parse_decisions(decision_log_path)
    snapshot = render_snapshot(
        workspace=workspace,
        output_path=output_path,
        decision_log_path=decision_log_path,
        decisions=decisions,
        artifacts=existing_artifacts,
    )
    output_path.write_text(snapshot, encoding="utf-8")
    print(f"Wrote resume snapshot to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
