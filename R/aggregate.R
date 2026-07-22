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

# Shock-level controls for the Borusyak-Hull-Jaravel equivalent regression:
# period fixed effects in panels (the constant is added by .ssb_resid itself).
# Exposure-robust inference must residualise the shocks on these controls,
# with exposure weights, before forming the shock-level scores: using the raw
# g_n leaves the point estimate unchanged but mis-states the standard errors.
# This mirrors the BHJ ssaggregate workflow (aggregate the residualised
# location variables, then run the shock-level IV with a constant and period
# fixed effects) and is cross-checked against ShiftShareSE's AKM variance.
.ssb_shock_C <- function(design) {
  tt <- design$mat$cell_time
  if (is.null(tt)) return(NULL)
  per <- factor(tt)
  if (nlevels(per) < 2L) return(NULL)
  D <- stats::model.matrix(~ 0 + per)[, -1, drop = FALSE]
  colnames(D) <- paste0(".period", levels(per)[-1])
  D
}

#' Shock-level IV estimate with exposure-robust standard errors
#'
#' Runs the exposure-weighted IV at the shock level (see [ssb_aggregate()]),
#' including the shock-level controls of the Borusyak-Hull-Jaravel equivalent
#' regression: a constant, plus period fixed effects in panels. The point
#' estimate equals the location-level shift-share estimate (exactly so on the
#' shift route, where the corresponding location-level controls -- the sum of
#' exposure shares, interacted with period fixed effects in panels -- are in
#' place automatically); the heteroskedasticity- or cluster-robust standard
#' error of this shock-level regression is the exposure-robust (AKM-type) SE.
#'
#' The scores use the shocks *residualised* on the shock-level controls with
#' exposure weights, \eqn{\tilde g_n}, not the raw \eqn{g_n}: the two give the
#' same coefficient but different standard errors, and only the residualised
#' version is valid (Borusyak, Hull & Jaravel; cf. their `ssaggregate`
#' workflow, against which this calculation is aligned).
#'
#' @param design An [ssb_design()] object.
#' @param cluster Optional grouping of the shocks for a cluster-robust
#'   shock-level SE: a column name in the shocks table, or a vector of length
#'   equal to the number of shock-cells.
#' @param level Confidence level for the reported interval.
#' @return A one-row `data.frame` (class `ssb_shock_iv`) with `estimate`,
#'   `std.error`, `conf.low`, `conf.high`.
#' @export
ssb_shock_iv <- function(design, cluster = NULL, level = 0.95) {
  stopifnot(inherits(design, "ssb_design"))
  agg <- ssb_aggregate(design)
  s <- agg$s_bar
  # FWL at the shock level: residualise the shocks AND the aggregated
  # outcome / treatment on the shock-level controls, weighting by exposure.
  Q  <- .ssb_shock_C(design)
  gt <- .ssb_resid(agg$g,     Q, s)
  xt <- .ssb_resid(agg$x_bar, Q, s)
  yt <- .ssb_resid(agg$y_bar, Q, s)
  den  <- sum(s * gt * xt)
  beta <- sum(s * gt * yt) / den
  e    <- yt - beta * xt
  mom  <- s * gt * e
  K    <- length(mom)
  kq   <- .ssb_np(Q) + 1L             # constant + period FE + the IV slope
  cl   <- if (is.null(cluster)) NULL else .ssb_block(design, cluster)
  meat <- if (is.null(cl)) sum(mom^2) * K / max(K - kq, 1)
          else .ssb_cluster_meat(mom, cl)
  se <- sqrt(meat) / abs(den)
  q  <- stats::qnorm(1 - (1 - level) / 2)
  out <- data.frame(estimate = beta, std.error = se,
                    conf.low = beta - q * se, conf.high = beta + q * se)
  attr(out, "n_shocks")  <- K
  attr(out, "clustered") <- !is.null(cl)
  class(out) <- c("ssb_shock_iv", "data.frame")
  out
}

#' Check the location-level / shock-level equivalence
#'
#' Verifies numerically that the location-level shift-share IV estimate equals
#' the shock-level IV estimate (Borusyak-Hull-Jaravel 2022). A near-zero
#' difference is a strong internal-consistency check that the instrument and
#' aggregation are behaving as intended. Equality is exact on the shift route,
#' where the location-level regression carries the BHJ controls that translate
#' into the shock-level constant and period fixed effects (the sum of exposure
#' shares, interacted with period FE in panels) automatically; it is a
#' shift-route diagnostic and is run there by [ssb_pipeline()].
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
