# Estimate a shift-share IV regression with several confidence intervals

Computes the shift-share 2SLS point estimate of \`x\` on \`y\`
(instrumented by the constructed Bartik instrument, controls partialled
out via FWL) and reports a panel of intervals side by side so the
practical importance of the inference method is visible:

- \`iid\` — classical (homoskedastic) IV,

- \`ehw\` — Eicker-Huber-White (heteroskedasticity-robust),

- \`akm\`, \`akm0\` — Adao-Kolesar-Morales exposure-robust inference,
  via ShiftShareSE when installed,

- \`cluster\` — naive cluster-robust (needs \`cluster\` in the design),

- \`twoway\` — two-way cluster-robust (needs \`cluster\` in the design
  and \`cluster2\` here).

The point estimate is identical across rows; only the standard errors
and intervals differ, which is exactly what makes the comparison
instructive.

## Usage

``` r
ssb_estimate(
  design,
  methods = c("ehw", "cluster", "akm", "akm0"),
  level = 0.95,
  cluster2 = NULL,
  shock_cluster = NULL
)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- methods:

  Which methods to report. Defaults to \`ehw\`, \`cluster\`, \`akm\`,
  \`akm0\`; add \`"iid"\` (homoskedastic) and/or \`"twoway"\` for
  two-way clustering. \`cluster\` needs the design's \`cluster\` column
  (else \`NA\`).

- level:

  Confidence level for the reported intervals.

- cluster2:

  Optional second clustering column in \`data\` for the \`"twoway"\`
  method (paired with the design's \`cluster\`).

- shock_cluster:

  Optional grouping of the shocks for the AKM / AKM0 variance: a column
  name in the shocks table, or a vector of length equal to the number of
  shock-cells. Use it when shocks are mutually correlated within groups
  — e.g. sub-industries within broader industries, or sector cells of
  the same sector across periods — so the exposure-robust variance is
  clustered at the group level (Adao, Kolesar & Morales 2019; passed to
  ShiftShareSE as \`sector_cvar\`).

## Value

A \`data.frame\` of class \`ssb_estimate\` with one row per method
(\`estimate\`, \`std.error\`, \`conf.low\`, \`conf.high\`), carrying the
first-stage F as an attribute. Plot with \[ssb_plot_ci()\].

## Details

The primary object of the comparison is the \*\*confidence interval\*\*,
not the standard error: AKM0 in particular is defined directly as a
(possibly asymmetric, possibly unbounded) interval, and the
\`std.error\` reported for it is a symmetric pseudo-SE implied by that
interval rather than a conventional standard error. Read the table and
\[ssb_plot_ci()\] figure as a comparison of intervals. When the
instrument is weak the AKM0 confidence \*set\* need not be an interval
at all: it can be the whole real line or the complement of an interval
(a union of two rays). ShiftShareSE encodes the latter as \`conf.low \>
conf.high\`; \`ssb_estimate()\` flags both cases in the \`note\` column
and the table/plot methods render them accordingly.

The default panel is \`ehw\` / \`cluster\` / \`akm\` / \`akm0\`: two
classical robust SEs (heteroskedasticity- and cluster-robust) shown next
to the two exposure-robust AKM / AKM0 intervals. \`iid\` (homoskedastic)
and \`twoway\` are not in the default; request them explicitly via
\`methods\` when wanted (e.g. \`methods = c("iid", "ehw", "cluster",
"twoway", "akm", "akm0")\`, adding \`cluster2\` for two-way clustering).
The \`cluster\` row needs a \`cluster\` column in the design (set via
\[ssb_design()\]); without one it is reported as \`NA\` with a note
rather than an error.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_estimate(d)
#> <ssBartik estimate>
#>   first-stage F : 19.8
#>         method estimate std.error conf.low conf.high
#>            EHW     1.45     0.199     1.06      1.84
#>  Clustering SE     1.45        NA       NA        NA
#>            AKM     1.45     0.105     1.24      1.65
#>           AKM0     1.45       Inf     -Inf       Inf
#>                            note
#>                                
#>                  no cluster var
#>                                
#>  unbounded CI (weak instrument)
```
