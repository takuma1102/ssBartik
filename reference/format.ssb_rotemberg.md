# Render the Rotemberg-weight table as paste-ready LaTeX or Markdown

Turns the \[ssb_rotemberg()\] decomposition into a publication-quality
table of the top-weight shocks. The \`"latex"\` output uses booktabs
rules and math-mode headers (load the booktabs LaTeX package);
\`"markdown"\` emits a GitHub pipe table. Both list, per shock, the
Rotemberg weight \\\hat\alpha_n\\, its just-identified estimate
\\\hat\beta_n\\, the first-stage F and the shock \\g_n\\, with the
overall estimate and the positive/negative weight sums in a note.

## Usage

``` r
# S3 method for class 'ssb_rotemberg'
format(
  x,
  output = c("latex", "markdown"),
  n = 6,
  digits = 3,
  caption = NULL,
  label = "tab:rotemberg",
  ...
)
```

## Arguments

- x:

  An \[ssb_rotemberg()\] object.

- output:

  \`"latex"\` (booktabs) or \`"markdown"\` (pipe table).

- n:

  Number of top-weight shocks to include.

- digits:

  Decimal places for the estimates and weights.

- caption, label:

  Table caption and cross-reference label (LaTeX only).

- ...:

  Unused.

## Value

A character vector of the table lines (paste-ready); pass to
\`writeLines()\`.

## See also

\[plot.ssb_rotemberg()\] for a rendered image, \[ssb_plot_rotemberg()\]
for the bubble figure.
