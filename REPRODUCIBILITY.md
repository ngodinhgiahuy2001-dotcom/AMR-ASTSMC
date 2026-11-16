# Numerical Reproducibility Protocol

## 1. Environment

- MATLAB: standard support for tables, FIG/PNG/PDF export and numerical calculations; a recorded regression self-test was executed with **MATLAB R2024a**.
- MATLAB Current Folder: repository root; retain all MATLAB `.m` files at this root.
- Run `main_selftest` before interpreting numerical results.
- Document OS, MATLAB release, commit SHA, runtime mode, parameter configuration and any manual changes.

## 2. Configuration files

| File | Responsibility |
| --- | --- |
| `config_experiment.m` | Run mode, task, seed count, case selection and output base |
| `config_parameters.m` | Nominal robot, control and trajectory parameters |
| `config_noise.m` | Gaussian/LPF numerical configuration |
| `config_plot_style.m` | Figure styles |
| `setup_project.m` | MATLAB source path initialization |

## 3. Experiments

### A. Deterministic baseline

Run `main`. The baseline compares three controllers across nominal operation, external disturbances, and external disturbances with variable payload. Full mission: **75 s**. The archived deterministic implementation recomputes controller feedback in the RK4 stages. Do not describe it as sampled zero-order-held feedback.

### B. Sampled Gaussian / LPF

Run `main_gaussian` for an individual seeded comparison, or `main_gaussian_statistics` for 30 paired seeds by default. The Gaussian implementation samples the control law, holds generalized inputs over integration intervals, and applies a common velocity LPF. The stored research-design seed IDs are **20261113–20261142**; verify the actual configured seed list before reporting new results.

**Warning:** Numerical integration and feedback differ from the deterministic solver. An absolute metric difference between `main` and `main_gaussian` does not isolate the impact of noise.

### C. Sequential ablation

Run `main_ablation`. The N0–N4 sequence introduces components incrementally: external-only sampled baseline, Gaussian process noise, velocity-sensor noise, LPF, then variable payload. A single seed is an illustrative comparison, not a multi-seed confidence interval.

### D. Gain-rate sensitivity

Run `main_sensitivity`: three deterministic cases, each with a 17 × 17 grid (867 total full-mission evaluations). Only the ASTSMC adaptation-rate pair is swept. If saved complete `ITAE_Sensitivity.mat` files exist, run `main_replot_sensitivity` instead of repeating the sweep just to modify plotting style.

For publication, apply a common ITAE axis and color scale of **1.40–2.70 m·s²**. Report any values outside these display limits rather than silently clipping them.

## 4. Reporting checklist

- Record code commit SHA and MATLAB release.
- Report the controller, case, mission duration and metric units.
- Separate deterministic and sampled-feedback results in tables and discussion.
- For paired seed-wise percentage improvements, compute the percentage *within each matched seed pair* before averaging.
- Distinguish full-mission RMSE/ITAE from local 27–42 s metrics.
- Keep figure titles out of exported axes; add panel labels and captions in the manuscript.
- Save raw simulation artifacts outside the Git repository, with checksums where needed.

## 5. Current validation boundary

A recorded MATLAB R2024a self-test passed 6/6 regression comparisons (deterministic full-sweep, multi-seed, plotting and hardware experiments were **not** all rerun during repository setup). This is a limited regression result, not proof of experimental reproducibility on every MATLAB configuration.
