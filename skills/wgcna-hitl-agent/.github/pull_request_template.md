## Summary
- What changed:
- Why:

## Agent Workflow Checklist
- [ ] Stage 0 output directory behavior is correct (uses source-data directory + run-specific subdirectory).
- [ ] `scripts/init_output_dir.py` behavior is validated for this change (`--help` and one sample invocation).
- [ ] All workflow gates still use explicit approval prompts and preserve HITL structure.
- [ ] Decision logging behavior remains intact (`scripts/append_decision_log.py` path/usage unchanged or updated correctly).
- [ ] Reproducibility requirement is satisfied (`<output_dir>/wgcna_complete_run.R` is produced and documented).

## Quality and Safety Checklist
- [ ] No generated run artifacts are committed (stage files, figures, ad-hoc exports, logs).
- [ ] Any changes to defaults/guardrails are reflected in both `SKILL.md` and `references/workflow-map.md` if applicable.
- [ ] Added/updated scripts include clear CLI help text and at least one usage example in docs.
- [ ] Backward compatibility impact is called out (or marked as none).

## Validation
- Commands run:
```bash
# Paste commands used to validate this PR.
```

- Notes:
