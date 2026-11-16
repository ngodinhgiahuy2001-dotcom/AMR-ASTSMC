# ASTSMC for Autonomous Mobile Robot Trajectory Tracking

MATLAB simulation framework comparing **SMC**, **fixed-gain STSMC**, and **adaptive-gain STSMC (ASTSMC)** for a six-wheel autonomous mobile robot, with deterministic disturbances, variable payload, and sampled Gaussian-process / velocity-measurement noise with low-pass feedback filtering.

This source distribution contains **code only**. Simulation outputs and external data archives are not embedded; execution generates result directories locally. No personal identifiers, local machine paths, institutional affiliations, or personal authorship metadata are included.

## Requirements

- MATLAB with support for `table`, `writetable`, `savefig`, `exportgraphics`, and standard visualization functions. Some exporters fall back to `print` if vector export is unsupported.
- Place all `.m` files **in the same folder** and set that folder as the MATLAB Current Folder. Do not move helper functions into subfolders without updating the MATLAB path.
- This release has been **statically checked** for internal calls and file names but has not been executed with MATLAB in this environment.

## Start here

Open the MATLAB Current Folder and run one of these entrypoint scripts:

| File | Purpose |
| --- | --- |
| `main.m` | Full original deterministic comparison: three conditions × three controllers |
| `main_single_controller.m` | Run one controller and condition (selected in `config_experiment.m`) |
| `main_gaussian.m` | Sampled Gaussian/LPF comparison for one seed |
| `main_gaussian_statistics.m` | Multi-seed Gaussian/LPF statistics (30 by default) |
| `main_ablation.m` | Sequential N0–N4 noise / filter / payload ablation |
| `main_sensitivity.m` | ASTSMC gain sensitivity: all 3 conditions × 17 × 17 combinations |
| `main_replot_sensitivity.m` | Re-export the three sensitivity surfaces from saved `.mat` files, without rerunning the simulation |
| `main_replot_publication.m` | Regenerate deterministic figures from existing saved results |
| `main_selftest.m` | Check source dependencies and regression metrics |

Run an individual script using its bare name, e.g. `main_sensitivity`. Configuration options, seed count, single-run controller and output directory are in **`config_experiment.m`**. Robot parameters are in **`config_parameters.m`**; the sampled-noise configuration is in **`config_noise.m`**. See [CODE_GUIDE.md](CODE_GUIDE.md) for module mapping.

## Methods and reproducibility

- The deterministic experiments use continuous feedback evaluated within the RK4 integration substages.
- The Gaussian/LPF experiments use sampled control with held generalized input and a separate plant-integrator implementation. Results from these two numerical schemes must not be pooled to attribute a difference to noise alone.
- The full sensitivity sweep computes each 75-s deterministic trajectory on a 17×17 `(gammaUp, gammaDown)` grid for **each** of three conditions; surface plots use a common ITAE Z/color range of **1.40–2.70 m·s²**, and no embedded chart title.
- Sampled Gaussian comparisons are paired across controllers using reproducible random seeds. A single-seed N0–N4 ablation is descriptive; it does not establish statistical effect sizes by itself.
- Results are computational simulations, not hardware validation or a stochastic closed-loop stability certificate.

## Outputs and version control

Output paths default to folders adjacent to the MATLAB source. The `.gitignore` file excludes generated result directories and bulky binary simulation outputs. Exported research graphs do not include embedded titles; add panel labels and captions in the manuscript. FIG outputs are saved in viewable mode.

For a public repository, publish a tagged code version alongside a frozen configuration and an independent, documented data release, rather than committing mutable results from unrelated simulation runs.

## License

No license is granted by this repository unless one is added explicitly. Add a license only after all rights holders agree to its terms.
