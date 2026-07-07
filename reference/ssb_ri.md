# Randomization-inference (placebo-shock) test

Re-draws the shocks by permutation (optionally within exchangeability
\`block\`s) and reports where the observed statistic falls in the
resulting placebo distribution, in the spirit of Adao-Kolesar-Morales
(2019) and Borusyak & Hull.

## Usage

``` r
ssb_ri(design, R = 999, block = NULL, null = 0, seed = NULL)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- R:

  Number of permutation draws.

- block:

  Optional exchangeability blocks for shocks: a column name in the
  shocks table, or a vector of length equal to the number of
  shock-cells. Shocks are permuted only within blocks. In sector x
  period panels you almost always want blocks that separate periods, so
  shocks are not permuted across time.

- null:

  The null value \\\beta_0\\ of the coefficient (default 0).

- seed:

  Optional RNG seed.

## Value

A list (class \`ssb_ri\`) with the IV point estimate \`beta\`, the
observed Anderson-Rubin \`statistic\`, \`null\`, \`p_value\`, \`R\`, and
the vector \`perm\` of placebo statistics.

## Details

The statistic is Anderson-Rubin-style: the reduced-form coefficient of
\\y - \beta_0 x\\ on the reconstructed instrument, with \\\beta_0 =\\
\`null\`. Under the constant-effects null \\\beta = \beta_0\\ (plus the
exclusion restriction), \\y - \beta_0 x\\ does not respond to how the
shocks are assigned, so the permutation distribution of this statistic
is \*exact\* given the exchangeability encoded in \`block\`. Permuting
the IV ratio itself (holding the observed treatment fixed) would \*not\*
be exact — the treatment also responds to the shocks through the first
stage, and placebo draws with weak first stages give the ratio very
heavy tails — so this function does not do that.
