# Release Notes — Repository Preparation

- Standardized MATLAB file and primary-function names by functional responsibility.
- Preserved one-folder MATLAB execution and synchronized direct function calls, string-based checks and documentation references.
- Restored four sensitivity/replot source files absent from the latest uploaded archive using a verified earlier archive with identical shared modules.
- Renamed the zoom export utility to `export_zoom_figures.m` and removed collaborator-specific wording in source comments.
- Applied the previously requested title-free convention to Gaussian/ablation/export plots; did not alter plotted data, axes, control or simulation algorithms.
- Stored exported MATLAB FIG in a visible state to avoid the common invisible-FIG reopening issue.
- Included GitHub `.gitignore` and clear baseline, Gaussian, ablation and sensitivity entrypoints.

**Validation status:** all MATLAB function declarations, renamed references and source-file dependencies have been checked statically. Simulations have not been executed in MATLAB for this release.
