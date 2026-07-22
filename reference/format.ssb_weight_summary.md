# Render a Rotemberg-weight summary as LaTeX or Markdown

Paste-ready version of the \[ssb_weight_summary()\] table (top share
instruments by weight), with the largest weight and the
weight/estimate/F correlations in a note.

## Usage

``` r
# S3 method for class 'ssb_weight_summary'
format(
  x,
  output = c("latex", "markdown"),
  digits = 3,
  caption = NULL,
  label = "tab:ssb-weights",
  ...
)
```

## Arguments

- x:

  An \[ssb_weight_summary()\] object.

- output:

  \`"latex"\` (booktabs) or \`"markdown"\` (pipe table).

- digits:

  Decimal places for the estimate, SE and interval.

- caption, label:

  Table caption and cross-reference label (LaTeX only).

- ...:

  Unused.

## Value

A character vector of the table lines; pass to \`writeLines()\`.
