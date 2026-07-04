## Publication-ready Rotemberg-weight table -----------------------------------
## Paste-ready LaTeX / Markdown via format() (or print(format=)), and a compact
## booktabs-style rendered figure via plot(). Row spacing is set to a normal
## single-line table pitch (no stretched whitespace).

# Format a numeric vector to a fixed number of decimals.
.ssb_rot_fmt <- function(v, digits) formatC(v, format = "f", digits = digits)

# Escape LaTeX-special characters in a label.
.ssb_tex_escape <- function(s) {
  s <- gsub("\\\\", "\\\\textbackslash{}", s)
  gsub("([&%$#_{}])", "\\\\\\1", s)
}

# Top-n display columns (formatted) plus the summary quantities.
.ssb_rot_disp <- function(x, n, digits) {
  n   <- min(n, nrow(x)); top <- utils::head(x, n)
  bh  <- attr(x, "beta_hat"); if (is.null(bh)) bh <- NA_real_
  list(n = n,
       sector = as.character(top$sector),
       alpha  = .ssb_rot_fmt(top$alpha, digits),
       beta   = .ssb_rot_fmt(top$beta,  digits),
       F      = .ssb_rot_fmt(top$F,     max(digits - 1L, 1L)),
       g      = .ssb_rot_fmt(top$g,     digits),
       beta_hat = bh,
       pos = sum(x$alpha[x$alpha > 0]),
       neg = sum(x$alpha[x$alpha < 0]))
}

# Build the paste-ready table lines (internal; shared by format() and print()).
.ssb_rot_text <- function(x, output = c("latex", "markdown"),
                          n = 6, digits = 3, caption = NULL,
                          label = "tab:rotemberg") {
  output <- match.arg(output)
  d  <- .ssb_rot_disp(x, n, digits)
  fb <- .ssb_rot_fmt(d$beta_hat, digits)
  fp <- .ssb_rot_fmt(d$pos, digits)
  fn <- .ssb_rot_fmt(d$neg, digits)

  if (output == "markdown") {
    hdr  <- c("Sector", "Rotemberg weight", "Just-ID estimate",
              "First-stage F", "Shock")
    algn <- c(":--", "--:", "--:", "--:", "--:")
    rows <- vapply(seq_len(d$n), function(i)
      sprintf("| %s | %s | %s | %s | %s |",
              d$sector[i], d$alpha[i], d$beta[i], d$F[i], d$g[i]),
      character(1))
    note <- sprintf(paste0("*Top %d shocks by |Rotemberg weight|. Overall ",
                           "estimate = %s; positive weights sum to %s, ",
                           "negative to %s.*"), d$n, fb, fp, fn)
    c(paste0("| ", paste(hdr,  collapse = " | "), " |"),
      paste0("| ", paste(algn, collapse = " | "), " |"),
      rows, "", note)
  } else {
    if (is.null(caption))
      caption <- sprintf(paste0("Rotemberg-weight diagnostic (top %d shocks). ",
                                "Overall $\\hat\\beta = %s$; ",
                                "$\\sum_{\\hat\\alpha>0}\\hat\\alpha = %s$, ",
                                "$\\sum_{\\hat\\alpha<0}\\hat\\alpha = %s$."),
                         d$n, fb, fp, fn)
    hdr  <- c("Sector", "$\\hat\\alpha_n$", "$\\hat\\beta_n$",
              "First-stage $F$", "$g_n$")
    rows <- vapply(seq_len(d$n), function(i)
      paste0(paste(c(.ssb_tex_escape(d$sector[i]), d$alpha[i], d$beta[i],
                     d$F[i], d$g[i]), collapse = " & "), " \\\\"),
      character(1))
    c("\\begin{table}[!ht]", "\\centering",
      sprintf("\\caption{%s}", caption),
      sprintf("\\label{%s}", label),
      "\\begin{tabular}{lrrrr}",
      "\\toprule",
      paste0(paste(hdr, collapse = " & "), " \\\\"),
      "\\midrule",
      rows,
      "\\bottomrule",
      "\\end{tabular}", "\\end{table}")
  }
}

