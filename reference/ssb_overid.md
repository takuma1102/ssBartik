# Overidentification test across the share instruments (Sargan-Hansen)

Treats each sector's exposure share as a separate instrument — the
exogenous-shares reading of a Bartik design (Goldsmith-Pinkham, Sorkin &
Swift 2020) — estimates the corresponding overidentified IV, and reports
the Sargan-Hansen J test of the overidentifying restrictions. Rejection
points to a failure of shares exogeneity for some sectors \*\*or\*\* to
treatment-effect heterogeneity across instruments. This is a share-route
diagnostic; \[ssb_pipeline()\] runs it there.

## Usage

``` r
ssb_overid(
  design,
  estimator = c("auto", "2sls", "gmm", "liml", "jive"),
  min_F = 0,
  level = 0.95
)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- estimator:

  \`"auto"\` (default), \`"2sls"\`, \`"gmm"\`, \`"liml"\`, or
  \`"jive"\`. See Details.

- min_F:

  Drop instruments whose own first-stage F is below this before
  estimating and testing.

- level:

  Confidence level for the reported interval.

## Value

A list (class \`ssb_overid\`) with the chosen \`estimator\`, its
\`beta\`, \`se\`, \`conf.low\`/\`conf.high\`, the Hansen \`J\`
statistic, \`df\`, \`p\`, the number of instruments used \`K\` (plus
\`n_dropped\`, \`n_collinear\`, \`n_weak\`), and the per-instrument
table \`instruments\` of just-identified estimates for
\[ssb_plot_overid()\].

## Details

The J statistic comes from efficient two-step GMM with a
heteroskedasticity-robust weight matrix (cluster-robust when the design
has a \`cluster\` variable), so it accounts for the fact that the
just-identified estimates are estimated on the \*same\* sample and are
mutually correlated. Earlier versions reported a precision-weighted
Cochran Q, which is only valid when those estimates are independent; it
has been replaced.

Following the Borusyak-Hull-Jaravel JEP practical guide, several
estimators of the common coefficient are available: \`"2sls"\` and
efficient two-step \`"gmm"\` are natural when the number of instruments
\\K\\ is modest, while \`"liml"\` and \`"jive"\` (JIVE1) guard against
many-instrument bias when \\K\\ is large relative to the sample.
\`estimator = "auto"\` (default) picks 2SLS when \\K \le \max(3,
0.05\\n)\\ and LIML otherwise, with a message. When the shares sum to
one (or the sum of shares is controlled) the residualised share
instruments are exactly collinear; redundant columns are dropped
automatically, so a complete-shares design with \\K\\ sectors uses
\\K-1\\ instruments and the test has \\K-2\\ degrees of freedom,
matching the usual leave-one-share-out formulation.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_overid(d, estimator = "2sls")
#> <ssBartik overidentification test (Sargan-Hansen)>
#>   estimator : 2SLS over 9 share instruments (1 collinear dropped)
#>   beta = 1.5851   se = 0.1487   [1.294, 1.877]
#>   Hansen J = 5.77 on 8 df,  p = 0.6731
#>   instruments dropped: 0 (min_F / degenerate); weak (F<10): 9
#>   small p => reject joint validity of the share instruments
#>   (exclusion failure for some shares OR treatment-effect heterogeneity)
```
