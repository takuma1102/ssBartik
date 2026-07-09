# Rotemberg-weight summary and correlations (GPSS diagnostic table)

Summarises the Rotemberg-weight diagnostic in the spirit of
Goldsmith-Pinkham, Sorkin & Swift (2020): the top-weight shocks, the
largest single weight, the correlation of the weights with the
just-identified estimates and first-stage F, and — if \`covariates\` are
supplied — the correlation between each shock's Rotemberg weight and its
exposure-weighted average of unit observables (do high-weight shocks
load on systematically different places?).

## Usage

``` r
ssb_weight_summary(design, covariates = NULL, top = 5)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- covariates:

  Optional unit-level observable columns in \`data\`.

- top:

  Number of top-weight shocks to display.

## Value

A list (class \`ssb_weight_summary\`).

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_weight_summary(d, covariates = "w1")
#> <ssBartik Rotemberg-weight summary>
#>   largest weight: alpha = 0.532 (6)
#>   cor(alpha, beta_k) = -0.23   cor(alpha, F) = 0.97
#>   cor(alpha, exposure-weighted covariate):
#>     w1                0.16
#>   top shocks by |alpha|:
#>  sector  alpha  beta     F      g
#>       6 0.5323 1.486 12.24 -2.768
#>       3 0.2077 1.472  5.53  1.670
#>       8 0.1330 0.631  1.54  1.648
#>       4 0.0517 1.956  2.83 -0.395
#>       9 0.0359 2.041  1.22  0.507
```
