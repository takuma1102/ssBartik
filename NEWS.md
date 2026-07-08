# ssBartik 0.1.0.9000

First release. An end-to-end toolkit for shift-share (Bartik) instrumental
variables, spanning both identification routes (exogenous shares and exogenous
shocks) from instrument construction through estimation, inference, and
credibility diagnostics.

* Estimation: `ssb_design()`, `ssbartik()`, and `ssb_estimate()`, reporting a
  panel of confidence intervals (IID, EHW, and exposure-robust AKM / AKM0 by
  default; cluster and two-way available on request).
* Rotemberg / GPSS diagnostics: `ssb_rotemberg()`, `ssb_weight_summary()`,
  `ssb_loo()`, `ssb_drop_top()`.
* Shock-level (Borusyak-Hull-Jaravel) tools: `ssb_aggregate()`,
  `ssb_shock_iv()`, `ssb_equivalence()`, `ssb_recenter()`.
* Credibility checks: `ssb_first_stage()`, `ssb_overid()`,
  `ssb_share_balance()`, `ssb_shock_balance()`, `ssb_pretrend()`,
  `ssb_placebo()`, `ssb_ri()`.
* Output: `autoplot()` / `ssb_plot_*()` figures (including the
  `ssb_plot_ci()` interval comparison), and paste-ready tables via
  `format(x, "latex" / "markdown")` and a rendered `plot()` for the Rotemberg
  table.
