# Shock-level IV estimate

Runs the exposure-weighted IV at the shock level (see
\[ssb_aggregate()\]). The point estimate equals the location-level
shift-share estimate; the shock-level heteroskedasticity- or
cluster-robust standard error here is the natural shock-level analogue
of the AKM exposure-robust SE.

## Usage

``` r
ssb_shock_iv(design, cluster = NULL, level = 0.95)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- cluster:

  Optional vector (length = number of shock-cells) grouping shocks into
  clusters for the shock-level SE.

- level:

  Confidence level for the reported interval.

## Value

A one-row \`data.frame\` (class \`ssb_shock_iv\`) with \`estimate\`,
\`std.error\`, \`conf.low\`, \`conf.high\`.
