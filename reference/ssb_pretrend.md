# Pre-trend test

Reduced-form regression of a pre-period outcome on the constructed
instrument (controls partialled out). A coefficient far from zero
indicates that exposure predicts differential pre-trends — a threat to
identification. This is distinct from \[ssb_placebo()\], which runs the
\*full IV\* on a placebo outcome; pre-trends ask whether exposure
predicts the outcome \*before\* the shocks, placebo asks whether the
design moves an outcome it should not.

## Usage

``` r
ssb_pretrend(design, pre_y, level = 0.95)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- pre_y:

  Column name of the pre-period outcome (or pre-period change).

- level:

  Confidence level.

## Value

A list (class \`ssb_pretrend\`) with the reduced-form coefficient and
the route-appropriate headline \`se\`, \`p\`, \`conf.low\`/\`conf.high\`
(see Details), plus all of \`se_ehw\` / \`se_cluster\` / \`se_akm\`, the
p-values \`p_ehw\` / \`p_akm\`, and the exposure-robust interval
\`conf.low_akm\`/\`conf.high_akm\`.

## Details

The headline standard error follows the identification route of the
design. On the \*\*shift route\*\* the regressor is a shift-share
variable driven by as-good-as-random shocks, so EHW / cluster standard
errors over-reject (Adao, Kolesar & Morales 2019); the headline
\`se\`/\`p\`/interval are then exposure-robust (AKM-type), computed from
shock-level scores with the shocks residualised on the shock-level
controls (a constant, plus period fixed effects in panels) — see
\[ssb_shock_iv()\]. On the \*\*share route\*\* identification comes from
the shares and conventional inference is appropriate: the headline is
the design's cluster-robust SE if a \`cluster\` variable is set, and EHW
otherwise. All three SEs are reported either way for transparency.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
sim$data$y_pre <- stats::rnorm(nrow(sim$data))   # a pre-period outcome
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
ssb_pretrend(d, pre_y = "y_pre")   # headline p is exposure-robust
#> <ssBartik pre-trend test (reduced form on instrument)>
#>   pre-period outcome : y_pre
#>   coef 0.0988
#>   se   : EHW 0.2049 | cluster NA | exposure-robust (AKM) 0.0491
#>   headline (exogenous SHIFT) : se 0.0491, p = 0.044  [exposure-robust (AKM)]
#>   (shift route: the regressor is shift-share, EHW/cluster over-reject;
#>   the exposure-robust p is the one to read)
#>   coefficient near 0 => no differential pre-trend by exposure
```
