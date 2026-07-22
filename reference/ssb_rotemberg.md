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
ssb_rotemberg(design, demean = TRUE)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- demean:

  Normalise the shocks by (within-period, exposure-weighted) demeaning
  before computing the weights (default \`TRUE\`; see Details).
  \`FALSE\` reproduces the raw-shock formula.

## Value

A \`data.frame\` of class \`ssb_rotemberg\`, one row per sector-cell,
with columns \`sector\`, \`g\` (shock, after any demeaning), \`alpha\`
(Rotemberg weight), \`beta\` (just-identified estimate), \`F\`
(first-stage F of that instrument), and \`sign\`. Carries the overall
estimate \`beta_hat\` and the normalisation used (\`demeaned\`) as
attributes. Pass it to \[ssb_plot_rotemberg()\] for the canonical
figure.

## Details

\*\*Normalisation.\*\* When the exposure shares sum to one (or the sum
of shares is controlled, as it is automatically on the shift route),
adding a constant to every shock leaves the instrument — and
\\\hat\beta\\ — unchanged but changes the individual weights: the
decomposition is unique only up to a normalisation of the shocks.
Following Goldsmith-Pinkham, Sorkin & Swift and Borusyak-Hull-Jaravel,
\`demean = TRUE\` (default) resolves this by demeaning the shocks with
exposure weights, \*\*within periods in a panel\*\* (when the
corresponding per-period constant directions are absorbed by the
controls). If the constant is \*not\* absorbed (incomplete shares
without a sum-of-shares control) the decomposition is already pinned
down by the raw shocks; demeaning would then change it, so the raw
shocks are kept, with a message. The just-identified estimates
\\\hat\beta_n\\, the first-stage Fs and \\\hat\beta\\ itself are
unaffected by the normalisation — only the weights are.

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
ssb_rotemberg(d)
#> <ssBartik Rotemberg weights>
#>   overall beta_hat : 1.4468
#>   sum positive alpha : 1.005   sum negative alpha : -0.005
#>   largest weight   : alpha = 0.585 (6)
#>   ! one share instrument carries |alpha| = 0.58; check robustness via ssb_drop_top()
#>   shocks demeaned (overall, exposure-weighted) before weighting -- GPSS/BHJ normalisation
#>   top 6 sectors by |alpha|:
#>  sector  alpha  beta     F
#>       6 0.5850 1.486 12.24
#>       3 0.1736 1.472  5.53
#>       8 0.1109 0.631  1.54
#>       4 0.0875 1.956  2.83
#>       9 0.0165 2.041  1.22
#>       5 0.0130 1.651  1.94
#>   (negative weights are not by themselves a red flag; see GPSS 2020)
```
