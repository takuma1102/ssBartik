# Package index

## One-call pipeline

Build the dataset, run the whole workflow, and return the interval
comparison, the effective first-stage F, and every diagnostic in a
single call.

- [`ssbartik()`](https://takuma1102.github.io/ssBartik/reference/ssbartik.md)
  : One-call shift-share analysis
- [`ssb_pipeline()`](https://takuma1102.github.io/ssBartik/reference/ssb_pipeline.md)
  : Run the full shift-share analysis pipeline

## Design

Assemble shares, shocks and controls into one object and choose the
identification route (`exogenous = "share"` or `"shift"`); everything
downstream reads from it.

- [`ssb_design()`](https://takuma1102.github.io/ssBartik/reference/ssb_design.md)
  : Define a shift-share (Bartik) IV design

## Estimation and exposure-robust inference

Point estimates with IID / EHW / cluster / two-way standard errors and
the exposure-robust AKM and AKM0 confidence sets (via ‘ShiftShareSE’),
plus first-stage strength and the location/shock-level equivalence
check.

- [`ssb_estimate()`](https://takuma1102.github.io/ssBartik/reference/ssb_estimate.md)
  : Estimate a shift-share IV regression with several confidence
  intervals
- [`ssb_first_stage()`](https://takuma1102.github.io/ssBartik/reference/ssb_first_stage.md)
  : First-stage strength: standard and exposure-robust (effective) F
- [`ssb_equivalence()`](https://takuma1102.github.io/ssBartik/reference/ssb_equivalence.md)
  : Check the location-level / shock-level equivalence

## Exogenous-shares diagnostics (Rotemberg)

Which shocks carry identification, how concentrated exposure is, and
whether the shares look exogenous — following Goldsmith-Pinkham, Sorkin
and Swift (2020).

- [`ssb_rotemberg()`](https://takuma1102.github.io/ssBartik/reference/ssb_rotemberg.md)
  : Rotemberg weights for a Bartik instrument
- [`ssb_weight_summary()`](https://takuma1102.github.io/ssBartik/reference/ssb_weight_summary.md)
  : Rotemberg-weight summary and correlations (GPSS diagnostic table)
- [`ssb_share_balance()`](https://takuma1102.github.io/ssBartik/reference/ssb_share_balance.md)
  : Share balance (exogenous-shares route)

## Exogenous-shifts diagnostics

Shock-level summaries, correlation balance across shocks, the
shock-level IV, and the over-identification test across single-share
instruments.

- [`ssb_shock_summary()`](https://takuma1102.github.io/ssBartik/reference/ssb_shock_summary.md)
  : Shock summary: effective number of shocks and exposure concentration
- [`ssb_shock_balance()`](https://takuma1102.github.io/ssBartik/reference/ssb_shock_balance.md)
  : Shock-level balance test
- [`ssb_shock_iv()`](https://takuma1102.github.io/ssBartik/reference/ssb_shock_iv.md)
  : Shock-level IV estimate
- [`ssb_overid()`](https://takuma1102.github.io/ssBartik/reference/ssb_overid.md)
  : Overidentification / cross-instrument homogeneity test

## Robustness and validity checks

Leave-one-out and drop-top sensitivity, pre-trend and placebo tests,
randomization inference, recentering, and shock aggregation.

- [`ssb_loo()`](https://takuma1102.github.io/ssBartik/reference/ssb_loo.md)
  : Leave-one-sector-out sensitivity
- [`ssb_drop_top()`](https://takuma1102.github.io/ssBartik/reference/ssb_drop_top.md)
  : Re-estimate after dropping the top-weight shocks
- [`ssb_pretrend()`](https://takuma1102.github.io/ssBartik/reference/ssb_pretrend.md)
  : Pre-trend test
- [`ssb_placebo()`](https://takuma1102.github.io/ssBartik/reference/ssb_placebo.md)
  : Placebo-outcome test
- [`ssb_ri()`](https://takuma1102.github.io/ssBartik/reference/ssb_ri.md)
  : Randomization-inference (placebo-shock) test
- [`ssb_recenter()`](https://takuma1102.github.io/ssBartik/reference/ssb_recenter.md)
  : Recenter the shocks (Borusyak & Hull)
- [`ssb_aggregate()`](https://takuma1102.github.io/ssBartik/reference/ssb_aggregate.md)
  : Aggregate a shift-share design to the shock (shifter) level

## Plots

ggplot2 figures for the interval comparison, leave-one-out sensitivity,
dispersion of just-identified estimates, exposure concentration, and the
randomization-inference null.

- [`ssb_plot_ci()`](https://takuma1102.github.io/ssBartik/reference/ssb_plot_ci.md)
  : Plot the confidence-interval comparison
- [`ssb_plot_loo()`](https://takuma1102.github.io/ssBartik/reference/ssb_plot_loo.md)
  : Leave-one-out sensitivity plot
- [`ssb_plot_overid()`](https://takuma1102.github.io/ssBartik/reference/ssb_plot_overid.md)
  : Overidentification dispersion plot
- [`ssb_plot_shocks()`](https://takuma1102.github.io/ssBartik/reference/ssb_plot_shocks.md)
  : Exposure-concentration (Lorenz) plot
- [`ssb_plot_ri()`](https://takuma1102.github.io/ssBartik/reference/ssb_plot_ri.md)
  : Randomization-inference plot
- [`ssb_plot_rotemberg()`](https://takuma1102.github.io/ssBartik/reference/ssb_plot_rotemberg.md)
  : Plot Rotemberg weights (canonical GPSS figure)

## Publication-ready tables

Render any result table as a booktabs-style PNG/PDF image
(`plot(x, file = ...)`), or as LaTeX / Markdown source via the
[`format()`](https://rdrr.io/r/base/format.html) methods below.

- [`plot(`*`<ssb_estimate>`*`)`](https://takuma1102.github.io/ssBartik/reference/ssb_table_image.md)
  [`plot(`*`<ssb_weight_summary>`*`)`](https://takuma1102.github.io/ssBartik/reference/ssb_table_image.md)
  [`plot(`*`<ssb_overid>`*`)`](https://takuma1102.github.io/ssBartik/reference/ssb_table_image.md)
  [`plot(`*`<ssb_loo>`*`)`](https://takuma1102.github.io/ssBartik/reference/ssb_table_image.md)
  [`plot(`*`<ssb_drop_top>`*`)`](https://takuma1102.github.io/ssBartik/reference/ssb_table_image.md)
  : Render a result table as an image (PNG or PDF)
- [`plot(`*`<ssb_rotemberg>`*`)`](https://takuma1102.github.io/ssBartik/reference/plot.ssb_rotemberg.md)
  : Render the Rotemberg-weight table as a compact booktabs figure
- [`format(`*`<ssb_estimate>`*`)`](https://takuma1102.github.io/ssBartik/reference/format.ssb_estimate.md)
  : Render the estimate / standard-error table as LaTeX or Markdown
- [`format(`*`<ssb_rotemberg>`*`)`](https://takuma1102.github.io/ssBartik/reference/format.ssb_rotemberg.md)
  : Render the Rotemberg-weight table as paste-ready LaTeX or Markdown
- [`format(`*`<ssb_weight_summary>`*`)`](https://takuma1102.github.io/ssBartik/reference/format.ssb_weight_summary.md)
  : Render a Rotemberg-weight summary as LaTeX or Markdown
- [`format(`*`<ssb_overid>`*`)`](https://takuma1102.github.io/ssBartik/reference/format.ssb_overid.md)
  : Render an overidentification test as LaTeX or Markdown
- [`format(`*`<ssb_loo>`*`)`](https://takuma1102.github.io/ssBartik/reference/format.ssb_loo.md)
  : Render a leave-one-out table as LaTeX or Markdown
- [`format(`*`<ssb_drop_top>`*`)`](https://takuma1102.github.io/ssBartik/reference/format.ssb_drop_top.md)
  : Render a drop-top-shocks comparison as LaTeX or Markdown
- [`format(`*`<ssb_shocks>`*`)`](https://takuma1102.github.io/ssBartik/reference/format.ssb_shocks.md)
  : Render a shock-exposure summary as LaTeX or Markdown
- [`format(`*`<ssb_shock_balance>`*`)`](https://takuma1102.github.io/ssBartik/reference/format.ssb_shock_balance.md)
  : Render a shock-balance test as LaTeX or Markdown

## Package overview

- [`ssBartik`](https://takuma1102.github.io/ssBartik/reference/ssBartik-package.md)
  [`ssBartik-package`](https://takuma1102.github.io/ssBartik/reference/ssBartik-package.md)
  : ssBartik: End-to-End Pipeline for Shift-Share (Bartik) IV Designs
