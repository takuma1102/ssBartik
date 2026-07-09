# Leave-one-out sensitivity plot

Plots the shift-share estimate re-computed with each top-weight shock
dropped (see \[ssb_loo()\]) against the full estimate (dashed line), so
a result that hinges on a single shock is obvious.

## Usage

``` r
ssb_plot_loo(x, title = NULL, ...)
```

## Arguments

- x:

  An \[ssb_loo()\] object.

- title:

  Optional plot title.

- ...:

  Unused.

## Value

A ggplot2 object.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_plot_loo(ssb_loo(d, top = 5))
```
