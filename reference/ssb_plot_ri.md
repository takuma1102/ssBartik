# Randomization-inference plot

Histogram of the permuted-shock (placebo) estimates from \[ssb_ri()\],
with the observed estimate marked; the RI p-value is where the observed
value falls in this null distribution.

## Usage

``` r
ssb_plot_ri(x, bins = 30, title = NULL, ...)
```

## Arguments

- x:

  An \[ssb_ri()\] object.

- bins:

  Number of histogram bins.

- title:

  Optional plot title.

- ...:

  Unused.

## Value

A ggplot2 object.
