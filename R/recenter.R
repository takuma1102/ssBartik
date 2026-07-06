#' Recenter the shocks (Borusyak & Hull)
#'
#' Recentering removes the expected instrument implied by the shock-assignment
#' process, so identification comes only from deviations of shocks from their
#' (conditional) mean. Two methods:
#' \itemize{
#'   \item `"demean"` (default): subtract the single exposure-weighted mean shock
#'         \eqn{\bar g}. Leaves the point estimate unchanged but makes the
#'         identifying variation explicit.
#'   \item `"permute"`: subtract a *block-specific* exposure-weighted mean shock,
#'         i.e. recenter within exchangeability groups. This is the expectation
#'         of the instrument under within-block permutations of the shocks
#'         (Borusyak & Hull), computed analytically. With no `block` it reduces
#'         to `"demean"`.
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
              "this is equivalent to 'demean'.")
      blk <- rep(1L, length(g))
    } else {
      blk <- .ssb_block(design, block)
    }
  }

  gbar <- tapply(seq_along(g), blk,
                 function(idx) sum(imp[idx] * g[idx]) / sum(imp[idx]))
  gsub <- as.numeric(gbar[as.character(blk)])

  d <- design
  d$shocks[[d$vars$shock_col]] <- d$shocks[[d$vars$shock_col]] - gsub
  d <- .ssb_build(d)
  attr(d, "recentered") <- list(method = method, block_means = gbar)
  d
}
