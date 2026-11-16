# Contributing to ASTSMC-AMR

Thank you for helping improve scientific reproducibility.

## Before proposing a change

1. Open an issue using the relevant [structured form](.github/ISSUE_TEMPLATE) and document the case, MATLAB release, and observed behavior.
2. For numerical changes, describe the mathematical motivation and expected effects on SMC, STSMC and ASTSMC comparisons.
3. Keep edits focused. A documentation or plotting-style change must not silently alter control gains, solver settings, disturbances, seeds or performance metrics.

## MATLAB source conventions

- Keep `.m` functions in the **flat repository root** unless a coordinated path migration is proposed.
- Keep primary MATLAB function names identical to filenames.
- Prefix helpers according to purpose: `config_`, `controller_`, `model_`, `simulate_`, `run_`, `plot_`, `export_`, `check_`.
- Prefer explicit units in parameter names, figure axes and documentation.
- Reuse shared random innovations for paired controller comparisons; record the seed generation scheme.
- Leave publication panel labels/captions in the manuscript, not embedded in plotted images.
- Do not commit local paths, names, email addresses, access tokens, raw personal details or bulky generated `Results*` output.

## Pull request requirements

Use the pull request template. Include:

- Description, affected experiment(s) and files.
- Whether mathematics, numerical parameters, random seeds or solver behavior changed.
- Evidence from `main_selftest` and targeted experiments, or a clear explanation of what was not run.
- Reproducibility impact and updated documentation where applicable.

There is currently no continuous integration job proving MATLAB runtime correctness. A passing code review or static check is not equivalent to a numerical regression test.

## License and publication

No open-source license has yet been approved for this repository. External contributions and redistribution may require agreement from the rights holders. Do not add identifying details before the applicable anonymous-review stage has ended.
