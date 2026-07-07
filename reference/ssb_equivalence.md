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
