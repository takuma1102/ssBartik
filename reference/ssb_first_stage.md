# First-stage strength: standard and exposure-robust (effective) F

Reports the standard heteroskedasticity-robust first-stage F of the
treatment on the constructed instrument, and an exposure-robust
"effective" F whose denominator uses the shock-level (AKM-type) variance
of the first-stage coefficient — the relevant notion when weak
\*shocks\* are the concern (in the spirit of Montiel Olea & Pflueger
2013, adapted to shift-share).

## Usage

``` r
ssb_first_stage(design)
```

## Arguments

- design:

  An \[ssb_design()\] object.

## Value

A list (class \`ssb_first_stage\`) with \`F_standard\`, \`F_effective\`,
and the first-stage coefficient \`pi\`.
