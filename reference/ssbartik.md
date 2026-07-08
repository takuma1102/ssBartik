# One-call shift-share analysis

Convenience wrapper that builds an \[ssb_design()\] from raw pieces and
runs \[ssb_pipeline()\] — the "give me everything" entry point. Specify
the identification route with \`exogenous\` and the rest flows through
to diagnostics and plots.

## Usage

``` r
ssbartik(
  data,
  shares,
  shocks,
  y = "y",
  x = "x",
  location = "location",
  sector = "sector",
  time = NULL,
  controls = NULL,
  weights = NULL,
  cluster = NULL,
  share_col = "share",
  shock_col = "shock",
  exogenous = c("shift", "share"),
  covariates = NULL,
  pre_y = NULL,
  placebo_y = NULL,
  shock_covariates = NULL,
  top = 5,
  level = 0.95
)
```

## Arguments

- data:

  A unit-level \`data.frame\`: one row per location (or
  location-period). Must contain \`y\`, \`x\`, \`location\`, and any
  \`controls\`, \`weights\`, \`cluster\` columns referenced below.

- shares:

  A long \`data.frame\` of exposure shares with columns \`location\`,
  \`sector\`, the share column (\`share_col\`), and \`time\` for panels.

- shocks:

  A \`data.frame\` of shocks with columns \`sector\`, the shock column
  (\`shock_col\`), and \`time\` for panels.

- y, x:

  Column names (strings) of the outcome and endogenous treatment.

- location, sector:

  Column names of the unit and sector identifiers.

- time:

  Optional column name of a period identifier (present in \`data\`,
  \`shares\` and \`shocks\`) for panel designs.

- controls:

  Optional character vector of control columns in \`data\`. Numeric
  columns enter linearly; factor or character columns are expanded into
  dummies, so period or region fixed effects can be supplied as factors
  (in panel shift-share designs, period fixed effects are usually
  essential — shocks should be compared within periods).

- weights:

  Optional column name of regression weights in \`data\`.

- cluster:

  Optional column name of a clustering variable in \`data\`.

- share_col:

  Name of the exposure-share column in \`shares\` (default \`"share"\`).

- shock_col:

  Name of the shock (shift) column in \`shocks\` (default \`"shock"\`).

- exogenous:

  Which identification route to emphasise downstream: \`"shift"\`
  (shocks) or \`"share"\` (shares). \`"shock"\`/\`"shares"\` are
  accepted aliases.

- covariates, pre_y, placebo_y, shock_covariates, top, level:

  Passed to \[ssb_pipeline()\].

## Value

An \`ssb_result\` object.

## Examples

``` r
# Bring your own data; this is a small synthetic design for illustration.
set.seed(1)
n_loc <- 60L; n_sec <- 8L
shares <- expand.grid(location = seq_len(n_loc), sector = seq_len(n_sec))
shares$share <- stats::runif(nrow(shares))
tot <- tapply(shares$share, shares$location, sum)
shares$share <- shares$share / tot[as.character(shares$location)]
shocks <- data.frame(sector = seq_len(n_sec), shock = stats::rnorm(n_sec))
Z <- tapply(shares$share, list(shares$location, shares$sector), sum)
Z[is.na(Z)] <- 0
inst <- as.numeric(Z %*% shocks$shock)
dat <- data.frame(location = seq_len(n_loc),
                  x = 4 * inst + stats::rnorm(n_loc, sd = 0.3))
dat$y <- 1.2 * dat$x + stats::rnorm(n_loc, sd = 0.3)
res <- ssbartik(dat, shares, shocks, exogenous = "share")
res
#> == ssBartik result ==============================================
#> route : exogenous SHARE
#> 
#> <ssBartik estimate>
#>   first-stage F : 324.9
#>         method estimate std.error conf.low conf.high           note
#>            EHW     1.23    0.0382     1.15      1.30               
#>  Clustering SE     1.23        NA       NA        NA no cluster var
#>            AKM     1.23    0.0268     1.17      1.28               
#>           AKM0     1.23    0.3156     1.09      2.33               
#> 
#> <ssBartik first-stage strength>
#>   standard robust F         : 324.9
#>   effective (exposure) F    : 1168.7
#> 
#> <ssBartik equivalence check>
#>   location-level SSIV : 1.226347
#>   shock-level IV      : 1.226347
#>   |difference|        : 0.00e+00  (match)
#> 
#> <ssBartik overidentification test (cross-instrument homogeneity)>
#>   Q = 5.30 on 7 df,  p = 0.6235
#>   I^2 = 0.0%   precision-weighted mean beta = 1.2230
#>   instruments used: 8 (dropped 0; 4 weak, F<10)
#>   small p => reject a common coefficient (exogeneity failure OR heterogeneity)
#>   (heuristic: the beta_k are mutually correlated, so the chi-square reference is approximate)
#> 
#> <ssBartik Rotemberg weights>
#>   overall beta_hat : 1.2263
#>   sum positive alpha : 1.000   sum negative alpha : 0.000
#>   largest weight   : alpha = 0.462 (6)
#>   ! one shock carries |alpha| = 0.46; check robustness via ssb_drop_top()
#>   top 5 sectors by |alpha|:
#>  sector  alpha beta     F
#>       6 0.4620 1.21 36.89
#>       5 0.1370 1.32 12.01
#>       2 0.1227 1.11 10.41
#>       1 0.1003 1.34 11.99
#>       4 0.0888 1.27  6.02
#>   (negative weights are not by themselves a red flag; see GPSS 2020)
#> 
#> <ssBartik Rotemberg-weight summary>
#>   largest weight: alpha = 0.462 (6)
#>   cor(alpha, beta_k) = -0.21   cor(alpha, F) = 0.98
#>   top shocks by |alpha|:
#>  sector  alpha beta     F      g
#>       6 0.4620 1.21 36.89 -2.000
#>       5 0.1370 1.32 12.01  1.163
#>       2 0.1227 1.11 10.41  1.034
#>       1 0.1003 1.34 11.99  0.707
#>       4 0.0888 1.27  6.02 -0.879
#> 
#> [leave-one-out] overall beta = 1.2263 
#>  sector  alpha beta_drop
#>       6 0.4620      1.24
#>       5 0.1370      1.21
#>       2 0.1227      1.24
#>       1 0.1003      1.21
#>       4 0.0888      1.22
#> =================================================================
if (FALSE) { # \dontrun{
autoplot(res)                       # headline Rotemberg figure
autoplot(res$estimate)              # CI comparison
} # }
```
