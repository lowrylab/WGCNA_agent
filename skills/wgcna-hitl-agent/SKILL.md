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
- Alignment guardrail: enforce exact metadata-to-expression sample ID alignment using the user-confirmed sample ID column (for example `sample_name`); report duplicates and unmatched IDs before Stage 1.
- Duplicate-column guardrail: if expression sample columns are duplicated, default to keeping the first occurrence and report all duplicate IDs at Gate A.
- Gene-ID guardrail: support prefix matching for user-provided gene IDs that omit version suffixes (for example `Pavir.*` matched to `Pavir.*.v6.1`) and report whether matches are exact or prefix-based.
- Stage 2 default for raw counts: prefer `DESeq2::vst` for first-pass WGCNA normalization unless user requests an alternative.
- Stage 3 baseline options: compare signed and signed-hybrid; if both are acceptable, prefer lower-power choice with adequate fit and connectivity.
- Stage 3 runtime fallback: if full-gene `pickSoftThreshold` is prohibitively slow, calibrate power on a top-variable-gene subset (for example 8,000 genes) and disclose this in Gate C.
- Stage 5 interpretation guardrail: clarify that baseline factor levels (for example `2leaf`) are reference levels and therefore not emitted as explicit dummy columns.
- Stage 5 reporting default: for binary genotype factors, prefer one contrast column (for example `genotypeInland`) to avoid duplicate anti-correlated interpretations.
- Plotting guardrail: if strata are sparse and line plots warn about single-observation groups, use points plus error bars (or point-only summaries) to avoid misleading line continuity.
- Stage 6 output policy: always produce both strict and balanced candidate counts before Gate F approval.
- Stage 6 curation default: when strict or balanced hub lists are too large, offer capped exports (for example top `N` per module-trait pair ranked by `|kME|*|GS|`).
- Module preservation guardrail: before `modulePreservation`, run per-set QC (`goodSamplesGenes`) and remove zero-variance genes within each set; use the intersection of valid genes across sets.
- Module preservation fallback: if full preservation is too slow, run an explicit approximate mode (top variable genes + lower permutations), label outputs as approximate, and write run notes with genes used and permutation count.
- Module preservation plotting default: for manuscript-facing preservation figures, exclude control modules (`gold`, `grey`) unless explicitly requested.
- Module preservation export guardrail: do not assume optional columns (for example `medianRank.pres`) are present; export available columns defensively.
- Effects plotting default: support `Extractionpoint x Genotype` module and gene plots as first-class outputs (combined panel, per-feature plots, and interaction-stats table).
- Largest-module plotting default: provide a reusable option to plot effects for the top `N` largest non-grey modules by gene count.
- Session resilience default: maintain a local chat log and stage summary file in the project directory so work can resume after UI/thread loss.

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
- Use `scripts/export_resume_snapshot.py` near run end to generate `wgcna_resume_snapshot.md` for reliable session restart.
- Run `python scripts/export_resume_snapshot.py --help` for full argument details.
