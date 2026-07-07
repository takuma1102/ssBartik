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
