# Render the Rotemberg-weight table as a compact booktabs figure

Draws the top-weight-shock table (see \[format.ssb_rotemberg()\] for the
columns) as a paper-style image with normal single-line row spacing.
Writes to the active device, or to \`file\` when supplied (\`.png\`
default, \`.pdf\` for vector output). For LaTeX/Markdown source use
\[format()\] instead; for the bubble scatter use
\[ssb_plot_rotemberg()\].

## Usage

``` r
# S3 method for class 'ssb_rotemberg'
plot(
  x,
  file = NULL,
  width = NULL,
  height = NULL,
  res = 200,
  n = 6,
  digits = 3,
  note = .ssb_rot_note(),
  ...
)
```

## Arguments

- x:

  An \[ssb_rotemberg()\] object.

- file:

  Optional output path; the format is taken from the extension (\`.png\`
  or \`.pdf\`).

- width, height:

  Figure size in inches; defaults adapt to the content.

- res:

  Resolution in PPI for the \`.png\` device (ignored for \`.pdf\`).

- n:

  Number of top-weight shocks to include.

- digits:

  Decimal places for the estimates and weights.

- note:

  Footnote shown left-aligned below the table (an italic "Note:" label
  is prepended). Defaults to a definition of the columns rendered in
  maths so the symbols match the headers. Pass \`NULL\` to omit it, a
  character string for a plain note (explicit line breaks honoured,
  never auto-wrapped), or your own plotmath expression.

- ...:

  Unused.

## Value

The object, invisibly (called for its side effect).
