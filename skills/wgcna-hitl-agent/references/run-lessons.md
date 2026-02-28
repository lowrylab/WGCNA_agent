# Run Lessons (Reusable)

## Purpose
Capture practical defaults and caveats from a completed WGCNA HITL run so future analyses are faster and less error-prone.

## Input Parsing Lessons
- Expression files may include top metadata rows before gene rows.
- When present, treat rows such as `sample name`, `Library_Pool`, `Primer`, `genotype`, and `development_stage` as embedded metadata and strip them before matrix conversion.
- Verify that expression sample columns align exactly to `metadata.sample_number`.

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
- Module detection first pass: start with less fragmented settings before moving to highly granular settings.
- Hub selection: present strict and balanced threshold options and show resulting candidate counts before final approval.

## Required Final Artifacts
- `wgcna_decision_log.md` with all gate approvals.
- Module-trait association table with FDR.
- Hub candidate exports reflecting the final approved Gate F rule.
- Reproducible rerun script and figure-generation script when available.
