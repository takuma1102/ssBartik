# Share balance (exogenous-shares route)

For the sectors with the \*\*largest absolute Rotemberg weights\*\* —
the share instruments that actually drive the estimate — regresses each
sector's share on observable unit characteristics to see how strongly
exposure correlates with observables: the key credibility check when
identification comes from the shares. Both Goldsmith-Pinkham, Sorkin &
Swift (2020) and the Borusyak-Hull-Jaravel JEP practical guide recommend
checking balance for the high-\|Rotemberg-weight\| shares, not the
shares with the largest average exposure (which earlier versions used):
a high-exposure sector with a near-zero weight contributes almost
nothing to the estimate, and misspecification there is largely harmless.

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

  Number of top-\|Rotemberg-weight\| sectors to test.

## Value

A \`data.frame\` of slope coefficients and (robust) t-statistics of each
covariate in the share regression, one block per tested sector, with the
sector's Rotemberg weight in \`alpha\`.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_share_balance(d, covariates = "w1", top = 3)
#>   sector     alpha covariate         coef          t
#> 1      6 0.5849517        w1  0.005229986  0.5201994
#> 2      3 0.1736046        w1 -0.004444499 -0.3769272
#> 3      8 0.1109170        w1  0.004130552  0.3064055
```
