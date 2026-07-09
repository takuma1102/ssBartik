#' Recenter the shocks (Borusyak & Hull)
#'
#' Recentering removes the expected instrument implied by the shock-assignment
#' process, so identification comes only from deviations of shocks from their
#' (conditional) mean. Two methods:
#' \itemize{
#'   \item `"demean"` (default): subtract the single exposure-weighted mean shock
#'         \eqn{\bar g}. Leaves the point estimate unchanged but makes the
#'         identifying variation explicit.
#'   \item `"permute"`: subtract the *block-specific simple average* shock, i.e.
#'         recenter within exchangeability groups. Under uniform within-block
#'         permutation every cell in a block is equally likely to receive each
#'         of the block's shocks, so \eqn{E[g_n]} is the unweighted within-block
#'         mean; subtracting it gives the expectation of the instrument under
#'         that assignment process (Borusyak & Hull), computed analytically.
#'         With no `block` this recenters by the grand unweighted mean.
#' }
#' For randomization-inference p-values based on the same permutation idea, see
#' [ssb_ri()].
#'
#' @param design An [ssb_design()] object.
#' @param method `"demean"` or `"permute"`.
#' @param block Exchangeability blocks for `"permute"`: a column name in the
#'   shocks table, or a vector of length equal to the number of shock-cells.
#' @param ... Reserved.
#' @return A new [ssb_design()] with recentered shocks/instrument (carries a
#'   `"recentered"` attribute).
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
#' ssb_recenter(d, method = "demean")
#' @export
ssb_recenter <- function(design, method = c("demean", "permute"),
                         block = NULL, ...) {
  stopifnot(inherits(design, "ssb_design"))
  method <- match.arg(method)
  imp <- .ssb_exposure(design)                       # exposure weight per shock
  g   <- design$mat$g

  if (method == "demean") {
    blk <- rep(1L, length(g))
  } else {
    if (is.null(block)) {
      message("ssb_recenter(method = 'permute'): no `block` given; ",
              "recentering by the grand (unweighted) mean shock.")
      blk <- rep(1L, length(g))
    } else {
      blk <- .ssb_block(design, block)
    }
  }

  # "demean" subtracts the exposure-weighted aggregate shock; "permute"
  # subtracts E[g_n] under uniform within-block permutation, which is the
  # SIMPLE within-block average (each cell is equally likely to receive each
  # of its block's shocks), not the exposure-weighted one.
  gbar <- if (method == "demean") {
    tapply(seq_along(g), blk,
           function(idx) sum(imp[idx] * g[idx]) / sum(imp[idx]))
  } else {
    tapply(g, blk, mean)
  }
  gsub <- as.numeric(gbar[as.character(blk)])

  d <- design
  d$shocks[[d$vars$shock_col]] <- d$shocks[[d$vars$shock_col]] - gsub
  d <- .ssb_build(d)
  attr(d, "recentered") <- list(method = method, block_means = gbar)
  d
}
