# Validation Status and Boundaries

## Repository preparation checks

- MATLAB source files: **58**, maintained in one folder.
- Static checks during source normalization reported **0 unresolved project-prefixed calls** and **0 MATLAB function/file-name mismatches**.
- Common-scale ASTSMC sensitivity implementation targets **3 × 17 × 17** deterministic sweeps, with common displayed ITAE limits of **1.40–2.70 m·s²**.
- Plot exports are designed to omit embedded figure titles.

## MATLAB regression record

A provided MATLAB **R2024a** self-test archive recorded **6 of 6 passing** numerical regression comparisons under full mode. Reported residual differences were at numerical floating-point precision.

This is evidence for the checked regression cases only. The original self-test archive is **not** shipped in the source repository, and neither the entire 30-seed batch nor all 867 sensitivity runs were executed during this GitHub documentation update.

## Not certified by this file

- End-to-end execution on every MATLAB release and platform.
- Hardware experiments, physical torque limits, gain-freezing or anti-windup performance.
- Closed-loop stochastic stability under sampled Gaussian noise.
- Inference of lower hardware energy usage from generalized-input RMS.
- Universal performance superiority over optimally tuned fixed-gain controllers.

For the exact experiment commands, see [REPRODUCIBILITY.md](REPRODUCIBILITY.md).
