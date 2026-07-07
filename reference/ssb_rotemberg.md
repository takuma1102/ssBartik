# Rotemberg weights for a Bartik instrument

Decomposes the shift-share 2SLS estimate into a weighted sum of the
just-identified estimates that use each sector's share as a single
instrument, following Goldsmith-Pinkham, Sorkin and Swift (2020):
\$\$\hat\beta = \sum_n \hat\alpha_n \hat\beta_n,\qquad \hat\alpha_n =
\frac{g_n\\ \tilde s_n' \tilde x}{\sum\_{n'} g\_{n'}\\ \tilde s\_{n'}'
\tilde x},\$\$ where tildes denote residualisation on the controls (and,
in panels, sector-cells are sector \\\times\\ period pairs). The weights
\\\hat\alpha_n\\ sum to one and measure the sensitivity of \\\hat\beta\\
to misspecification of each sector's instrument; a small number of large
weights is a warning sign. Unlike Goodman-Bacon weights, negative
Rotemberg weights are not automatically problematic.

## Usage

``` r
ssb_rotemberg(design)
```

## Arguments

- design:

  An \[ssb_design()\] object.

## Value

A \`data.frame\` of class \`ssb_rotemberg\`, one row per sector-cell,
with columns \`sector\`, \`g\` (shock), \`alpha\` (Rotemberg weight),
\`beta\` (just-identified estimate), \`F\` (first-stage F of that
instrument), and \`sign\`. Carries the overall estimate \`beta_hat\` as
an attribute. Pass it to \[ssb_plot_rotemberg()\] for the canonical
figure.
