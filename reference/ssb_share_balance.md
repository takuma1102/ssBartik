# Share balance (exogenous-shares route)

For the top-exposure sectors, regresses each sector's share on
observable unit characteristics to see how strongly exposure correlates
with observables — the key credibility check when identification comes
from the shares.

## Usage

``` r
ssb_share_balance(design, covariates, top = 5)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- covariates:

  Character vector of observable columns in \`data\`.

- top:

  Number of top-exposure sectors to test.

## Value

A \`data.frame\` of slope coefficients and (robust) t-statistics of each
covariate in the share regression, one block per tested sector.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_share_balance(d, covariates = "w1", top = 3)
#>   sector covariate         coef          t
#> 1      3        w1 -0.004444499 -0.3769272
#> 2      8        w1  0.004130552  0.3064055
#> 3      9        w1  0.005451495  0.3314546
```
