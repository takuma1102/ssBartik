# Render the estimate / standard-error table as LaTeX or Markdown

Turns an \[ssb_estimate()\] table into a publication-ready comparison of
the point estimate across standard-error methods. \`"latex"\` uses
booktabs rules; \`"markdown"\` emits a GitHub pipe table. Rows whose
standard error is unavailable are dropped. Mirrors
\[format.ssb_rotemberg()\].

## Usage

``` r
# S3 method for class 'ssb_estimate'
format(
  x,
  output = c("latex", "markdown"),
  digits = 3,
  caption = NULL,
  label = "tab:ssb-estimate",
  ...
)
```

## Arguments

- x:

  An \[ssb_estimate()\] object.

- output:

  \`"latex"\` (booktabs) or \`"markdown"\` (pipe table).

- digits:

  Decimal places for the estimate, SE and interval.

- caption, label:

  Table caption and cross-reference label (LaTeX only).

- ...:

  Unused.

## Value

A character vector of the table lines (paste-ready); pass to
\`writeLines()\`.
