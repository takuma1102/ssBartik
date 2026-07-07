# Render a drop-top-shocks comparison as LaTeX or Markdown

Paste-ready full-vs-reduced table from \[ssb_drop_top()\].

## Usage

``` r
# S3 method for class 'ssb_drop_top'
format(
  x,
  output = c("latex", "markdown"),
  digits = 3,
  caption = NULL,
  label = "tab:ssb-droptop",
  ...
)
```

## Arguments

- x:

  An \[ssb_drop_top()\] object.

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
