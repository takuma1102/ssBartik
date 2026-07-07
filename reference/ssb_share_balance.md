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
