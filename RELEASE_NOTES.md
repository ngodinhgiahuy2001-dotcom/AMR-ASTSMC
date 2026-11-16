# Release Notes

## Repository organization

- Standardized MATLAB naming around main, config, controller, model, simulation, plotting, exporting and checks.
- Preserved the one-folder MATLAB execution assumption.
- Restored missing sensitivity-related modules from a verified earlier matching archive during source preparation.
- Preserved the original scientific algorithms and fixed comparison settings during naming cleanup.
- Adopted consistent, title-free publication plots and common ITAE sensitivity scaling.

## Documentation and collaboration setup

- Rebuilt the bilingual README navigation with experiment-specific commands.
- Added explicit reproducibility, validation, figure-export and data availability policies.
- Added structured GitHub Issue Forms for MATLAB bugs and numerical discrepancies.
- Added contribution and pull request templates focused on scientific traceability.
- Documented anonymous-review constraints without claiming that a private repository is anonymous.
- Deferred `CITATION.cff` and licensing metadata until actual authorship, bibliographic metadata and rights are authorized.

## Verification boundary

A recorded MATLAB R2024a self-test passed **6/6 regression comparisons**. Full 30-seed and sensitivity experiments have not been rerun for these documentation changes. This commit does not modify the 58 MATLAB source files.
