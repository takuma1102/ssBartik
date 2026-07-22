# Overidentification dispersion plot

Forest plot of the just-identified estimates \\\hat\beta_k\\ (one per
instrument) with confidence intervals, ordered by size, against the
overidentified estimate (dashed line). Wide, mutually inconsistent
estimates signal a failure of the exogeneity assumption or
treatment-effect heterogeneity; the formal test is the Sargan-Hansen J
in the subtitle (see \[ssb_overid()\]). Point size is the first-stage F;
the axis is trimmed to the bulk since weak instruments have very wide
intervals.

## Usage

``` r
ssb_plot_overid(x, level = 0.95, xlim = NULL, title = NULL, ...)
```

## Arguments

- x:

  An \[ssb_overid()\] object.

- level:

  Confidence level for the per-instrument intervals.

- xlim:

  Optional \`c(lo, hi)\` for the horizontal axis. By default the axis is
  trimmed to the bulk of the estimates because weak single-share
  instruments have very wide intervals; widen it here to show more of
  them.

- title:

  Optional plot title.

- ...:

  Unused.

## Value

A ggplot2 object.
