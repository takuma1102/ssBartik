#' Aggregate a shift-share design to the shock (shifter) level
#'
#' Collapses the unit-level design to one row per shock, following the
#' Borusyak-Hull-Jaravel (2022) equivalence. With controls partialled out of the
#' outcome and treatment (weighted FWL), each shock \eqn{n} gets an exposure
#' weight \eqn{s_n=\sum_i e_i s_{in}} and exposure-weighted means
#' \eqn{\bar y_n=\sum_i e_i s_{in}\tilde y_i/s_n} and \eqn{\bar x_n} similarly.
#' Running an IV of \eqn{\bar y_n} on \eqn{\bar x_n} with instrument \eqn{g_n}
#' and weights \eqn{s_n} reproduces the location-level shift-share estimate
#' exactly (see [ssb_equivalence()]).
#'
#' @param design An [ssb_design()] object.
#' @return A `data.frame` (class `ssb_aggregate`) with columns `sector`, `g`,
#'   `s_bar` (exposure weight), `x_bar`, `y_bar`.
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
#' ssb_aggregate(d)
#' @export
ssb_aggregate <- function(design) {
  stopifnot(inherits(design, "ssb_design"))
  d <- design; w <- .ssb_w(d); C <- .ssb_C(d); S <- d$mat$S; g <- d$mat$g
  ry <- .ssb_resid(d$data[[d$vars$y]], C, w)
  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  s_n <- as.numeric(colSums(w * S))
  out <- data.frame(
    sector = d$mat$cell_sector, g = as.numeric(g), s_bar = s_n,
    x_bar = as.numeric(colSums(w * S * rx)) / s_n,
    y_bar = as.numeric(colSums(w * S * ry)) / s_n,
    stringsAsFactors = FALSE)
  class(out) <- c("ssb_aggregate", "data.frame")
  out
}

#' Shock-level IV estimate
#'
#' Runs the exposure-weighted IV at the shock level (see [ssb_aggregate()]).
#' The point estimate equals the location-level shift-share estimate; the
#' shock-level heteroskedasticity- or cluster-robust standard error here is the
#' natural shock-level analogue of the AKM exposure-robust SE.
#'
#' @param design An [ssb_design()] object.
#' @param cluster Optional vector (length = number of shock-cells) grouping
#'   shocks into clusters for the shock-level SE.
#' @param level Confidence level for the reported interval.
#' @return A one-row `data.frame` (class `ssb_shock_iv`) with `estimate`,
#'   `std.error`, `conf.low`, `conf.high`.
#' @export
ssb_shock_iv <- function(design, cluster = NULL, level = 0.95) {
  agg <- ssb_aggregate(design)
  s <- agg$s_bar; g <- agg$g; xb <- agg$x_bar; yb <- agg$y_bar
  den  <- sum(s * g * xb)
  beta <- sum(s * g * yb) / den
  e    <- yb - beta * xb
  mom  <- s * g * e
  meat <- if (is.null(cluster)) sum(mom^2) * length(mom) / max(length(mom) - 1, 1)
          else .ssb_cluster_meat(mom, cluster)
  se <- sqrt(meat) / abs(den)
  q  <- stats::qnorm(1 - (1 - level) / 2)
  out <- data.frame(estimate = beta, std.error = se,
                    conf.low = beta - q * se, conf.high = beta + q * se)
  class(out) <- c("ssb_shock_iv", "data.frame")
  out
}

#' Check the location-level / shock-level equivalence
#'
#' Verifies numerically that the location-level shift-share IV estimate equals
#' the shock-level IV estimate (Borusyak-Hull-Jaravel 2022). A near-zero
#' difference is a strong internal-consistency check that the instrument and
#' aggregation are behaving as intended.
#'
#' @param design An [ssb_design()] object.
#' @return A list (class `ssb_equivalence`) with `location`, `shock`, and their
#'   absolute `difference`.
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
#' ssb_equivalence(d)
#' @export
ssb_equivalence <- function(design) {
  stopifnot(inherits(design, "ssb_design"))
  d <- design; w <- .ssb_w(d); C <- .ssb_C(d)
  ry <- .ssb_resid(d$data[[d$vars$y]], C, w)
  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  rz <- .ssb_resid(d$mat$z, C, w)
  b_loc <- .ssb_wip(rz, ry, w) / .ssb_wip(rz, rx, w)
  b_shk <- ssb_shock_iv(d)$estimate
  structure(list(location = b_loc, shock = b_shk,
                 difference = abs(b_loc - b_shk)),
            class = "ssb_equivalence")
}

#' @export
print.ssb_aggregate <- function(x, n = 6, ...) {
  cat(sprintf("<ssBartik shock-level data: %d shocks>\n", nrow(x)))
  print(format(utils::head(x[c("sector", "g", "s_bar", "x_bar", "y_bar")], n),
               digits = 3), row.names = FALSE)
  invisible(x)
}

#' @export
print.ssb_shock_iv <- function(x, ...) {
  cat("<ssBartik shock-level IV>\n")
  cat(sprintf("  estimate %.4f   se %.4f   [%.3f, %.3f]\n",
              x$estimate, x$std.error, x$conf.low, x$conf.high))
  invisible(x)
}

#' @export
print.ssb_equivalence <- function(x, ...) {
  cat("<ssBartik equivalence check>\n")
  cat(sprintf("  location-level SSIV : %.6f\n", x$location))
  cat(sprintf("  shock-level IV      : %.6f\n", x$shock))
  cat(sprintf("  |difference|        : %.2e  %s\n", x$difference,
              if (x$difference < 1e-6) "(match)" else "(CHECK)"))
  invisible(x)
}
