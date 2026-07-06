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
  class(out) <- c("ssb_loo", "data.frame")
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

#' Pre-trend test
#'
#' Reduced-form regression of a pre-period outcome on the constructed instrument
#' (controls partialled out). A coefficient far from zero indicates that
#' exposure predicts differential pre-trends --- a threat to identification.
#' This is distinct from [ssb_placebo()], which runs the *full IV* on a placebo
#' outcome; pre-trends ask whether exposure predicts the outcome *before* the
#' shocks, placebo asks whether the design moves an outcome it should not.
#'
#' @param design An [ssb_design()] object.
#' @param pre_y Column name of the pre-period outcome (or pre-period change).
#' @param level Confidence level.
#' @return A list (class `ssb_pretrend`) with the reduced-form coefficient and
#'   EHW / cluster standard errors.
#' @export
ssb_pretrend <- function(design, pre_y, level = 0.95) {
  stopifnot(inherits(design, "ssb_design"))
  if (missing(pre_y) || is.null(pre_y) || !pre_y %in% names(design$data))
    stop("supply `pre_y`, a pre-period outcome column in the data.")
  d <- design; w <- .ssb_w(d); C <- .ssb_C(d)
  rp <- .ssb_resid(d$data[[pre_y]], C, w)
  rz <- .ssb_resid(d$mat$z, C, w)
  zz <- .ssb_wip(rz, rz, w)
  b  <- .ssb_wip(rz, rp, w) / zz
  e  <- rp - b * rz
  gmom <- w * rz * e
  n <- length(rp)
  k <- .ssb_np(C) + 1L                   # intercept + controls + reduced-form coef
  se_ehw <- sqrt(sum(gmom^2) * n / max(n - k, 1)) / zz
  cl <- if (is.null(d$vars$cluster)) NULL else d$data[[d$vars$cluster]]
  se_cl <- if (is.null(cl)) NA_real_ else sqrt(.ssb_cluster_meat(gmom, cl)) / zz
  q <- stats::qnorm(1 - (1 - level) / 2)
  structure(list(coef = b, se_ehw = se_ehw, se_cluster = se_cl,
                 p_ehw = 2 * stats::pnorm(-abs(b / se_ehw)),
                 conf.low = b - q * se_ehw, conf.high = b + q * se_ehw,
                 pre_y = pre_y), class = "ssb_pretrend")
}

#' @export
print.ssb_pretrend <- function(x, ...) {
  cat("<ssBartik pre-trend test (reduced form on instrument)>\n")
  cat(sprintf("  pre-period outcome : %s\n", x$pre_y))
  cat(sprintf("  coef %.4f   se(EHW) %.4f   se(cluster) %s   p(EHW) %.3f\n",
              x$coef, x$se_ehw,
              if (is.na(x$se_cluster)) "NA" else sprintf("%.4f", x$se_cluster),
              x$p_ehw))
  cat("  coefficient near 0 => no differential pre-trend by exposure\n")
  invisible(x)
}

#' Shock-level balance test
#'
#' Tests the identifying assumption of the shocks route --- that shocks are
#' as-good-as-randomly assigned --- by regressing the shocks on pre-determined
#' shock-level characteristics, weighted by exposure (Borusyak, Hull & Jaravel
#' 2022). Coefficients near zero and a non-significant joint test support shock
#' exogeneity.
#'
#' @param design An [ssb_design()] object.
#' @param shock_covariates A `data.frame` keyed by `sector` (and `time` for
#'   panels) holding the shock-level characteristics to test.
#' @param weight If `TRUE` (default) weight by exposure \eqn{s_n}; else unweighted.
#' @return A list (class `ssb_shock_balance`) with a coefficient table and the
#'   joint Wald test that the characteristics are unrelated to the shocks.
#' @export
ssb_shock_balance <- function(design, shock_covariates, weight = TRUE) {
  stopifnot(inherits(design, "ssb_design"))
  v <- design$vars; sh <- design$shocks
  keys <- if (is.null(v$time)) v$sector else c(v$sector, v$time)
  miss <- setdiff(keys, names(shock_covariates))
  if (length(miss)) stop("`shock_covariates` must contain: ",
                         paste(keys, collapse = ", "))
  covs <- setdiff(names(shock_covariates), c(keys, v$shock_col))
  if (!length(covs)) stop("no covariate columns found in `shock_covariates`.")

  key_of <- function(df) if (is.null(v$time)) as.character(df[[v$sector]])
                         else paste(df[[v$sector]], df[[v$time]], sep = "\r")
  idx <- match(key_of(sh), key_of(shock_covariates))
  if (anyNA(idx))
    stop(sum(is.na(idx)), " shock cell(s) have no matching row in ",
         "`shock_covariates`.")
  X   <- as.matrix(shock_covariates[idx, covs, drop = FALSE])
  g   <- sh[[v$shock_col]]
  wts <- if (weight) .ssb_exposure(design) else rep(1, length(g))

  fit <- .ssb_wls(g, cbind(1, X), wts)
  tab <- data.frame(covariate = covs, coef = fit$coef[-1], se = fit$se[-1],
                    t = fit$tstat[-1], p = 2 * stats::pnorm(-abs(fit$tstat[-1])),
                    stringsAsFactors = FALSE)
  rownames(tab) <- NULL
  structure(list(coefficients = tab, joint_wald = fit$wald,
                 joint_df = fit$wald_df, joint_p = fit$wald_p,
                 weighted = weight), class = "ssb_shock_balance")
}

#' @export
print.ssb_shock_balance <- function(x, ...) {
  cat("<ssBartik shock-level balance test>\n")
  cat(sprintf("  %s regression of shocks on characteristics\n",
              if (x$weighted) "exposure-weighted" else "unweighted"))
  print(format(x$coefficients, digits = 3), row.names = FALSE)
  cat(sprintf("  joint Wald = %.2f on %d df, p = %.4f\n",
              x$joint_wald, x$joint_df, x$joint_p))
  cat("  non-significant => shocks unrelated to observed characteristics\n")
  invisible(x)
}
