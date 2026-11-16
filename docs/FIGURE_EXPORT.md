# Publication Figure Conventions

The Word/LaTeX manuscript owns figure numbers, captions and panel annotations. MATLAB plots should **not** embed titles or panel identifiers such as (a), (b), (c).

## Preferred exports

- Editable MATLAB FIG for local review.
- High-resolution PNG for manuscript placement.
- Vector PDF when supported for print quality.
- Consistent fonts, readable legends, axis units and line widths across experiments.
- Keep the source MAT/CSV separate from presentation-only output.

## Fig. 18: deterministic sensitivity comparison

Three surfaces correspond to:

1. Nominal operation.
2. Sinusoidal-plus-bias external disturbances.
3. External disturbances and variable payload.

Use identical gain-rate domains, camera view, and ITAE Z/color scale across all three panels. The current common ITAE limits are **[1.40, 2.70] m·s²**. Preserve all data points and state clearly when rescaling makes the nominal surface appear nearly flat.

The figure must not contain embedded condition titles; manuscript labels (a), (b), (c) and the caption identify each panel.

## Scientific interpretation

The color scale is comparable **only** when shared. A common axis may visually compress small variations; this does not mean their numerical spread is zero. No plot-formatting change should modify simulated dynamics, computed ITAE or the saved raw data.
