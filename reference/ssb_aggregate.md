# Aggregate a shift-share design to the shock (shifter) level

Collapses the unit-level design to one row per shock, following the
Borusyak-Hull-Jaravel (2022) equivalence. With controls partialled out
of the outcome and treatment (weighted FWL), each shock \\n\\ gets an
exposure weight \\s_n=\sum_i e_i s\_{in}\\ and exposure-weighted means
\\\bar y_n=\sum_i e_i s\_{in}\tilde y_i/s_n\\ and \\\bar x_n\\
similarly. Running an IV of \\\bar y_n\\ on \\\bar x_n\\ with instrument
\\g_n\\ and weights \\s_n\\ reproduces the location-level shift-share
estimate exactly (see \[ssb_equivalence()\]).

## Usage

``` r
ssb_aggregate(design)
```

## Arguments

- design:

  An \[ssb_design()\] object.

## Value

A \`data.frame\` (class \`ssb_aggregate\`) with columns \`sector\`,
\`g\`, \`s_bar\` (exposure weight), \`x_bar\`, \`y_bar\`.
