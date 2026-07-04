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
      plot.title       = ggplot2::element_text(face = "plain", size = base_size,
                                               hjust = 0.5),
      plot.subtitle    = ggplot2::element_text(hjust = 0.5, colour = "grey40")
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
  lab <- .ssb_se_label(df$method)
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
    ggplot2::labs(x = sprintf("Estimate (%.0f%% CI)", 100 * lev),
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

## Additional diagnostic figures ------------------------------------------------

#' Leave-one-out sensitivity plot
#'
#' Plots the shift-share estimate re-computed with each top-weight shock dropped
#' (see [ssb_loo()]) against the full estimate (dashed line), so a result that
#' hinges on a single shock is obvious.
#'
#' @param x An [ssb_loo()] object.
#' @param title Optional plot title.
#' @param ... Unused.
#' @return A \pkg{ggplot2} object.
#' @export
ssb_plot_loo <- function(x, title = NULL, ...) {
  stopifnot(inherits(x, "ssb_loo"))
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("ggplot2 is required for plotting; install.packages('ggplot2').")
  .data <- ggplot2::.data
  bh <- attr(x, "beta_hat")
  df <- x; class(df) <- "data.frame"
  df$sector <- factor(df$sector, levels = rev(df$sector))
  ggplot2::ggplot(df, ggplot2::aes(y = .data$sector, x = .data$beta_drop)) +
    ggplot2::geom_vline(xintercept = bh, linetype = "dashed",
                        colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_point(size = 2.6, colour = "#1B3A5B") +
    ggplot2::labs(x = expression("Estimate with shock dropped" ~ (hat(beta)[-n])),
                  y = "Dropped shock",
                  title = title %||% "Leave-one-out sensitivity",
                  subtitle = sprintf("dashed line = full estimate (%.3f)", bh)) +
    .ssb_theme()
}

#' Randomization-inference plot
#'
#' Histogram of the permuted-shock (placebo) estimates from [ssb_ri()], with the
#' observed estimate marked; the RI p-value is where the observed value falls in
#' this null distribution.
#'
#' @param x An [ssb_ri()] object.
#' @param bins Number of histogram bins.
#' @param title Optional plot title.
#' @param ... Unused.
#' @return A \pkg{ggplot2} object.
#' @export
ssb_plot_ri <- function(x, bins = 30, title = NULL, ...) {
  stopifnot(inherits(x, "ssb_ri"))
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("ggplot2 is required for plotting; install.packages('ggplot2').")
  .data <- ggplot2::.data
  # single-share permutations can blow up (weak instruments); trim the tails so
  # the bulk of the null is legible. The p-value still uses ALL permutations.
  xr <- stats::quantile(x$perm, c(0.025, 0.975), na.rm = TRUE)
  xr <- range(c(as.numeric(xr), x$beta, x$null))
  keep <- is.finite(x$perm) & x$perm >= xr[1] & x$perm <= xr[2]
  ntrim <- sum(!keep)
  df <- data.frame(perm = x$perm[keep])
  sub <- sprintf("observed = %.3f;  RI p = %.3f  (%d permutations%s)",
                 x$beta, x$p_value, x$R,
                 if (ntrim > 0) sprintf("; %d tail draws off-axis", ntrim) else "")
  ggplot2::ggplot(df, ggplot2::aes(x = .data$perm)) +
    ggplot2::geom_histogram(bins = bins, fill = "grey80",
                            colour = "white", linewidth = 0.2) +
    ggplot2::geom_vline(xintercept = x$null, linetype = "dotted", colour = "grey50") +
    ggplot2::geom_vline(xintercept = x$beta, colour = "#2C6FBB", linewidth = 0.9) +
    ggplot2::labs(x = expression("Permuted-shock estimate" ~ (hat(beta))),
                  y = "Count", title = title %||% "Randomization inference",
                  subtitle = sub) +
    .ssb_theme()
}

#' Overidentification dispersion plot
#'
#' Forest plot of the just-identified estimates \eqn{\hat\beta_k} (one per
#' instrument) with confidence intervals, ordered by size, against the
#' precision-weighted mean (dashed line). Wide, mutually inconsistent estimates
#' signal a failure of the exogeneity assumption or treatment-effect
#' heterogeneity (see [ssb_overid()]). Point size is the first-stage F; the axis
#' is trimmed to the bulk since weak instruments have very wide intervals.
#'
#' @param x An [ssb_overid()] object.
#' @param level Confidence level for the per-instrument intervals.
#' @param title Optional plot title.
#' @param ... Unused.
#' @return A \pkg{ggplot2} object.
#' @export
ssb_plot_overid <- function(x, level = 0.95, title = NULL, ...) {
  stopifnot(inherits(x, "ssb_overid"))
  if (is.null(x$instruments))
    stop("this ssb_overid object predates plotting; re-run ssb_overid().")
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("ggplot2 is required for plotting; install.packages('ggplot2').")
  .data <- ggplot2::.data
  z <- stats::qnorm(1 - (1 - level) / 2)
  d <- x$instruments
  d$lo <- d$beta - z * d$se; d$hi <- d$beta + z * d$se
  d <- d[order(d$beta), , drop = FALSE]
  d$sector <- factor(d$sector, levels = d$sector)
  # weak single-share instruments have huge intervals; focus the axis on the bulk
  # of the estimates (their CIs run off the panel edge).
  qb  <- stats::quantile(d$beta, c(0.25, 0.75), na.rm = TRUE)
  pad <- as.numeric(qb[2] - qb[1])
  rng <- range(c(qb[1] - pad, qb[2] + pad, x$beta_bar))
  ggplot2::ggplot(d, ggplot2::aes(y = .data$sector, x = .data$beta)) +
    ggplot2::geom_vline(xintercept = x$beta_bar, linetype = "dashed",
                        colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = .data$lo, xmax = .data$hi),
                            height = 0, colour = "#9BB8DA", linewidth = 0.5) +
    ggplot2::geom_point(ggplot2::aes(size = .data$F), colour = "#1B3A5B") +
    ggplot2::scale_size_area(max_size = 4, guide = "none") +
    ggplot2::coord_cartesian(xlim = as.numeric(rng)) +
    ggplot2::labs(x = expression("Just-identified estimate" ~ (hat(beta)[k])),
                  y = "Instrument (sector)",
                  title = title %||% "Overidentification: dispersion of estimates",
                  subtitle = sprintf("Q = %.1f on %d df, p = %.3f;  dashed = weighted mean",
                                     x$Q, x$df, x$p)) +
    .ssb_theme()
}

#' Exposure-concentration (Lorenz) plot
#'
#' Lorenz curve of the shock exposure weights from [ssb_shock_summary()]: the
#' further the curve bows below the 45-degree line, the more the identifying
#' variation is concentrated in a few shocks. The effective number of shocks and
#' the HHI are shown in the subtitle.
#'
#' @param x An [ssb_shock_summary()] (`ssb_shocks`) object.
#' @param title Optional plot title.
#' @param ... Unused.
#' @return A \pkg{ggplot2} object.
#' @export
ssb_plot_shocks <- function(x, title = NULL, ...) {
  stopifnot(inherits(x, "ssb_shocks"))
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("ggplot2 is required for plotting; install.packages('ggplot2').")
  .data <- ggplot2::.data
  w <- sort(x$weights$weight)
  n <- length(w)
  df <- data.frame(p = c(0, seq_len(n) / n), L = c(0, cumsum(w) / sum(w)))
  ggplot2::ggplot(df, ggplot2::aes(x = .data$p, y = .data$L)) +
    ggplot2::geom_area(fill = "#2C6FBB", alpha = 0.08) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dotted",
                         colour = "grey50") +
    ggplot2::geom_line(colour = "#2C6FBB", linewidth = 0.9) +
    ggplot2::labs(x = "Cumulative share of shocks",
                  y = "Cumulative share of exposure",
                  title = title %||% "Exposure concentration (Lorenz curve)",
                  subtitle = sprintf("%d shocks; effective = %.1f (HHI %.3f)",
                                     x$n_shocks, x$effective_shocks, x$hhi)) +
    .ssb_theme()
}

#' @method autoplot ssb_loo
#' @export
autoplot.ssb_loo <- function(object, ...) ssb_plot_loo(object, ...)

#' @method autoplot ssb_ri
#' @export
autoplot.ssb_ri <- function(object, ...) ssb_plot_ri(object, ...)

#' @method autoplot ssb_overid
#' @export
autoplot.ssb_overid <- function(object, ...) ssb_plot_overid(object, ...)

#' @method autoplot ssb_shocks
#' @export
autoplot.ssb_shocks <- function(object, ...) ssb_plot_shocks(object, ...)
