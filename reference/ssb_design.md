# Define a shift-share (Bartik) IV design

\`ssb_design()\` is the single entry point of the package. It takes the
three pieces of a shift-share design — a unit-level table, a long table
of exposure shares, and a table of shocks (shifts) — aligns them, and
constructs the Bartik instrument \\z_i = \sum_n s\_{in} g_n\\. The
resulting object flows directly into diagnostics (\[ssb_rotemberg()\],
\[ssb_shock_summary()\], ...), estimation (\[ssb_estimate()\]) and
plotting.

## Usage

``` r
ssb_design(
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
  exogenous = c("shift", "share")
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

## Value

An object of class \`ssb_design\`.

## Details

The \*\*instrument is constructed identically\*\* whichever
identification route you take; the \`exogenous\` argument only governs
which \*diagnostics\* and \*controls\* are appropriate downstream (see
\[ssb_pipeline()\]). Set \`exogenous = "share"\` for the
exogenous-shares route (Goldsmith-Pinkham, Sorkin and Swift 2020;
Rotemberg-weight diagnostics) or \`exogenous = "shift"\` for the
exogenous-shocks route (Borusyak, Hull and Jaravel 2022; Adao, Kolesar
and Morales 2019; shock-level diagnostics and AKM inference).

## Examples

``` r
sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
d
#> <ssBartik design>
#>   route      : exogenous SHARE
#>   units      : 80   sectors/cells : 10
#>   outcome/trt: y ~ x
#>   controls   : (none)
#>   weights    : (none)   cluster : (none)
#>   shares sum to one : yes
```
