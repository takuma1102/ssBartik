#' Shock summary: effective number of shocks and exposure concentration
#'
#' Reports the Borusyak-Hull-Jaravel (2022) exposure-concentration diagnostics
#' for the shocks route: the average exposure (importance) weight of each shock,
#' its Herfindahl index, and the *effective number of shocks*
#' \eqn{1/\sum_n \bar s_n^2}. Few effective shocks undermine the large-n
#' asymptotics that justify the shocks-exogeneity approach.
#'
#' @param design An [ssb_design()] object.
#' @return A list with `effective_shocks`, `hhi`, `n_shocks`, and a `data.frame`
#'   `weights` of per-shock importance weights (descending). Class `ssb_shocks`.
#' @export
ssb_shock_summary <- function(design) {
  stopifnot(inherits(design, "ssb_design"))
  w <- .ssb_w(design)
  S <- design$mat$S
  imp <- colSums(w * S) / sum(w)         # average exposure per shock
  imp <- imp / sum(imp)                  # normalise to importance weights
  hhi <- sum(imp^2)
  df <- data.frame(sector = design$mat$cell_sector, weight = imp,
                   stringsAsFactors = FALSE)
  df <- df[order(-df$weight), , drop = FALSE]; rownames(df) <- NULL
  structure(list(effective_shocks = 1 / hhi, hhi = hhi,
                 n_shocks = ncol(S), weights = df),
            class = "ssb_shocks")
}

#' @export
print.ssb_shocks <- function(x, ...) {
  cat("<ssBartik shock summary>\n")
  cat(sprintf("  shocks (cells)     : %d\n", x$n_shocks))
  cat(sprintf("  effective shocks   : %.1f  (HHI %.3f)\n",
              x$effective_shocks, x$hhi))
  cat(sprintf("  largest exposure   : %.3f (%s)\n",
              x$weights$weight[1], x$weights$sector[1]))
  invisible(x)
}

#' Leave-one-sector-out sensitivity
#'
#' Recomputes the overall estimate dropping each of the top sectors (by
#' |Rotemberg weight|) one at a time, to see whether identification hinges on a
#' single shock.
#'
#' @param design An [ssb_design()] object.
#' @param top Number of top-weight sectors to leave out in turn.
#' @return A `data.frame` with the dropped `sector`, its `alpha`, and the
#'   `beta_drop` obtained without it (plus the full-sample `beta_hat` attribute).
#' @export
ssb_loo <- function(design, top = 5) {
  rot <- ssb_rotemberg(design)
  bh  <- attr(rot, "beta_hat")
  w <- .ssb_w(design); C <- .ssb_C(design)
  S <- design$mat$S; g <- design$mat$g
  rx <- .ssb_resid(design$data[[design$vars$x]], C, w)
  ry <- .ssb_resid(design$data[[design$vars$y]], C, w)
  cell <- design$mat$cell_sector
  top <- min(top, nrow(rot))
  res <- lapply(seq_len(top), function(i) {
    k <- which(cell == rot$sector[i])
    keep <- setdiff(seq_along(g), k)
    zt <- as.numeric(S[, keep, drop = FALSE] %*% g[keep])
    rz <- .ssb_resid(zt, C, w)
    b  <- .ssb_wip(rz, ry, w) / .ssb_wip(rz, rx, w)
    data.frame(sector = rot$sector[i], alpha = rot$alpha[i], beta_drop = b,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, res)
  attr(out, "beta_hat") <- bh
  out
}

#' Share balance (exogenous-shares route)
#'
#' For the top-exposure sectors, regresses each sector's share on observable
#' unit characteristics to see how strongly exposure correlates with observables
#' --- the key credibility check when identification comes from the shares.
#'
#' @param design An [ssb_design()] object.
#' @param covariates Character vector of observable columns in `data`.
#' @param top Number of top-exposure sectors to test.
#' @return A `data.frame` of slope coefficients and (robust) t-statistics of
#'   each covariate in the share regression, one block per tested sector.
#' @export
ssb_share_balance <- function(design, covariates, top = 5) {
  stopifnot(inherits(design, "ssb_design"))
  miss <- setdiff(covariates, names(design$data))
  if (length(miss)) stop("covariates not in data: ", paste(miss, collapse = ", "))
  w <- .ssb_w(design)
  imp <- colSums(w * design$mat$S) / sum(w)
  ord <- order(-imp)[seq_len(min(top, ncol(design$mat$S)))]
  X <- as.matrix(design$data[, covariates, drop = FALSE])
  res <- lapply(ord, function(k) {
    sk <- design$mat$S[, k]
    fit <- stats::lm.wfit(cbind(1, X), sk, w)
    b <- fit$coefficients[-1]
    # HC1 t-stats
    Xd <- cbind(1, X); e <- fit$residuals
    bread <- solve(crossprod(Xd * sqrt(w)))
    meat <- crossprod(Xd * (w * e))
    V <- bread %*% meat %*% bread
    tval <- b / sqrt(diag(V)[-1])
    data.frame(sector = design$mat$cell_sector[k],
               covariate = covariates, coef = b, t = tval,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, res); rownames(out) <- NULL
  out
}

#' Pre-trend / placebo check (stub)
#'
#' Regresses a pre-period outcome on the constructed instrument. Not yet
#' implemented in v0.1: the design object does not yet carry pre-period
#' outcomes. Supply them via `pre_y` in a future release, or run the check
#' manually by building an [ssb_design()] with the pre-period outcome as `y`.
#'
#' @param design An [ssb_design()] object.
#' @param pre_y Optional pre-period outcome column in `data`.
#' @export
ssb_pretrend <- function(design, pre_y = NULL) {
  if (is.null(pre_y)) {
    message("ssb_pretrend(): supply `pre_y`, or rebuild the design with the ",
            "pre-period outcome as `y` and call ssb_estimate(). (stub in v0.1)")
    return(invisible(NULL))
  }
  d2 <- design; d2$vars$y <- pre_y
  ssb_estimate(d2, methods = c("ehw", "cluster"))
}

#' Shock-level balance test (stub)
#'
#' Intended to regress shock-level covariates (merged at the sector level) on
#' the shocks to test the as-good-as-random assignment of shifts. Not yet
#' implemented in v0.1 because shock-level covariates are not part of the design
#' object; the scaffolding ([ssb_aggregate()] hook) is where this will live.
#'
#' @param design An [ssb_design()] object.
#' @param shock_covariates Optional `data.frame` keyed by `sector`.
#' @export
ssb_shock_balance <- function(design, shock_covariates = NULL) {
  message("ssb_shock_balance(): not yet implemented in v0.1 (needs shock-level ",
          "covariates keyed by sector).")
  invisible(NULL)
}
