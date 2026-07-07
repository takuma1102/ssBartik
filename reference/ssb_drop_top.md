# Re-estimate after dropping the top-weight shocks

Removes the \`n\` shocks with the largest absolute Rotemberg weight
\*together\* and re-estimates, to see whether the headline result
survives without the most influential shocks. (Contrast \[ssb_loo()\],
which drops one at a time.)

## Usage

``` r
ssb_drop_top(design, n = 5, methods = c("iid", "ehw", "akm", "akm0"))
```

## Arguments

- design:

  An \[ssb_design()\] object.

- n:

  Number of top-weight shocks to drop.

- methods:

  Inference methods for the comparison, passed to \[ssb_estimate()\]
  (defaults to the exposure-robust panel; add \`"cluster"\` /
  \`"twoway"\` if wanted).

## Value

A list (class \`ssb_drop_top\`) with the \`dropped\` sectors and the
\`full\` and \`reduced\` \[ssb_estimate()\] tables.
