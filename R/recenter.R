#' Recenter the shocks (Borusyak & Hull)
#'
#' Recentering guards against non-random exposure by subtracting the expected
#' instrument implied by a shock-assignment model. v0.1 ships the simplest
#' defensible version, `method = "demean"`: subtract the exposure-weighted mean
#' shock \eqn{\bar g} from every shock. This is the GPSS "Remark 1.1"
#' normalisation --- it leaves the point estimate unchanged but makes the
#' identifying variation (deviations of shocks from their mean) explicit and is
#' a prerequisite for honest recentering.
#'
#' A full permutation/reassignment recentering (`method = "permute"`, drawing
#' counterfactual shock assignments to estimate \eqn{E[z_i]}) is stubbed: it
#' requires the user's real assignment process and will land in a later version.
#'
#' @param design An [ssb_design()] object.
#' @param method `"demean"` (implemented) or `"permute"` (stub).
#' @param ... Reserved.
#' @return A new [ssb_design()] with recentered shocks/instrument.
#' @export
ssb_recenter <- function(design, method = c("demean", "permute"), ...) {
  stopifnot(inherits(design, "ssb_design"))
  method <- match.arg(method)
  if (method == "permute") {
    message("ssb_recenter(method='permute'): not implemented in v0.1; ",
            "falling back to 'demean'. Encode your shock-assignment process ",
            "to enable permutation recentering.")
    method <- "demean"
  }
  w <- .ssb_w(design)
  imp <- colSums(w * design$mat$S) / sum(w)
  gbar <- sum(imp * design$mat$g) / sum(imp)
  d <- design
  d$shocks$shock <- d$shocks$shock - gbar
  d <- .ssb_build(d)
  attr(d, "recentered") <- list(method = "demean", gbar = gbar)
  d
}
