# Run Lessons (Reusable)

## Purpose
Capture practical defaults and caveats from a completed WGCNA HITL run so future analyses are faster and less error-prone.

## Input Parsing Lessons
- Expression files may include top metadata rows before gene rows.
- When present, treat rows such as `sample name`, `Library_Pool`, `Primer`, `genotype`, and `development_stage` as embedded metadata and strip them before matrix conversion.
- Verify that expression sample columns align exactly to a user-confirmed metadata ID column (often `sample_name`, not always `sample_number`).
- Detect and report duplicate expression sample columns before QC.
- Report exact unmatched IDs on both sides (metadata-only and expression-only) before applying strict alignment.
- For user-provided candidate genes, support prefix matching when IDs are versioned (for example query `Pavir.1NG123456` against matrix ID `Pavir.1NG123456.v6.1`).

## QC Lessons
- Sample connectivity Z-score is useful for candidate outlier screening.
- Treat `Z.k < -2.5` as a candidate rule, not an automatic exclusion rule.
- Always check whether excluded outliers cluster in a specific biological subgroup before confirming removal.

## Trait Modeling Lessons
- Factor reference levels are expected to be omitted from model-matrix columns.
- Explain this explicitly during review (for example `development_stage2leaf` can be baseline and not a missing trait).
- For two-level genotype traits, keep one explicit contrast column in interpretation summaries to reduce duplicate anti-correlated hits.

## Gate Defaults for First Pass
- Normalization: `DESeq2::vst` for raw count data unless user requests another method.
- Network selection: compare signed and signed-hybrid; balance scale-free fit and connectivity.
- If `pickSoftThreshold` on the full feature set is too slow, calibrate on top-variable genes (for example 8,000) and disclose subset use at Gate C.
- Module detection first pass: start with less fragmented settings before moving to highly granular settings.
- Hub selection: present strict and balanced threshold options and show resulting candidate counts before final approval.
- When candidate lists are large, provide a third option that caps top genes per module-trait pair.

## Plotting Lessons
- For sparse combinations in interaction plots (especially 3-way stratifications), line geoms may warn because groups have single observations.
- Prefer point + error bar summaries (or remove connecting lines) for those sparse strata to avoid over-interpreting trajectories.

## Session Resilience Lessons
- Do not rely on UI thread persistence for long analyses.
- Maintain a local markdown chat log and append major decisions/results during the run.
- Write a concise run report at completion with approved gate choices and output file paths for restartability.

## Required Final Artifacts
- `wgcna_decision_log.md` with all gate approvals.
- `wgcna_resume_snapshot.md` generated from `scripts/export_resume_snapshot.py` for restartability.
- Module-trait association table with FDR.
- Hub candidate exports reflecting the final approved Gate F rule.
- Reproducible rerun script and figure-generation script when available.
