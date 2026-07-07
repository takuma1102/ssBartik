# Generic booktabs-style table -> image renderer.
#
# The Rotemberg diagnostic already renders to a PNG/PDF via plot.ssb_rotemberg()
# (see rotemberg_table.R). These helpers generalise the same grid drawing to any
# result object that has a format() method, so plot(x, file = "...") draws the
# same table format() prints -- for ssb_estimate / ssb_weight_summary /
# ssb_overid / ssb_loo / ssb_drop_top. Layout is shared with the Rotemberg
# renderer via .ssb_rot_layout(); only the column extraction differs.

# Format one data-frame column to display strings (plain text: NA -> "",
# +/-Inf -> "Inf"/"-Inf", numeric -> fixed digits; character passed through).
.ssb_img_cell <- function(col, digits) {
  if (is.numeric(col))
    vapply(col, function(v) {
      if (is.na(v)) ""
      else if (is.infinite(v)) (if (v > 0) "Inf" else "-Inf")
      else formatC(v, format = "f", digits = digits)
    }, character(1))
  else as.character(col)
}

# Draw a table (title, subtitle, header, rows, note) on the current device.
# `cells` is a list of character-vector columns; `headers` plain strings;
# `align` a vector of "l"/"r" per column.
.ssb_draw_grid_table <- function(cells, headers, title, sub = NULL,
                                 note_lines = list(), align = NULL) {
  ncol <- length(cells); nb <- length(cells[[1]])
  if (is.null(align)) align <- c("l", rep("r", max(ncol - 1L, 0L)))
  cw   <- vapply(seq_len(ncol), function(j)
    max(nchar(headers[j]), max(nchar(cells[[j]]), 1L)), integer(1))
  wrel <- cw + 2L; wfrac <- wrel / sum(wrel)
  xr <- cumsum(wfrac); xl <- xr - wfrac

  c_rule <- "#222222"; c_text <- "#111111"; c_sub <- "#555555"; ff <- "serif"
  lay <- .ssb_rot_layout(nb, length(note_lines))

  grid::grid.newpage()
  grid::pushViewport(grid::viewport(width = 0.92, height = 1))
  on.exit(grid::popViewport(), add = TRUE)
  dev_h <- grid::convertHeight(grid::unit(1, "npc"), "inches", valueOnly = TRUE)
  ytop  <- 0.5 + (lay$content_h / 2) / max(dev_h, lay$content_h)
  at    <- function(off) grid::unit(ytop, "npc") - grid::unit(off, "inches")
  xpos  <- function(j) if (align[j] == "l") grid::unit(xl[j], "npc") else
    grid::unit(xr[j], "npc") - grid::unit(2, "pt")
  jjust <- function(j) if (align[j] == "l") c("left", "centre") else
    c("right", "centre")
  put   <- function(lbl, j, off, bold = FALSE)
    grid::grid.text(lbl, x = xpos(j), y = at(off), just = jjust(j),
                    gp = grid::gpar(fontsize = 11, fontfamily = ff, col = c_text,
                                    fontface = if (bold) "bold" else "plain"))
  rule  <- function(off, lwd) grid::grid.lines(
    x = grid::unit(c(0, 1), "npc"),
    y = grid::unit(c(ytop, ytop), "npc") - grid::unit(c(off, off), "inches"),
    gp = grid::gpar(col = c_rule, lwd = lwd))

  grid::grid.text(title, x = 0.5, y = at(lay$c_title),
                  just = c("centre", "centre"),
                  gp = grid::gpar(fontface = "bold", fontsize = 15,
                                  fontfamily = ff, col = c_text))
  if (!is.null(sub) && nzchar(sub))
    grid::grid.text(sub, x = 0.5, y = at(lay$c_sub), just = c("centre", "centre"),
                    gp = grid::gpar(fontsize = 10.5, fontfamily = ff, col = c_sub))
  rule(lay$y_top, 1.6)
  for (j in seq_len(ncol)) put(headers[j], j, lay$c_head, bold = TRUE)
  rule(lay$y_mid, 1.0)
  for (i in seq_len(nb))
    for (j in seq_len(ncol)) put(cells[[j]][i], j, lay$c_rows[i])
  rule(lay$y_bot, 1.6)
  if (length(note_lines)) {
    vp_w   <- grid::convertWidth(grid::unit(1, "npc"), "inches", valueOnly = TRUE)
    indent <- grid::unit(0.34 / vp_w, "npc")
    grid::grid.text("Note:", x = grid::unit(0, "npc"), y = at(lay$y_note),
                    just = c("left", "centre"),
                    gp = grid::gpar(fontface = "italic", fontsize = 8.5,
                                    fontfamily = ff, col = c_sub))
    for (i in seq_along(note_lines))
      grid::grid.text(note_lines[[i]], x = indent,
                      y = at(lay$y_note + (i - 1L) * lay$note_pitch),
                      just = c("left", "centre"),
                      gp = grid::gpar(fontsize = 8.5, fontfamily = ff, col = c_sub))
  }
  invisible()
}

