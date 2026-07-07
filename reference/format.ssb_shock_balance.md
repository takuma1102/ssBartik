# Render a shock-balance test as LaTeX or Markdown

Paste-ready coefficient table for the \[ssb_shock_balance()\] test, with
the joint Wald statistic in a note.

## Usage

``` r
# S3 method for class 'ssb_shock_balance'
format(
  x,
  output = c("latex", "markdown"),
  digits = 3,
  caption = NULL,
  label = "tab:ssb-shock-balance",
  ...
)
```

## Arguments

- x:

  An \[ssb_shock_balance()\] object.

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
