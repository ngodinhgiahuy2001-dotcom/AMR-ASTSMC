# ASTSMC-AMR
### Adaptive Super-Twisting Sliding Mode Control for a Six-Wheel Autonomous Mobile Robot

**MATLAB research implementation · Trajectory tracking · Robust and adaptive control**

This repository provides a reproducible MATLAB simulation framework for comparing conventional Sliding Mode Control (**SMC**), fixed-gain Super-Twisting Sliding Mode Control (**STSMC**), and online gain-adaptive Super-Twisting Sliding Mode Control (**ASTSMC**) on a six-wheel autonomous mobile robot with two independently driven wheels.

The study investigates nominal motion, prescribed external disturbances, variable payload, and a separate sampled-feedback evaluation with Gaussian process and velocity-measurement noise. The repository distributes **source code, configuration and validation guidance**; large simulation outputs are not included.

> **Research scope:** Computational simulation only. No hardware performance, actuator feasibility, stochastic stability or energy reduction is claimed solely from these scripts.

## Research workflow

| Study | Entry point | Scope |
| --- | --- | --- |
| Deterministic baseline | `main.m` | 3 operating conditions × SMC/STSMC/ASTSMC |
| Single controller | `main_single_controller.m` | Selected case and controller |
| Sampled Gaussian/LPF | `main_gaussian.m` | One seeded evaluation |
| Paired Gaussian statistics | `main_gaussian_statistics.m` | 30 seeds by default |
| Sequential ablation | `main_ablation.m` | N0–N4 experiments |
| Gain-rate sensitivity | `main_sensitivity.m` | 3 conditions × 17 × 17 parameter combinations |
| Re-export sensitivity figures | `main_replot_sensitivity.m` | Replot saved sensitivity MAT results |
| Regression self-test | `main_selftest.m` | Dependency and numerical reference checks |

## Quick start

**Requirements:** MATLAB supporting standard numerical integration, graphics and tables. MATLAB R2024a was used for a recorded six-comparison regression self-test; the complete experiment suite has not been rerun as part of this repository presentation update.

1. Clone or download this repository.
2. Set the repository root (containing all `.m` files) as your MATLAB **Current Folder**.
3. Run the checks and then the desired experiment:

```matlab
main_selftest
main
% Optional experiments
main_gaussian_statistics
main_ablation
main_sensitivity
```

Keep the MATLAB source files together. The source is deliberately structured as a **flat MATLAB directory** because internal functions and entry points assume this configuration.

## Experimental design

**Deterministic study:** Three operating conditions share the same 75-second reference mission and fixed unloaded nominal model: (1) nominal, (2) sinusoidal-plus-bias external disturbances, and (3) those disturbances combined with scheduled variable payload reaching 800 kg. The deterministic solver evaluates feedback within RK4 substages.

**Sampled-noise study:** Controllers are evaluated separately with sampled feedback, Gaussian acceleration/process noise, noisy velocity measurements, a common first-order LPF, and zero-order-held generalized inputs. This implementation is **not numerically interchangeable** with the deterministic RK4 feedback scheme.

**Sensitivity:** ASTSMC gain-increase and gain-decrease rates are swept on a 17 × 17 grid per deterministic condition. Publication sensitivity surfaces use common ITAE limits of **1.40–2.70 m·s²**, common color scaling and **no embedded plot titles**; panel labels and captions belong in the manuscript.

## Source layout

The `main_*` scripts select experiments; `config_*` defines configuration; `controller_*` implements control laws; `model_*` defines the plant/reference/disturbances; `simulate_*` and `run_*` execute experiments; `plot_*` and `export_*` create graphics; `check_*` verifies assumptions and regressions.

- [Source map](CODE_GUIDE.md)
- [Reproducibility protocol](REPRODUCIBILITY.md)
- [Validation scope](VALIDATION.md)
- [Figure conventions](docs/FIGURE_EXPORT.md)
- [Contribution guidelines](CONTRIBUTING.md)
- [Citation guidance](CITATION_GUIDE.md)
- [Data availability](DATA_AVAILABILITY.md)

## Versioning and scientific integrity

Run settings, MATLAB release, random seeds and source commit should be recorded alongside reported numerical results. Generated MAT, FIG and batch-output directories are excluded by `.gitignore`. Do **not** interpret an attractive figure or a passing limited self-test as validation of the complete mathematical or physical model.

**License:** No software license is granted at present. Reuse permissions should be resolved with the relevant rights holders before public release. See [citation guidance](CITATION_GUIDE.md).

**Peer review:** If anonymous review is required, use an approved anonymized artifact rather than linking to an identifying GitHub account. Follow [the anonymity checklist](docs/REVIEW_ANONYMIZATION.md).
