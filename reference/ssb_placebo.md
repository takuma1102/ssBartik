# Placebo-outcome test

Runs the \*same\* shift-share IV but on an outcome that the treatment
should not move (a placebo). A coefficient far from zero signals that
the design is picking up something other than the intended channel. This
is distinct from \[ssb_pretrend()\], which regresses a \*pre-period\*
outcome on the instrument (reduced form) to look for differential
pre-trends.

## Usage

``` r
ssb_placebo(design, placebo_y, methods = NULL, level = 0.95)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- placebo_y:

  Column name of the placebo outcome in \`data\`.

- methods:

  Standard-error methods (see \[ssb_estimate()\]); \`NULL\` (default)
  uses the route-appropriate methods.

- level:

  Confidence level.

## Value

An \`ssb_estimate\` for the placebo outcome.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
sim$data$y_placebo <- stats::rnorm(nrow(sim$data))   # an unrelated outcome
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_placebo(d, placebo_y = "y_placebo")
#> <ssBartik placebo test>
#>   route         : exogenous SHARE -> conventional (EHW / cluster) inference
#>   first-stage F : 19.8
#>   full IV re-estimated with a placebo outcome, which should be unaffected
#>  method estimate std.error conf.low conf.high note
#>     EHW   0.0975     0.203     -0.3     0.495     
```
