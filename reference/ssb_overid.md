# Overidentification / cross-instrument homogeneity test

Treats each sector's share as a separate instrument and tests whether
the just-identified estimates \\\hat\beta_n\\ are mutually consistent,
using a precision-weighted Cochran's Q statistic \\Q=\sum_n
(\hat\beta_n-\bar\beta)^2/\widehat{\mathrm{Var}}(\hat\beta_n)\\ referred
to a \\\chi^2\_{K-1}\\ distribution. Rejection points to a failure of
shares/shocks exogeneity \*\*or\*\* to treatment-effect heterogeneity
across instruments (Goldsmith-Pinkham, Sorkin & Swift 2020). Very weak
instruments are down-weighted automatically; use \`min_F\` to drop
near-dead instruments entirely.

## Usage

``` r
ssb_overid(design, min_F = 0)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- min_F:

  Drop instruments whose own first-stage F is below this.

## Value

A list (class \`ssb_overid\`) with \`Q\`, \`df\`, \`p\`, \`I2\`,
\`beta_bar\`, \`n_instruments\`, \`n_dropped\`.

## Details

\*\*Caveat.\*\* The \\\hat\beta_n\\ are estimated from the \*same\*
sample and are therefore mutually correlated; the \\\chi^2\_{K-1}\\
reference treats them as independent and ignores that covariance. Read
the p-value as a heuristic screen for gross cross-instrument
disagreement, not as a formal overidentification test — for the latter,
use a J-type test with an estimator robust to many instruments (e.g. the
HFUL-based test in Goldsmith-Pinkham, Sorkin & Swift 2020).

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_overid(d)
#> <ssBartik overidentification test (cross-instrument homogeneity)>
#>   Q = 2.44 on 9 df,  p = 0.9824
#>   I^2 = 0.0%   precision-weighted mean beta = 1.5435
#>   instruments used: 10 (dropped 0; 9 weak, F<10)
#>   small p => reject a common coefficient (exogeneity failure OR heterogeneity)
#>   (heuristic: the beta_k are mutually correlated, so the chi-square reference is approximate)
```
