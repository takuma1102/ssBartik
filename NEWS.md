# ssBartik 0.2.0

## Changes

* `ssb_design()` / `ssbartik()`: `exogenous` is now **required** (no default).
  The identification route fixes the automatic controls, the standard errors
  and the diagnostics, so it must be chosen deliberately.
* `ssb_estimate()` (and `ssb_placebo()`, `ssb_drop_top()`): the default
  `methods` now follow the route -- conventional `ehw` (+ `cluster` when a
  cluster variable is set) on the share route, exposure-robust `akm` / `akm0`
  on the shift route. Explicit `methods = c(...)` still overrides, and the
  printed table names the route. (Review point 1.)
* `ssb_overid()` now reports a **Sargan–Hansen J** from efficient two-step GMM
  with a robust (or cluster-robust) weight matrix, replacing the
  precision-weighted Cochran Q, which treated the mutually correlated
  just-identified estimates as independent. Estimators of the common
  coefficient: `"2sls"`, efficient `"gmm"`, and the many-instrument-robust
  `"liml"` / `"jive"` (`"auto"` picks between 2SLS and LIML by K/n).
  Collinear residualised shares are pruned automatically (complete designs
  use K−1 instruments, df = K−2). Output fields changed accordingly;
  `ssb_plot_overid()`, `format()` and `plot()` methods updated. (Point 3.)
* `ssb_pipeline()` reports only route-appropriate statistics: Rotemberg
  weights / weight summary / overidentification / share balance on the share
  route; equivalence / shock summary / shock balance on the shift route.
  Arguments belonging to the other route are skipped with a message.
  (Point 2.)
* `ssb_share_balance()` now tests the sectors with the largest
  **|Rotemberg weight|** (the shares that drive the estimate), not the
  largest average exposure, and returns their `alpha`. (Point 4.)

## Methodology fixes

* Exposure-robust (shock-level) variances in `ssb_shock_iv()`,
  `ssb_first_stage()` and `ssb_pretrend()` now use the shocks
  **residualised on the shock-level controls** (a constant, plus period
  fixed effects in panels) with exposure weights, instead of the raw shocks.
  Point estimates are unchanged; standard errors are corrected, and now match
  ShiftShareSE's AKM variance / the BHJ `ssaggregate` workflow exactly
  (verified in the test suite). (Point 7.)
* Shift-route **panels** now automatically control the sum of exposure shares
  **interacted with period fixed effects** (reducing to period FE under
  complete shares); controlling only the overall sum is not sufficient in
  panels. Auto columns are pruned of anything the user's controls already
  span, and the location-/shock-level equivalence is now exact in panels.
  (Point 6.)
* `ssb_rotemberg()` gains `demean = TRUE`: shocks are demeaned with exposure
  weights (within periods in panels) whenever the corresponding constant
  directions are absorbed by the controls, resolving the normalisation
  non-uniqueness of the decomposition; the weights are now invariant to
  adding constants to the shocks. β̂, the per-instrument estimates and Fs are
  unaffected. (Point 5.)
* `ssb_pretrend()` is route-aware: the headline `se` / `p` / interval are
  exposure-robust on the shift route and conventional (cluster / EHW) on the
  share route, with all three SEs still reported. (Point 2.)

## Verification, wording, docs

* `ssb_estimate(shock_cluster = )` was **verified** to genuinely cluster the
  shocks: it reaches ShiftShareSE's `sector_cvar` and matches a hand-computed
  cluster-robust shock-level regression; a regression test pins this down.
  `ssb_shock_iv(cluster = )` now also accepts a shocks-table column name.
  (Point 8.)
* `ssb_ri()` documents (and prints) that randomization inference requires
  shocks to be **exchangeable** within blocks -- a stronger assumption than
  BHJ as-good-as-random, which allows heteroskedastic shocks. (Point 9.)
* Shock-balance output no longer states that a non-significant test shows
  shocks are "unrelated to observables"; it reports that the null of balance
  is not rejected. (Point 10.)
* Terminology: high-weight *share instruments* (sectors), not "shocks", across
  `ssb_weight_summary()`, `ssb_loo()`, `ssb_drop_top()` output and plots.
  (Point 5.)

# ssBartik 0.1.1

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
