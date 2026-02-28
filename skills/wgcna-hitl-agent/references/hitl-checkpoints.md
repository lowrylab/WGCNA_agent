# HITL Checkpoints

## Required Gate Format
Before each gate, provide:
1. Evidence summary (plots/tables/metrics produced).
2. Decision options (at least two, with parameter values).
3. Recommendation with short rationale.
4. Explicit approval request.

## Gate A: QC/Filtering Approval
- Human decides which samples and genes to remove.
- Minimum evidence: outlier clustering summary, missingness summary, filter impact counts.

## Gate B: Normalization/Covariate Strategy Approval
- Human decides final normalization and batch handling strategy.
- Minimum evidence: before/after summary and expected biological signal retention statement.

## Gate C: Power and Network Type Approval
- Human decides `power` and network type.
- Minimum evidence: scale-free fit trend, connectivity trend, and candidate settings.

## Gate D: Module Detection Parameter Approval
- Human decides cut and merge parameters.
- Minimum evidence: module count, module size distribution, and merge impact summary.

## Gate E: Trait Association Criteria Approval
- Human decides thresholds and correction strategy.
- Minimum evidence: association table preview and interpretation constraints.
- Clarify baseline/reference-level behavior for factor-coded traits to avoid mistaking omitted baseline columns for missing data.

## Gate F: Hub Gene Criteria Approval
- Human decides kME/gene significance thresholds and tie-break policy.
- Minimum evidence: candidate count preview under each option.

## Decision Log Requirement
After each approved gate, append an entry to `wgcna_decision_log.md`:
- Date/time
- Stage
- Options presented
- Approved option
- Rationale
- Deferred risks
