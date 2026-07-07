# Plot the confidence-interval comparison

Draws the (identical) point estimate with each method's confidence
interval, making the practical consequences of the inference method
immediately visible — the naive/EHW intervals are typically far too
narrow relative to the exposure-robust AKM / AKM0 intervals. The
comparison is of \*intervals\*: AKM0 is defined as an interval directly
(and can be asymmetric), so it is the interval, not a standard error,
that is the object of interest.

## Usage

``` r
ssb_plot_ci(x, title = NULL, ...)
```

## Arguments

- x:

  An \`ssb_estimate\` object (from \[ssb_estimate()\]).

- title:

  Optional plot title.

- ...:

  Ignored.

## Value

A \`ggplot\` object.
