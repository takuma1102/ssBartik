# Render a shock-exposure summary as LaTeX or Markdown

Paste-ready version of the \[ssb_shock_summary()\] diagnostic: the top
shocks by exposure weight, with the effective number of shocks and
concentration in a note.

## Usage

``` r
# S3 method for class 'ssb_shocks'
format(
  x,
  output = c("latex", "markdown"),
  digits = 3,
  caption = NULL,
  label = "tab:ssb-shocks",
  top = 8,
  ...
)
```

## Arguments

- x:

  An \[ssb_shock_summary()\] (\`ssb_shocks\`) object.

- output:

  \`"latex"\` (booktabs) or \`"markdown"\` (pipe table).

- digits:

  Decimal places for the estimate, SE and interval.

- caption, label:

  Table caption and cross-reference label (LaTeX only).

- top:

  Number of top-exposure shocks to include.

- ...:

  Unused.

## Value

A character vector of the table lines; pass to \`writeLines()\`.
