# Changelog

## ssBartik 0.1.1

CRAN release: 2026-07-19

First release. An end-to-end toolkit for shift-share (Bartik)
instrumental variables, spanning both identification routes (exogenous
shares and exogenous shocks) from instrument construction through
estimation, inference, and credibility diagnostics.

- Estimation:
  [`ssb_design()`](https://takuma1102.github.io/ssBartik/reference/ssb_design.md),
  [`ssbartik()`](https://takuma1102.github.io/ssBartik/reference/ssbartik.md),
  and
  [`ssb_estimate()`](https://takuma1102.github.io/ssBartik/reference/ssb_estimate.md),
  reporting a panel of confidence intervals (IID, EHW, and
  exposure-robust AKM / AKM0 by default; cluster and two-way available
  on request).
- Rotemberg / GPSS diagnostics:
  [`ssb_rotemberg()`](https://takuma1102.github.io/ssBartik/reference/ssb_rotemberg.md),
  [`ssb_weight_summary()`](https://takuma1102.github.io/ssBartik/reference/ssb_weight_summary.md),
  [`ssb_loo()`](https://takuma1102.github.io/ssBartik/reference/ssb_loo.md),
  [`ssb_drop_top()`](https://takuma1102.github.io/ssBartik/reference/ssb_drop_top.md).
- Shock-level (Borusyak-Hull-Jaravel) tools:
  [`ssb_aggregate()`](https://takuma1102.github.io/ssBartik/reference/ssb_aggregate.md),
  [`ssb_shock_iv()`](https://takuma1102.github.io/ssBartik/reference/ssb_shock_iv.md),
  [`ssb_equivalence()`](https://takuma1102.github.io/ssBartik/reference/ssb_equivalence.md),
  [`ssb_recenter()`](https://takuma1102.github.io/ssBartik/reference/ssb_recenter.md).
- Credibility checks:
  [`ssb_first_stage()`](https://takuma1102.github.io/ssBartik/reference/ssb_first_stage.md),
  [`ssb_overid()`](https://takuma1102.github.io/ssBartik/reference/ssb_overid.md),
  [`ssb_share_balance()`](https://takuma1102.github.io/ssBartik/reference/ssb_share_balance.md),
  [`ssb_shock_balance()`](https://takuma1102.github.io/ssBartik/reference/ssb_shock_balance.md),
  [`ssb_pretrend()`](https://takuma1102.github.io/ssBartik/reference/ssb_pretrend.md),
  [`ssb_placebo()`](https://takuma1102.github.io/ssBartik/reference/ssb_placebo.md),
  [`ssb_ri()`](https://takuma1102.github.io/ssBartik/reference/ssb_ri.md).
- Output:
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  / `ssb_plot_*()` figures (including the
  [`ssb_plot_ci()`](https://takuma1102.github.io/ssBartik/reference/ssb_plot_ci.md)
  interval comparison), and paste-ready tables via
  `format(x, "latex" / "markdown")` and a rendered
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) for the
  Rotemberg table.