# Open a device (if `file` given), size it to the content + note, and draw.
.ssb_render_grid_table <- function(cells, headers, title, sub = NULL,
                                   note_lines = list(), align = NULL,
                                   file = NULL, width = NULL, height = NULL,
                                   res = 200) {
  nb <- length(cells[[1]]); ncol <- length(cells)
  cw <- vapply(seq_len(ncol), function(j)
    max(nchar(headers[j]), max(nchar(cells[[j]]), 1L)) + 2L, integer(1))
  auto_w <- is.null(width)
  if (auto_w) width <- max(5.5, 0.092 * sum(cw) + 1)
  if (length(note_lines) && auto_w) {
    nw <- tryCatch({
      tf <- tempfile(fileext = ".pdf"); grDevices::pdf(tf, width = 30, height = 3)
      w <- max(vapply(note_lines, function(L) grid::convertWidth(grid::grobWidth(
        grid::textGrob(L, gp = grid::gpar(fontsize = 8.5, fontfamily = "serif"))),
        "inches", valueOnly = TRUE), numeric(1)))
      grDevices::dev.off(); unlink(tf); w
    }, error = function(e) 4.5)
    width <- max(width, (0.34 + nw + 0.25) / 0.92)
  }
  if (is.null(height))
    height <- .ssb_rot_layout(nb, length(note_lines))$content_h + 0.22

  if (!is.null(file)) {
    ext <- tolower(tools::file_ext(file))
    if (ext == "") { file <- paste0(file, ".png"); ext <- "png" }
    if (ext == "pdf") {
      grDevices::pdf(file, width = width, height = height)
    } else if (ext == "png") {
      grDevices::png(file, width = width, height = height, units = "in", res = res)
    } else {
      stop("plot() on this object writes .png or .pdf; ",
           "for .tex/.md use format(x, \"latex\"/\"markdown\").", call. = FALSE)
    }
    on.exit(grDevices::dev.off(), add = TRUE)
  }
  .ssb_draw_grid_table(cells, headers, title, sub, note_lines, align)
  invisible(file)
}

# Bridge: (data.frame, headers, note text) -> rendered image. Long notes are
# wrapped to `wrap` characters so the image width stays sensible.
.ssb_image_table <- function(df, headers, align = NULL, title = "",
                             subtitle = NULL, note = NULL, file = NULL,
                             width = NULL, height = NULL, res = 200,
                             digits = 3, wrap = 92) {
  cells <- lapply(df, .ssb_img_cell, digits = digits)
  note_lines <- if (!is.null(note) && nzchar(note))
    as.list(strwrap(note, width = wrap)) else list()
  .ssb_render_grid_table(cells, headers, title, subtitle, note_lines, align,
                         file = file, width = width, height = height, res = res)
}

#' Render a result table as an image (PNG or PDF)
#'
#' `plot()` methods that draw the same booktabs-style table [format()] prints,
#' as a standalone image --- the sibling of [plot.ssb_rotemberg()]. Pass `file=`
#' to write a `.png` (default) or `.pdf`; without `file` the table is drawn on
#' the current graphics device. For LaTeX/Markdown source instead of an image,
#' use `format(x, "latex")` / `format(x, "markdown")`.
#'
#' @param x A result object: an [ssb_estimate()] (also [ssb_placebo()]),
#'   [ssb_weight_summary()], [ssb_overid()], [ssb_loo()], or [ssb_drop_top()].
#' @param file Output path (`.png` or `.pdf`); `NULL` draws on the current device.
#' @param width,height Image size in inches (auto-sized when `NULL`).
#' @param res PNG resolution in dpi.
#' @param digits Number of decimal places.
#' @param ... Unused.
#' @return The `file` path, invisibly.
#' @name ssb_table_image
NULL

#' @rdname ssb_table_image
#' @export
plot.ssb_estimate <- function(x, file = NULL, width = NULL, height = NULL,
                              res = 200, digits = 3, ...) {
  d   <- x[!is.na(x$std.error), , drop = FALSE]
  lev <- attr(x, "level") %||% 0.95
  fst <- attr(x, "fstat")
  num <- function(v) if (is.na(v)) "" else if (is.infinite(v))
    (if (v > 0) "Inf" else "-Inf") else formatC(v, format = "f", digits = digits)
  ci <- function(lo, hi) {
    l <- num(lo); h <- num(hi)
    if (l == "" && h == "") return("")
    if (is.finite(lo) && is.finite(hi) && lo > hi)
      return(sprintf("(-Inf, %s] U [%s, Inf)", h, l))   # disjoint AKM0 set
    sprintf("[%s, %s]", l, h)
  }
  df <- data.frame(method = .ssb_se_label(d$method),
                   estimate = d$estimate, se = d$std.error,
                   ci = mapply(ci, d$conf.low, d$conf.high),
                   stringsAsFactors = FALSE)
  disj <- any(is.finite(d$conf.low) & is.finite(d$conf.high) &
                d$conf.low > d$conf.high) ||
          any(!is.finite(d$conf.low) | !is.finite(d$conf.high))
  note <- if (disj)
    paste0("Some confidence sets are unbounded or disjoint (weak instrument); ",
           "shown as the complement of an interval.") else NULL
  sub <- if (is.null(fst) || is.na(fst)) "" else sprintf("First-stage F = %.1f", fst)
  .ssb_image_table(df,
    headers = c("Method", "Estimate", "Std. error", sprintf("%.0f%% CI", 100 * lev)),
    align = c("l", "r", "r", "r"), title = "Shift-share estimate",
    subtitle = sub, note = note, file = file, width = width, height = height,
    res = res, digits = digits)
}

