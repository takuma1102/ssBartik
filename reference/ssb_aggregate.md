# Aggregate a shift-share design to the shock (shifter) level

Collapses the unit-level design to one row per shock, following the
Borusyak-Hull-Jaravel (2022) equivalence. With controls partialled out
of the outcome and treatment (weighted FWL), each shock \\n\\ gets an
exposure weight \\s_n=\sum_i e_i s\_{in}\\ and exposure-weighted means
\\\bar y_n=\sum_i e_i s\_{in}\tilde y_i/s_n\\ and \\\bar x_n\\
similarly. Running an IV of \\\bar y_n\\ on \\\bar x_n\\ with instrument
\\g_n\\ and weights \\s_n\\ reproduces the location-level shift-share
estimate exactly (see \[ssb_equivalence()\]).

## Usage

``` r
ssb_aggregate(design)
```

## Arguments

- design:

  An \[ssb_design()\] object.

## Value

A \`data.frame\` (class \`ssb_aggregate\`) with columns \`sector\`,
\`g\`, \`s_bar\` (exposure weight), \`x_bar\`, \`y_bar\`.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
ssb_aggregate(d)
#> <ssBartik shock-level data: 10 shocks>
#>  sector       g s_bar    x_bar  y_bar
#>       1  0.0269  6.91  0.00305  0.045
#>       2  0.4760  7.52  0.08629  0.244
#>       3  1.6698  9.76  0.22588  0.333
#>       4 -0.3953  6.68 -0.34690 -0.678
#>       5  0.4363  7.73  0.18326  0.303
#>       6 -2.7679  7.05 -0.48367 -0.719
```
