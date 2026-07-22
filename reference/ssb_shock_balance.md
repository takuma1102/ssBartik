# Shock-level balance test

Tests the identifying assumption of the shocks route — that shocks are
as-good-as-randomly assigned — by regressing the shocks on
pre-determined shock-level characteristics, weighted by exposure
(Borusyak, Hull & Jaravel 2022). Coefficients near zero and a
non-significant joint test are \*consistent with\* balance: the null
hypothesis of balance is not rejected. Note the asymmetry — failing to
reject does \*\*not\*\* establish that the shocks are unrelated to
observables (the test may simply lack power), whereas a rejection is
direct evidence against shock exogeneity.

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
joint Wald test of the null hypothesis of balance.
