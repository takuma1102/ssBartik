## Colour + shape constants matching the canonical GPSS figure -----------------
.ssb_pal   <- c(Positive = "#2C6FBB", Negative = "#E69F00")  # blue / amber
.ssb_shape <- c(Positive = 1,         Negative = 5)          # open circle / diamond

# A clean, paper-ready theme.
.ssb_theme <- function(base_size = 12) {
  ggplot2::theme_bw(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(linewidth = 0.25, colour = "grey90"),
      panel.border     = ggplot2::element_blank(),
      axis.line        = ggplot2::element_line(colour = "grey20", linewidth = 0.4),
      legend.position  = c(0.99, 0.99),
      legend.justification = c(1, 1),
      legend.background = ggplot2::element_rect(fill = "white", colour = "grey70"),
      legend.title     = ggplot2::element_blank(),
      plot.title       = ggplot2::element_text(face = "plain", size = base_size)
    )
}

#' Plot Rotemberg weights (canonical GPSS figure)
#'
#' Reproduces Figure 1 of Goldsmith-Pinkham, Sorkin and Swift (2020): each
#' sector-cell is a bubble at its first-stage F-statistic (x) and just-identified
#' estimate \eqn{\hat\beta_n} (y); bubble area is proportional to the absolute
#' Rotemberg weight; positive-weight cells are blue open circles and negative
#' ones amber open diamonds; the dashed horizontal line marks the overall
#' estimate \eqn{\hat\beta}.
#'
#' @param x An `ssb_rotemberg` object (from [ssb_rotemberg()]).
#' @param max_size Maximum bubble size.
#' @param label_top If > 0, label this many top-weight sectors.
#' @param title Optional plot title.
#' @param ... Ignored.
#' @return A `ggplot` object.
#' @export
ssb_plot_rotemberg <- function(x, max_size = 12, label_top = 0,
                               title = NULL, ...) {
  stopifnot(inherits(x, "ssb_rotemberg"))
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("ggplot2 is required for plotting; install.packages('ggplot2').")
  .data <- ggplot2::.data
  bh <- attr(x, "beta_hat")
  df <- x
  df$absw <- abs(df$alpha)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$F, y = .data$beta)) +
    ggplot2::geom_hline(yintercept = bh, linetype = "dashed",
                        colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_point(ggplot2::aes(size = .data$absw,
                                     colour = .data$sign, shape = .data$sign),
                        stroke = 0.8) +
    ggplot2::scale_colour_manual(values = .ssb_pal,
                                 labels = c(Positive = "Positive weights",
                                            Negative = "Negative weights")) +
    ggplot2::scale_shape_manual(values = .ssb_shape,
                                labels = c(Positive = "Positive weights",
                                           Negative = "Negative weights")) +
    ggplot2::scale_size_area(max_size = max_size, guide = "none") +
    ggplot2::labs(x = "First-stage F-statistic",
                  y = expression(hat(beta)[k] ~ "estimate"),
                  title = title) +
    .ssb_theme()

  if (label_top > 0 && requireNamespace("ggplot2", quietly = TRUE)) {
    top <- utils::head(df, label_top)
    p <- p + ggplot2::geom_text(data = top,
              ggplot2::aes(label = .data$sector),
              vjust = -0.9, size = 3, colour = "grey30")
  }
  p
}

#' Plot the standard-error comparison
#'
#' Draws the (identical) point estimate with each method's confidence interval,
#' making the practical consequences of the inference method immediately
#' visible --- the naive/EHW intervals are typically far too narrow relative to
#' the exposure-robust AKM / AKM0 intervals.
#'
#' @param x An `ssb_estimate` object (from [ssb_estimate()]).
#' @param title Optional plot title.
#' @param ... Ignored.
#' @return A `ggplot` object.
#' @export
ssb_plot_se <- function(x, title = NULL, ...) {
  stopifnot(inherits(x, "ssb_estimate"))
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("ggplot2 is required for plotting; install.packages('ggplot2').")
  .data <- ggplot2::.data
  df <- x[!is.na(x$std.error), , drop = FALSE]
  lev <- attr(x, "level")
  lab <- toupper(df$method)
  df$method <- factor(lab, levels = rev(lab))

  ggplot2::ggplot(df, ggplot2::aes(y = .data$method, x = .data$estimate)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.5) +
    ggplot2::geom_vline(xintercept = df$estimate[1], linetype = "dotted",
                        colour = "grey70") +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = .data$conf.low,
                                         xmax = .data$conf.high),
                            height = 0.18, colour = "#2C6FBB", linewidth = 0.6) +
    ggplot2::geom_point(size = 2.4, colour = "#1B3A5B") +
    ggplot2::expand_limits(x = 0) +      # always show the null so significance is legible
    ggplot2::labs(x = sprintf("Estimate (%.0f%% CI); vertical line at 0", 100 * lev),
                  y = NULL,
                  title = title %||% "Standard-error comparison") +
    .ssb_theme()
}

## autoplot generics -----------------------------------------------------------

#' @method autoplot ssb_rotemberg
#' @export
autoplot.ssb_rotemberg <- function(object, ...) ssb_plot_rotemberg(object, ...)

#' @method autoplot ssb_estimate
#' @export
autoplot.ssb_estimate <- function(object, ...) ssb_plot_se(object, ...)
