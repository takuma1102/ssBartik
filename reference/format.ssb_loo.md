# Render a leave-one-out table as LaTeX or Markdown

Paste-ready version of the \[ssb_loo()\] sensitivity table (one row per
dropped shock, with the re-estimated coefficient); the overall estimate
is in a note.

## Usage

``` r
# S3 method for class 'ssb_loo'
format(
  x,
  output = c("latex", "markdown"),
  digits = 3,
  caption = NULL,
  label = "tab:ssb-loo",
  ...
)
```

## Arguments

- x:

  An \[ssb_loo()\] object.

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
