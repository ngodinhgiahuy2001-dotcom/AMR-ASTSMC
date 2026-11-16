# Data Availability

This repository distributes **MATLAB source code** and documentation, not a complete frozen numerical dataset.

Simulation results are created locally by the relevant entry points and may include CSV, MAT, FIG, PNG and PDF artifacts. Those generated outputs are excluded from version control by default to keep the source repository readable and avoid mixing results from unrelated runs.

For a reproducible manuscript release, archive the complete raw/processed results separately, with:

- The exact source commit SHA and MATLAB release.
- Unmodified configuration files and random seed definitions.
- A manifest mapping conditions, controllers and runs to output files.
- Checksums and a description of how metrics and figures were computed.
- An explicit distinction between deterministic RK4 and sampled Gaussian/LPF results.

**Dataset DOI:** Not assigned. No external result-download link is claimed here. Reproduction requires running the supplied code or obtaining a separately released, verified results archive.
