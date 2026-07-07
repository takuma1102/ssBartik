# Exposure-concentration (Lorenz) plot

Lorenz curve of the shock exposure weights from \[ssb_shock_summary()\]:
the further the curve bows below the 45-degree line, the more the
identifying variation is concentrated in a few shocks. The effective
number of shocks and the HHI are shown in the subtitle.

## Usage

``` r
ssb_plot_shocks(x, title = NULL, ...)
```

## Arguments

- x:

  An \[ssb_shock_summary()\] (\`ssb_shocks\`) object.

- title:

  Optional plot title.

- ...:

  Unused.

## Value

A ggplot2 object.
