# Shock-level balance test

Tests the identifying assumption of the shocks route — that shocks are
as-good-as-randomly assigned — by regressing the shocks on
pre-determined shock-level characteristics, weighted by exposure
(Borusyak, Hull & Jaravel 2022). Coefficients near zero and a
non-significant joint test support shock exogeneity.

## Usage

``` r
ssb_shock_balance(design, shock_covariates, weight = TRUE)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- shock_covariates:

  A \`data.frame\` keyed by \`sector\` (and \`time\` for panels) holding
  the shock-level characteristics to test.

- weight:

  If \`TRUE\` (default) weight by exposure \\s_n\\; else unweighted.

## Value

A list (class \`ssb_shock_balance\`) with a coefficient table and the
joint Wald test that the characteristics are unrelated to the shocks.
