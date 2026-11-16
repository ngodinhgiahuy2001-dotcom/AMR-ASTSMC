# Source Organization

All MATLAB files are flat in one folder. Prefixes identify each role; MATLAB function names match their filenames.

| Prefix | Meaning | Examples |
| --- | --- | --- |
| `main_` / `main.m` | Runnable entrypoint | `main_sensitivity.m`, `main_gaussian_statistics.m` |
| `config_` | Parameters, numerical settings and plot style | `config_experiment.m`, `config_noise.m` |
| `controller_` | Kinematic command and robust control laws | `controller_ASTSMC.m`, `controller_STSMC.m` |
| `model_` | Dynamics, trajectory, external disturbances and payload model | `model_robot_dynamics.m` |
| `simulate_` | Single-trajectory integrators or metrics | `simulate_sensitivity_itae.m` |
| `run_` | Simulation batch and output orchestration | `run_deterministic.m`, `run_gaussian_statistics.m` |
| `plot_` | Figures from in-memory simulation data | `plot_gaussian_statistics.m` |
| `export_` | FIG/PNG/PDF export and inset generation | `export_zoom_figures.m` |
| `replot_` | Publication plots from archived .mat data | `replot_zoom_figures.m` |
| `check_` | Validations and regression checks | `check_regression_metrics.m` |

## Result-oriented workflow

1. Configure parameters in `config_experiment.m` without changing controller mathematics.
2. Run a single experiment via the appropriate `main_*.m` script, or the baseline `main.m`.
3. Keep numerical outputs outside Git; record seed, MATLAB release, and parameters for reproducibility.
4. Re-export Figures from saved MAT where available; re-running model dynamics is unnecessary for styling-only changes.
5. Assemble panel labels and journal figure captions in the manuscript, not in simulation plots.

## Source integrity

The code is derived from the user-supplied MATLAB ZIP. Four missing files required for sensitivity execution or common-scale replotting were restored from an earlier code archive whose 54 shared `.m` files matched the supplied archive by SHA-256. No equations, controller gains, disturbance parameters, seeds, or simulation grids were deliberately modified during naming normalization. File-name references and function identifiers were updated together.

**Not verified:** execution on an installed MATLAB release, full-run numerical reproducibility after renaming, or the availability of toolboxes on the destination computer.
