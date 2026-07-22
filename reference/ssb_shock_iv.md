# Shock-level IV estimate with exposure-robust standard errors

Runs the exposure-weighted IV at the shock level (see
\[ssb_aggregate()\]), including the shock-level controls of the
Borusyak-Hull-Jaravel equivalent regression: a constant, plus period
fixed effects in panels. The point estimate equals the location-level
shift-share estimate (exactly so on the shift route, where the
corresponding location-level controls – the sum of exposure shares,
interacted with period fixed effects in panels – are in place
automatically); the heteroskedasticity- or cluster-robust standard error
of this shock-level regression is the exposure-robust (AKM-type) SE.

## Usage

``` r
ssb_shock_iv(design, cluster = NULL, level = 0.95)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- cluster:

  Optional grouping of the shocks for a cluster-robust shock-level SE: a
  column name in the shocks table, or a vector of length equal to the
  number of shock-cells.

- level:

  Confidence level for the reported interval.

## Value

A one-row \`data.frame\` (class \`ssb_shock_iv\`) with \`estimate\`,
\`std.error\`, \`conf.low\`, \`conf.high\`.

## Details

The scores use the shocks \*residualised\* on the shock-level controls
with exposure weights, \\\tilde g_n\\, not the raw \\g_n\\: the two give
the same coefficient but different standard errors, and only the
residualised version is valid (Borusyak, Hull & Jaravel; cf. their
\`ssaggregate\` workflow, against which this calculation is aligned).
