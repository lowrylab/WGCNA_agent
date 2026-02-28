---
name: wgcna-hitl-agent
description: Build and run a human-in-the-loop gene co-expression analysis workflow using WGCNA. Use when a user needs to plan, execute, review, or troubleshoot WGCNA steps for transcriptomics data, including QC, soft-threshold selection, module detection, trait association, hub gene identification, decision logging, and reproducible reruns.
---

# WGCNA HITL Agent

## Workflow

1. Confirm analysis context.
- Capture species, expression units, sample count, trait table availability, and whether data are bulk RNA-seq, microarray, or single-cell pseudobulk.
- If context is incomplete, state assumptions before writing code.

2. Build a stepwise plan.
- Follow the stage map in `references/workflow-map.md`.
- Execute one stage at a time.
- Stop at every checkpoint defined in `references/hitl-checkpoints.md`.

3. Produce checkpoint output before execution.
- Use the output contract in `assets/templates/checkpoint-output-template.md`.
- Always include `Options` with at least two parameter choices when a decision is tunable.

4. Wait for explicit approval.
- Do not run next-stage actions unless the human says to proceed.
- If approval is conditional, restate the approved condition before continuing.

5. Record decisions.
- Write or update `wgcna_decision_log.md` in the working directory.
- Include chosen parameters, rejected alternatives, and rationale.
- Prefer `scripts/append_decision_log.py` to append structured entries.

6. Ensure reproducibility.
- Prefer scriptable R steps over interactive-only actions.
- Pin key package versions when feasible.
- Emit exact code snippets needed to rerun each completed stage.

## Execution Rules

- Use `WGCNA::pickSoftThreshold` for power exploration and show tradeoffs between scale-free fit and connectivity.
- Use signed or signed-hybrid network defaults unless the user explicitly requests unsigned.
- Validate trait/sample alignment before module-trait modeling.
- Distinguish exploratory signals from statistically supported findings.
- Flag small sample-size limitations and unstable module results.

## Run-Calibrated Defaults

- Input shape guardrail: if expression CSV has embedded metadata rows at top (for example `sample name`, `Library_Pool`, `Primer`, `genotype`, `development_stage`), strip these rows before count-matrix construction.
- Alignment guardrail: enforce `metadata.sample_number` match to expression sample columns; fail fast if any sample is unmatched.
- Stage 2 default for raw counts: prefer `DESeq2::vst` for first-pass WGCNA normalization unless user requests an alternative.
- Stage 3 baseline options: compare signed and signed-hybrid; if both are acceptable, prefer lower-power choice with adequate fit and connectivity.
- Stage 5 interpretation guardrail: clarify that baseline factor levels (for example `2leaf`) are reference levels and therefore not emitted as explicit dummy columns.
- Stage 5 reporting default: for binary genotype factors, prefer one contrast column (for example `genotypeInland`) to avoid duplicate anti-correlated interpretations.
- Stage 6 output policy: always produce both strict and balanced candidate counts before Gate F approval.

## Deliverable Format

For each stage, output these sections in order:
- `What I observed`
- `Options`
- `Recommended next action`
- `Risk`
- `Ask for approval`

Use `assets/templates/stage-deliverable-template.md` if a concrete scaffold is needed.

## References

- Read `references/workflow-map.md` for stage-by-stage structure.
- Read `references/hitl-checkpoints.md` for approval gates and minimum evidence before advancing.
- Read `references/run-lessons.md` for reusable defaults and interpretation caveats discovered in real execution.

## Scripts

- Use `scripts/append_decision_log.py` to append checkpoint decisions in a consistent format.
- Run `python scripts/append_decision_log.py --help` for full argument details.
