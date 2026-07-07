# Placebo-outcome test

Runs the \*same\* shift-share IV but on an outcome that the treatment
should not move (a placebo). A coefficient far from zero signals that
the design is picking up something other than the intended channel. This
is distinct from \[ssb_pretrend()\], which regresses a \*pre-period\*
outcome on the instrument (reduced form) to look for differential
pre-trends.

## Usage

``` r
ssb_placebo(
  design,
  placebo_y,
  methods = c("ehw", "cluster", "akm"),
  level = 0.95
)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- placebo_y:

  Column name of the placebo outcome in \`data\`.

- methods:

  Standard-error methods (see \[ssb_estimate()\]).

- level:

  Confidence level.

## Value

An \`ssb_estimate\` for the placebo outcome.
