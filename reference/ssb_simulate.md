# Simulate a shift-share (Bartik) design

Generates a small, self-contained shift-share dataset in the long format
expected by \[ssb_design()\]: a unit-level table, a long shares table,
and a shocks table. Useful for examples, tests, and demonstrations.

## Usage

``` r
ssb_simulate(
  n_loc = 300,
  n_sec = 20,
  beta = 1.2,
  share_conc = 0.5,
  endog = 0.6,
  incomplete = FALSE,
  seed = NULL
)
```

## Arguments

- n_loc:

  Number of locations (units).

- n_sec:

  Number of sectors/shocks.

- beta:

  True structural coefficient of \`x\` on \`y\`.

- share_conc:

  Dirichlet concentration for exposure shares (smaller = more
  concentrated exposure, i.e. fewer effective shocks).

- endog:

  Strength of the endogeneity (correlation between the treatment error
  and the outcome error).

- incomplete:

  If \`TRUE\`, shares deliberately do not sum to one within a location
  (an incomplete-shares design).

- seed:

  Optional RNG seed.

## Value

A list with elements \`data\`, \`shares\`, \`shocks\`, and \`beta\` (the
true coefficient), suitable for passing to \[ssb_design()\].
