# Check the location-level / shock-level equivalence

Verifies numerically that the location-level shift-share IV estimate
equals the shock-level IV estimate (Borusyak-Hull-Jaravel 2022). A
near-zero difference is a strong internal-consistency check that the
instrument and aggregation are behaving as intended.

## Usage

``` r
ssb_equivalence(design)
```

## Arguments

- design:

  An \[ssb_design()\] object.

## Value

A list (class \`ssb_equivalence\`) with \`location\`, \`shock\`, and
their absolute \`difference\`.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
ssb_equivalence(d)
#> <ssBartik equivalence check>
#>   location-level SSIV : 1.446813
#>   shock-level IV      : 1.446813
#>   |difference|        : 0.00e+00  (match)
```
