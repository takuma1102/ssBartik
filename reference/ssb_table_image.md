# Render a result table as an image (PNG or PDF)

\`plot()\` methods that draw the same booktabs-style table \[format()\]
prints, as a standalone image — the sibling of \[plot.ssb_rotemberg()\].
Pass \`file=\` to write a \`.png\` (default) or \`.pdf\`; without
\`file\` the table is drawn on the current graphics device. For
LaTeX/Markdown source instead of an image, use \`format(x, "latex")\` /
\`format(x, "markdown")\`.

## Usage

``` r
# S3 method for class 'ssb_estimate'
plot(x, file = NULL, width = NULL, height = NULL, res = 200, digits = 3, ...)

# S3 method for class 'ssb_weight_summary'
plot(x, file = NULL, width = NULL, height = NULL, res = 200, digits = 3, ...)

# S3 method for class 'ssb_overid'
plot(x, file = NULL, width = NULL, height = NULL, res = 200, digits = 3, ...)

# S3 method for class 'ssb_loo'
plot(x, file = NULL, width = NULL, height = NULL, res = 200, digits = 3, ...)

# S3 method for class 'ssb_drop_top'
plot(x, file = NULL, width = NULL, height = NULL, res = 200, digits = 3, ...)
```

## Arguments

- x:

  A result object: an \[ssb_estimate()\] (also \[ssb_placebo()\]),
  \[ssb_weight_summary()\], \[ssb_overid()\], \[ssb_loo()\], or
  \[ssb_drop_top()\].

- file:

  Output path (\`.png\` or \`.pdf\`); \`NULL\` draws on the current
  device.

- width, height:

  Image size in inches (auto-sized when \`NULL\`).

- res:

  PNG resolution in dpi.

- digits:

  Number of decimal places.

- ...:

  Unused.

## Value

The \`file\` path, invisibly.
