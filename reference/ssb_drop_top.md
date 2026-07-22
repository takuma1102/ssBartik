# Re-estimate after dropping the top-weight sectors

Removes the \`n\` sector-cells with the largest absolute Rotemberg
weight \*together\* and re-estimates, to see whether the headline result
survives without the most influential share instruments. (Contrast
\[ssb_loo()\], which drops one at a time.)

## Usage

``` r
ssb_drop_top(design, n = 5, methods = NULL)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- n:

  Number of top-weight sectors to drop.

- methods:

  Inference methods for the comparison, passed to \[ssb_estimate()\].
  \`NULL\` (default) uses the route-appropriate methods of
  \[ssb_estimate()\].

## Value

A list (class \`ssb_drop_top\`) with the \`dropped\` sectors and the
\`full\` and \`reduced\` \[ssb_estimate()\] tables.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_drop_top(d, n = 3)
#> <ssBartik drop-top-3>
#>   dropped: 6, 3, 8 
#>  method full reduced
#>     EHW 1.45    2.09
```
