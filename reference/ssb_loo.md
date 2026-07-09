# Leave-one-sector-out sensitivity

Recomputes the overall estimate dropping each of the top sectors (by
\|Rotemberg weight\|) one at a time, to see whether identification
hinges on a single shock.

## Usage

``` r
ssb_loo(
  design,
  top = 5,
  se = c("none", "iid", "ehw", "cluster", "akm", "akm0"),
  level = 0.95
)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- top:

  Number of top-weight sectors to leave out in turn.

- se:

  Standard-error method for a confidence interval on each leave-one-out
  estimate: \`"none"\` (default; point estimates only, the original
  behaviour) or one of \`"iid"\`, \`"ehw"\`, \`"cluster"\`, \`"akm"\`,
  \`"akm0"\` (each re-estimated on the reduced design via
  \[ssb_estimate()\]). With a CI you can read whether the estimate still
  excludes 0 after dropping the most influential shock;
  \[ssb_plot_loo()\] then draws the intervals.

- level:

  Confidence level for the interval when \`se\` is not \`"none"\`.

## Value

A \`data.frame\` with the dropped \`sector\`, its \`alpha\`, and the
\`beta_drop\` obtained without it (plus the full-sample \`beta_hat\`
attribute). When \`se\` is not \`"none"\` it also has
\`conf.low\`/\`conf.high\` columns and \`se_method\`/\`level\`
attributes.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_loo(d, top = 5)
#> <ssBartik leave-one-out>  overall beta = 1.4468
#>  sector  alpha beta_drop
#>       6 0.5323      1.40
#>       3 0.2077      1.44
#>       8 0.1330      1.57
#>       4 0.0517      1.42
#>       9 0.0359      1.42
```
