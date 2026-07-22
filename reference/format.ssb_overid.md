# Render an overidentification test as LaTeX or Markdown

Paste-ready statistic/value table for the \[ssb_overid()\] Sargan-Hansen
overidentification test.

## Usage

``` r
# S3 method for class 'ssb_overid'
format(
  x,
  output = c("latex", "markdown"),
  digits = 3,
  caption = NULL,
  label = "tab:ssb-overid",
  ...
)
```

## Arguments

- x:

  An \[ssb_overid()\] object.

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
