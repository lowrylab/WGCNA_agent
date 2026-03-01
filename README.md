# WGCNA HITL Agent (Workflow)

This repository contains a reusable, human-in-the-loop (HITL) Weighted Gene Co-expression Network Analysis (WGCNA) workflow that can be run through Codex as an agent or rerun non-interactively with R scripts.

WGCNA is a challenging application to implement for most users. This goal of this agent is to lower the threshold of difficulty for conducting gene network analyses using WGCNA. 

## What Is Included

- Skill definition (the agent behavior):
  - `skills/wgcna-hitl-agent/`
- Decision logging helper:
  - `skills/wgcna-hitl-agent/scripts/append_decision_log.py`
- Full reproducible pipeline script (Stages 1-6):
  - `scripts/wgcna_rerun_stage1_to_6.R`
- Figure-generation script:
  - `scripts/wgcna_make_interaction_figures.R`

## Recommended Way To Run (Codex Agent)

Yes, this is intended to be run through Codex for interactive HITL gating.

Use Codex when you want:
- Explicit approvals at each gate (A-F)
- Parameter choice support with options and risks
- Structured decision logging for reproducibility

### 1. Install/Expose the Skill in Codex

The skill folder must be available in Codex skills path as:
- `$CODEX_HOME/skills/wgcna-hitl-agent`

If this repo is not already under your Codex skill path, copy/symlink:

```bash
mkdir -p "$CODEX_HOME/skills"
ln -s /path/to/this/repo/skills/wgcna-hitl-agent "$CODEX_HOME/skills/wgcna-hitl-agent"
```

### 2. Prepare Input Files

Provide:
- Expression CSV
- Metadata CSV

Expected metadata columns:
- `sample_number`
- `genotype`
- `development_stage`

Expected expression format (current parser assumptions):
- First row: sample IDs as columns
- First column: row labels
- If present, top embedded metadata rows like:
  - `sample name`
  - `Library_Pool`
  - `Primer`
  - `genotype`
  - `development_stage`
- Remaining rows: gene-level numeric counts

### 3. Invoke the Agent in Codex

Prompt example:

```text
Use $wgcna-hitl-agent to run WGCNA on my dataset with human approval gates at each stage.
Expression file: /abs/path/expression.csv
Metadata file: /abs/path/metadata.csv
Output dir: /abs/path/results
```

### 4. Required Approval Gates

The agent should stop for approval at:
- Gate A: QC/filtering
- Gate B: normalization strategy
- Gate C: network type + soft-threshold power
- Gate D: module detection parameters
- Gate E: trait-association criteria
- Gate F: hub-gene criteria

All approvals should be appended to:
- `wgcna_decision_log.md`

## Non-Interactive Rerun (No Codex)

Use this when approved parameters are already known and you want reproducible reruns.

```bash
cd /path/to/this/repo
Rscript scripts/wgcna_rerun_stage1_to_6.R \
  --expr=/abs/path/expression.csv \
  --meta=/abs/path/metadata.csv \
  --out=/abs/path/results \
  --threads=2
```

Then generate figures:

```bash
Rscript scripts/wgcna_make_interaction_figures.R
```

## Outputs To Expect

During/after runs:
- Stage-wise outputs under `results/` (or your `--out` path)
- Final hub-gene exports for selected Gate F option
- Decision log: `wgcna_decision_log.md`
- Interaction and module-trait figures under `results/wgcna_figures/`

## Environment Requirements

R packages:
- `WGCNA`
- `DESeq2`
- `ggplot2`
- `dplyr`
- `tidyr`
- `pheatmap`

Python (for decision logger):
- Python 3.x

## Key References

1. Zhang B, Horvath S. (2005). *A General Framework for Weighted Gene Co-Expression Network Analysis*. **Statistical Applications in Genetics and Molecular Biology**, 4(1):Article17. DOI: `10.2202/1544-6115.1128`  
   Link: [PubMed](https://pubmed.ncbi.nlm.nih.gov/16646834/)

2. Langfelder P, Horvath S. (2008). *WGCNA: an R package for weighted correlation network analysis*. **BMC Bioinformatics**, 9:559. DOI: `10.1186/1471-2105-9-559`  
   Link: [BMC](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/1471-2105-9-559)

3. Langfelder P, Zhang B, Horvath S. (2008). *Defining clusters from a hierarchical cluster tree: the Dynamic Tree Cut package for R*. **Bioinformatics**, 24(5):719-720. DOI: `10.1093/bioinformatics/btm563`  
   Link: [PubMed](https://pubmed.ncbi.nlm.nih.gov/18024473/)

4. Langfelder P, Horvath S. (2007). *Eigengene networks for studying the relationships between co-expression modules*. **BMC Systems Biology**, 1:54. DOI: `10.1186/1752-0509-1-54`  
   Link: [BMC](https://bmcsystbiol.biomedcentral.com/articles/10.1186/1752-0509-1-54)

5. Langfelder P, Luo R, Oldham MC, Horvath S. (2011). *Is my network module preserved and reproducible?* **PLoS Computational Biology**, 7(1):e1001057. DOI: `10.1371/journal.pcbi.1001057`  
   Link: [PubMed](https://pubmed.ncbi.nlm.nih.gov/21283776/)

6. Langfelder P, Horvath S. (2012). *Fast R Functions for Robust Correlations and Hierarchical Clustering*. **Journal of Statistical Software**, 46(11):1-17. DOI: `10.18637/jss.v046.i11`  
   Link: [PubMed](https://pubmed.ncbi.nlm.nih.gov/23050260/)

### Software / Documentation References

1. WGCNA package manual (CRAN/r-universe; current reference documentation)  
   Link: [WGCNA Manual](https://cran.r-universe.dev/WGCNA/doc/manual.html)

2. Official WGCNA tutorial mirror (community-hosted copy of original tutorial docs)  
   Link: [WGCNA Official Documentation Mirror](https://edo98811.github.io/WGCNA_official_documentation/)

## Repository Usage

1. Clone the repo.
2. Install required R packages.
3. Link/copy the skill into `$CODEX_HOME/skills`.
4. Run through Codex for HITL analyses.
5. Use the rerun script for reproducible reruns.

## Suggested GitHub Practice

Commit:
- `skills/wgcna-hitl-agent/`
- `scripts/*.R`
- `README.md`
- `.gitignore`

Avoid committing:
- Large raw datasets (`data/`)
- Per-run intermediate outputs (`results/`)
- Local virtual environments (`.venv/`)
