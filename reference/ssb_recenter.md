# Recenter the shocks (Borusyak & Hull)

Recentering removes the expected instrument implied by the
shock-assignment process, so identification comes only from deviations
of shocks from their (conditional) mean. Two methods:

- \`"demean"\` (default): subtract the single exposure-weighted mean
  shock \\\bar g\\. Leaves the point estimate unchanged but makes the
  identifying variation explicit.

- \`"permute"\`: subtract the \*block-specific simple average\* shock,
  i.e. recenter within exchangeability groups. Under uniform
  within-block permutation every cell in a block is equally likely to
  receive each of the block's shocks, so \\E\[g_n\]\\ is the unweighted
  within-block mean; subtracting it gives the expectation of the
  instrument under that assignment process (Borusyak & Hull), computed
  analytically. With no \`block\` this recenters by the grand unweighted
  mean.

For randomization-inference p-values based on the same permutation idea,
see \[ssb_ri()\].

## Usage

``` r
ssb_recenter(design, method = c("demean", "permute"), block = NULL, ...)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- method:

  \`"demean"\` or \`"permute"\`.

- block:

  Exchangeability blocks for \`"permute"\`: a column name in the shocks
  table, or a vector of length equal to the number of shock-cells.

- ...:

  Reserved.

## Value

A new \[ssb_design()\] with recentered shocks/instrument (carries a
\`"recentered"\` attribute).
