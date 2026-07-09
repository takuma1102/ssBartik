# Shock summary: effective number of shocks and exposure concentration

Reports the Borusyak-Hull-Jaravel (2022) exposure-concentration
diagnostics for the shocks route: the average exposure (importance)
weight of each shock, its Herfindahl index, and the \*effective number
of shocks\* \\1/\sum_n \bar s_n^2\\. Few effective shocks undermine the
large-n asymptotics that justify the shocks-exogeneity approach.

## Usage

``` r
ssb_shock_summary(design)
```

## Arguments

- design:

  An \[ssb_design()\] object.

## Value

A list with \`effective_shocks\`, \`hhi\`, \`n_shocks\`, and a
\`data.frame\` \`weights\` of per-shock importance weights (descending).
Class \`ssb_shocks\`.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
ssb_shock_summary(d)
#> <ssBartik shock summary>
#>   shocks (cells)     : 10
#>   effective shocks   : 9.8  (HHI 0.102)
#>   largest exposure   : 0.122 (3)
```
