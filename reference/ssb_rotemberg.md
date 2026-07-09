# Rotemberg weights for a Bartik instrument

Decomposes the shift-share 2SLS estimate into a weighted sum of the
just-identified estimates that use each sector's share as a single
instrument, following Goldsmith-Pinkham, Sorkin and Swift (2020):
\$\$\hat\beta = \sum_n \hat\alpha_n \hat\beta_n,\qquad \hat\alpha_n =
\frac{g_n\\ \tilde s_n' \tilde x}{\sum\_{n'} g\_{n'}\\ \tilde s\_{n'}'
\tilde x},\$\$ where tildes denote residualisation on the controls (and,
in panels, sector-cells are sector \\\times\\ period pairs). The weights
\\\hat\alpha_n\\ sum to one and measure the sensitivity of \\\hat\beta\\
to misspecification of each sector's instrument; a small number of large
weights is a warning sign. Unlike Goodman-Bacon weights, negative
Rotemberg weights are not automatically problematic.

## Usage

``` r
ssb_rotemberg(design)
```

## Arguments

- design:

  An \[ssb_design()\] object.

## Value

A \`data.frame\` of class \`ssb_rotemberg\`, one row per sector-cell,
with columns \`sector\`, \`g\` (shock), \`alpha\` (Rotemberg weight),
\`beta\` (just-identified estimate), \`F\` (first-stage F of that
instrument), and \`sign\`. Carries the overall estimate \`beta_hat\` as
an attribute. Pass it to \[ssb_plot_rotemberg()\] for the canonical
figure.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_rotemberg(d)
#> <ssBartik Rotemberg weights>
#>   overall beta_hat : 1.4468
#>   sum positive alpha : 1.013   sum negative alpha : -0.013
#>   largest weight   : alpha = 0.532 (6)
#>   ! one shock carries |alpha| = 0.53; check robustness via ssb_drop_top()
#>   top 6 sectors by |alpha|:
#>  sector  alpha  beta     F
#>       6 0.5323 1.486 12.24
#>       3 0.2077 1.472  5.53
#>       8 0.1330 0.631  1.54
#>       4 0.0517 1.956  2.83
#>       9 0.0359 2.041  1.22
#>       5 0.0349 1.651  1.94
#>   (negative weights are not by themselves a red flag; see GPSS 2020)
```
