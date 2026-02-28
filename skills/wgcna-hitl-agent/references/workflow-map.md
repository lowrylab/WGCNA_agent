# WGCNA Workflow Map

## Scope
Use this flow for bulk transcriptomics or pseudobulk expression matrices where rows are genes and columns are samples.

## Stage 0: Intake and Preconditions
- Required inputs: expression matrix, metadata, trait table (or clear statement that trait analysis is deferred).
- Validate: unique sample IDs, no duplicated genes after preprocessing, expected data scale.
- If expression file includes embedded metadata rows before genes, identify and remove those rows before numeric conversion.
- Output: confirmed data contract and assumptions.

## Stage 1: QC and Filtering
- Detect sample outliers by clustering and missingness.
- Filter low-information genes using study-appropriate rules.
- Confirm final sample and gene counts.
- Checkpoint: human approves exclusions and filter thresholds.

## Stage 2: Normalization and Covariate Handling
- Confirm whether normalization is already complete.
- Apply/confirm batch correction strategy if needed.
- Re-check sample relationships after correction.
- Checkpoint: human approves preprocessing method choices.

## Stage 3: Network Type and Soft-Threshold Power
- Choose network type (signed/signed-hybrid/unsigned).
- Run `pickSoftThreshold` across candidate powers.
- Compare scale-free fit and mean connectivity curves.
- Checkpoint: human approves power and network type.

## Stage 4: Module Construction
- Build adjacency and TOM.
- Cluster genes and detect modules with dynamic tree cut.
- Merge similar modules using eigengene correlation threshold.
- Checkpoint: human approves module detection and merge parameters.

## Stage 5: Module-Trait Relationships
- Align module eigengenes and trait table.
- Compute correlations and p-values with multiple-testing handling as appropriate.
- Highlight robust vs borderline associations.
- Checkpoint: human approves significance criteria and interpretation framing.

## Stage 6: Hub Gene and Candidate Prioritization
- Compute module membership (kME) and gene significance metrics.
- Define hub criteria before ranking.
- Export candidates and module summaries.
- Checkpoint: human approves hub criteria and output artifacts.

## Stage 7: Reporting and Reproducibility
- Summarize final parameters and all human decisions.
- Provide rerun-ready scripts and environment notes.
- Mark unresolved uncertainties and recommended follow-ups.