#' Render the Rotemberg-weight table as paste-ready LaTeX or Markdown
#'
#' Turns the [ssb_rotemberg()] decomposition into a publication-quality table of
#' the top-weight shocks. The `"latex"` output uses \pkg{booktabs} rules and
#' math-mode headers (load the booktabs LaTeX package); `"markdown"` emits a
#' GitHub pipe table. Both list, per shock, the Rotemberg weight
#' \eqn{\hat\alpha_n}, its just-identified estimate \eqn{\hat\beta_n}, the
#' first-stage F and the shock \eqn{g_n}, with the overall estimate and the
#' positive/negative weight sums in a note.
#'
#' @param x An [ssb_rotemberg()] object.
#' @param output `"latex"` (booktabs) or `"markdown"` (pipe table).
#' @param n Number of top-weight shocks to include.
#' @param digits Decimal places for the estimates and weights.
#' @param caption,label Table caption and cross-reference label (LaTeX only).
#' @param ... Unused.
#' @return A character vector of lines (paste-ready). Combine with
#'   `cat(..., sep = "\n")` or `writeLines()`.
#' @seealso [plot.ssb_rotemberg()] for a rendered image, [ssb_plot_rotemberg()]
#'   for the bubble figure.
#' @export
format.ssb_rotemberg <- function(x, output = c("latex", "markdown"),
                                 n = 6, digits = 3, caption = NULL,
                                 label = "tab:rotemberg", ...) {
  .ssb_rot_text(x, output = match.arg(output), n = n, digits = digits,
                caption = caption, label = label)
}

## ---- rendered figure (compact booktabs table) -------------------------------

# Vertical layout in inches (top-down). Row pitch and rule gaps are set to a
# normal single-line table density rather than a stretched one.
.ssb_rot_layout <- function(nb) {
  c_title <- 0.13
  c_sub   <- c_title + 0.24
  y_top   <- c_sub   + 0.18
  c_head  <- y_top   + 0.15
  y_mid   <- c_head  + 0.15
  ROW     <- 0.21                         # single-line row pitch (normal table)
  c_rows  <- (y_mid + 0.16) + (seq_len(nb) - 1L) * ROW
  y_bot   <- c_rows[nb] + 0.13
  list(c_title = c_title, c_sub = c_sub, y_top = y_top, c_head = c_head,
       y_mid = y_mid, c_rows = c_rows, y_bot = y_bot, content_h = y_bot + 0.07)
}

# Pure-grid renderer (headless-safe): serif type, centred title/subtitle, three
# booktabs rules, no shading. Draws onto the current device.
.ssb_draw_rot_table <- function(x, n = 6, digits = 3) {
  d <- .ssb_rot_disp(x, n, digits)
  head_disp  <- list("Sector", quote(hat(alpha)[n]), quote(hat(beta)[n]),
                     "First-stage F", quote(italic(g)[n]))
  head_plain <- c("Sector", "alpha_n", "beta_n", "First-stage F", "g_n")
  cells <- list(d$sector, d$alpha, d$beta, d$F, d$g)
  ncol  <- length(cells); nb <- d$n

  cw    <- vapply(seq_len(ncol), function(j)
    max(nchar(head_plain[j]), max(nchar(cells[[j]]), 1L)), integer(1))
  wrel  <- cw + 3L; wfrac <- wrel / sum(wrel)
  xr <- cumsum(wfrac); xl <- xr - wfrac

  fbh <- .ssb_rot_fmt(d$beta_hat, digits)
  title <- "Rotemberg-weight diagnostic"
  sub   <- sprintf("top %d shocks by |alpha|   (overall beta-hat = %s)", nb, fbh)

  c_rule <- "#222222"; c_text <- "#111111"; c_sub <- "#555555"; ff <- "serif"
  lay <- .ssb_rot_layout(nb)

  grid::grid.newpage()
  grid::pushViewport(grid::viewport(width = 0.92, height = 1))
  on.exit(grid::popViewport(), add = TRUE)
  dev_h <- grid::convertHeight(grid::unit(1, "npc"), "inches", valueOnly = TRUE)
  ytop  <- 0.5 + (lay$content_h / 2) / max(dev_h, lay$content_h)
  at    <- function(off) grid::unit(ytop, "npc") - grid::unit(off, "inches")
  xpos  <- function(j) if (j == 1L) grid::unit(xl[1], "npc") else
    grid::unit(xr[j], "npc") - grid::unit(2, "pt")
  jjust <- function(j) if (j == 1L) c("left", "centre") else c("right", "centre")
  put   <- function(lbl, j, off, bold = FALSE)
    grid::grid.text(lbl, x = xpos(j), y = at(off), just = jjust(j),
                    gp = grid::gpar(fontsize = 11, fontfamily = ff, col = c_text,
                                    fontface = if (bold) "bold" else "plain"))
  rule  <- function(off, lwd) grid::grid.lines(
    x = grid::unit(c(0, 1), "npc"),
    y = grid::unit(c(ytop, ytop), "npc") - grid::unit(c(off, off), "inches"),
    gp = grid::gpar(col = c_rule, lwd = lwd))

  grid::grid.text(title, x = 0.5, y = at(lay$c_title), just = c("centre", "centre"),
                  gp = grid::gpar(fontface = "bold", fontsize = 15,
                                  fontfamily = ff, col = c_text))
  grid::grid.text(sub, x = 0.5, y = at(lay$c_sub), just = c("centre", "centre"),
                  gp = grid::gpar(fontsize = 10.5, fontfamily = ff, col = c_sub))
  rule(lay$y_top, 1.6)
  for (j in seq_len(ncol)) put(head_disp[[j]], j, lay$c_head, bold = TRUE)
  rule(lay$y_mid, 1.0)
  for (i in seq_len(nb))
    for (j in seq_len(ncol)) put(cells[[j]][i], j, lay$c_rows[i])
  rule(lay$y_bot, 1.6)
  invisible()
}

