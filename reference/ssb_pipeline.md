# Run the full shift-share analysis pipeline

Given a design, runs the estimation and the route-appropriate battery of
diagnostics in one call, dispatching on \`design\$exogenous\`:

- \*\*share\*\* (Goldsmith-Pinkham, Sorkin & Swift 2020):
  Rotemberg-weight decomposition, leave-one-out sensitivity, and — if
  \`covariates\` are supplied — a share-balance check; a pre-trend check
  if \`pre_y\` is supplied.

- \*\*shift\*\* (Borusyak, Hull & Jaravel 2022): effective-shock /
  exposure-concentration summary, leave-one-out sensitivity, and the
  shock-balance hook.

Estimation always reports the full SE panel (naive / EHW / cluster / AKM
/ AKM0). The point estimate and first-stage F are common to both routes.

## Usage

``` r
ssb_pipeline(
  design,
  covariates = NULL,
  pre_y = NULL,
  placebo_y = NULL,
  shock_covariates = NULL,
  top = 5,
  level = 0.95
)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- covariates:

  Optional observables for the share-balance check (share route).

- pre_y:

  Optional pre-period outcome for \[ssb_pretrend()\].

- placebo_y:

  Optional placebo outcome for \[ssb_placebo()\].

- shock_covariates:

  Optional shock-level characteristics (a data.frame keyed by sector)
  for \[ssb_shock_balance()\] on the shift route.

- top:

  Number of top-weight sectors for the sensitivity diagnostics.

- level:

  Confidence level.

## Value

An \`ssb_result\` list with \`estimate\`, \`route\`, and route-specific
diagnostic elements. \`autoplot()\` returns the headline figure.