#' @rdname ssb_table_image
#' @export
plot.ssb_weight_summary <- function(x, file = NULL, width = NULL, height = NULL,
                                    res = 200, digits = 3, ...) {
  tp <- x$top
  df <- data.frame(sector = as.character(tp$sector), alpha = tp$alpha,
                   beta = tp$beta, F = tp$F, g = tp$g, stringsAsFactors = FALSE)
  cc <- if (!is.null(x$cov_cor))
    paste0(", with covariate exposure ",
           paste(sprintf("(%s) %.2f", names(x$cov_cor), x$cov_cor), collapse = ", "))
  else ""
  note <- sprintf(paste0("Largest weight = %.3f (%s). Correlation of weights ",
                         "with just-ID estimates = %.2f, with first-stage F = %.2f%s."),
                  x$max_alpha, x$max_sector, x$cor[["alpha_vs_beta"]],
                  x$cor[["alpha_vs_F"]], cc)
  .ssb_image_table(df,
    headers = c("Sector", "Rotemberg weight", "Just-ID estimate",
                "First-stage F", "Shock"),
    align = c("l", "r", "r", "r", "r"), title = "Rotemberg-weight summary",
    subtitle = sprintf("Top %d shocks by |alpha|", nrow(tp)), note = note,
    file = file, width = width, height = height, res = res, digits = digits)
}

#' @rdname ssb_table_image
#' @export
plot.ssb_overid <- function(x, file = NULL, width = NULL, height = NULL,
                            res = 200, digits = 3, ...) {
  i2 <- sprintf("%.1f%%", 100 * x$I2)
  df <- data.frame(
    statistic = c("Q", "df", "p-value", "I-squared",
                  "Weighted mean estimate", "Instruments used"),
    value = c(formatC(x$Q, format = "f", digits = 2), as.character(x$df),
              formatC(x$p, format = "f", digits = 4), i2,
              formatC(x$beta_bar, format = "f", digits = digits),
              as.character(x$n_instruments)),
    stringsAsFactors = FALSE)
  .ssb_image_table(df, headers = c("Statistic", "Value"), align = c("l", "r"),
    title = "Overidentification test", subtitle = "Cross-instrument homogeneity",
    note = paste0("Q = Cochran's Q. Small p rejects a common coefficient ",
                  "(exogeneity failure or heterogeneity). The just-identified ",
                  "estimates are mutually correlated, so the chi-square reference ",
                  "is a heuristic screen."),
    file = file, width = width, height = height, res = res, digits = digits)
}

#' @rdname ssb_table_image
#' @export
plot.ssb_loo <- function(x, file = NULL, width = NULL, height = NULL,
                         res = 200, digits = 3, ...) {
  df <- data.frame(sector = as.character(x$sector), alpha = x$alpha,
                   beta = x$beta_drop, stringsAsFactors = FALSE)
  headers <- c("Sector", "Rotemberg weight", "Estimate without shock")
  align   <- c("l", "r", "r")
  sub     <- sprintf("Overall estimate = %s",
                     formatC(attr(x, "beta_hat"), format = "f", digits = digits))
  if (all(c("conf.low", "conf.high") %in% names(x))) {
    fmt <- function(v) ifelse(is.na(v), "", formatC(v, format = "f", digits = digits))
    df$ci <- ifelse(fmt(x$conf.low) == "" & fmt(x$conf.high) == "", "",
                    sprintf("[%s, %s]", fmt(x$conf.low), fmt(x$conf.high)))
    lev <- attr(x, "level") %||% 0.95
    headers <- c(headers, sprintf("%.0f%% CI", 100 * lev)); align <- c(align, "r")
    sub <- sprintf("%s;  %s CI", sub, toupper(attr(x, "se_method") %||% ""))
  }
  .ssb_image_table(df, headers = headers, align = align,
    title = "Leave-one-out sensitivity", subtitle = sub, note = NULL,
    file = file, width = width, height = height, res = res, digits = digits)
}

#' @rdname ssb_table_image
#' @export
plot.ssb_drop_top <- function(x, file = NULL, width = NULL, height = NULL,
                              res = 200, digits = 3, ...) {
  df <- data.frame(method = .ssb_se_label(x$full$method),
                   full = x$full$estimate, reduced = x$reduced$estimate,
                   stringsAsFactors = FALSE)
  .ssb_image_table(df,
    headers = c("Method", "Full", sprintf("Drop top %d", x$n)),
    align = c("l", "r", "r"),
    title = sprintf("Estimate after dropping the top %d shocks", x$n),
    subtitle = sprintf("Dropped: %s", paste(utils::head(x$dropped, 8), collapse = ", ")),
    note = NULL, file = file, width = width, height = height, res = res,
    digits = digits)
}