# Open a file device by extension (png default, pdf for vector) and draw.
.ssb_render_rot_table <- function(x, file = NULL, width = NULL, height = NULL,
                                  res = 200, n = 6, digits = 3) {
  d <- .ssb_rot_disp(x, n, digits)
  head_plain <- c("Sector", "alpha_n", "beta_n", "First-stage F", "g_n")
  cells <- list(d$sector, d$alpha, d$beta, d$F, d$g)
  cw <- vapply(seq_along(cells), function(j)
    max(nchar(head_plain[j]), max(nchar(cells[[j]]), 1L)) + 3L, integer(1))
  if (is.null(width))  width  <- max(5.5, 0.092 * sum(cw) + 1)
  if (is.null(height)) height <- .ssb_rot_layout(d$n)$content_h + 0.22

  if (!is.null(file)) {
    ext <- tolower(tools::file_ext(file))
    if (ext == "") { file <- paste0(file, ".png"); ext <- "png" }
    if (ext == "pdf") {
      grDevices::pdf(file, width = width, height = height)
    } else if (ext == "png") {
      grDevices::png(file, width = width, height = height, units = "in", res = res)
    } else {
      stop("plot() on an ssb_rotemberg writes .png or .pdf; ",
           "for .tex/.md use format(x, \"latex\"/\"markdown\").", call. = FALSE)
    }
    on.exit(grDevices::dev.off(), add = TRUE)
  }
  .ssb_draw_rot_table(x, n = n, digits = digits)
  invisible(file)
}

#' Render the Rotemberg-weight table as a compact booktabs figure
#'
#' Draws the top-weight-shock table (see [format.ssb_rotemberg()] for the
#' columns) as a paper-style image with normal single-line row spacing. Writes
#' to the active device, or to `file` when supplied (`.png` default, `.pdf` for
#' vector output). For LaTeX/Markdown source use [format()] instead; for the
#' bubble scatter use [ssb_plot_rotemberg()].
#'
#' @param x An [ssb_rotemberg()] object.
#' @param file Optional output path; the format is taken from the extension
#'   (`.png` or `.pdf`).
#' @param width,height Figure size in inches; defaults adapt to the content.
#' @param res Resolution in PPI for the `.png` device (ignored for `.pdf`).
#' @param n Number of top-weight shocks to include.
#' @param digits Decimal places for the estimates and weights.
#' @param ... Unused.
#' @return The object, invisibly (called for its side effect).
#' @export
plot.ssb_rotemberg <- function(x, file = NULL, width = NULL, height = NULL,
                               res = 200, n = 6, digits = 3, ...) {
  .ssb_render_rot_table(x, file = file, width = width, height = height,
                        res = res, n = n, digits = digits)
  invisible(x)
}
