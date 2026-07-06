#' @keywords internal
#' @noRd
NULL

## ----- small internal helpers -------------------------------------------------

# Number of parameters partialled out by .ssb_resid: the intercept plus the
# columns of the control matrix `C` (0 controls -> 1 for the intercept alone).
# Used so that HC1/iid finite-sample corrections divide by n - k rather than
# n - 1, i.e. account for the degrees of freedom consumed by the controls.
.ssb_np <- function(C) 1L + if (is.null(C)) 0L else ncol(as.matrix(C))

# Weighted residualisation of a vector `v` on a control matrix `C` (no intercept
# column needed; one is added). `w` are regression weights. Returns residuals in
# the original scale (FWL partialling-out).
.ssb_resid <- function(v, C = NULL, w = NULL) {
  n <- length(v)
  if (is.null(w)) w <- rep(1, n)
  X <- if (is.null(C)) matrix(1, n, 1) else cbind(1, as.matrix(C))
  fit <- stats::lm.wfit(x = X, y = v, w = w)
  as.numeric(fit$residuals)
}

# Weighted inner product sum_i w_i a_i b_i.
.ssb_wip <- function(a, b, w) sum(w * a * b)

# Robust (HC1) variance of the slope in a *through-the-origin* weighted
# regression of `y` on the single regressor `x` (both typically residualised).
# `p` is the total number of estimated parameters (slope + any controls already
# partialled out of `x` and `y`); the finite-sample factor is n / (n - p).
# Returns list(coef, var, fstat).
.ssb_uni_robust <- function(y, x, w, p = 1L) {
  sxx <- sum(w * x * x)
  b   <- sum(w * x * y) / sxx
  e   <- y - b * x
  n   <- length(y)
  meat <- sum((w * x)^2 * e^2)
  vr  <- meat / sxx^2
  vr  <- vr * n / max(n - p, 1)          # HC1-style finite-sample scaling
  list(coef = b, var = vr, fstat = b^2 / vr)
}

# Cluster-robust "meat" for a moment g_i = w_i * z_i * e_i given a cluster id.
.ssb_cluster_meat <- function(g, cluster) {
  if (is.null(cluster)) return(sum(g^2))
  ug <- tapply(g, cluster, sum)
  G  <- length(ug)
  s  <- sum(ug^2)
  s * (G / max(G - 1, 1))               # small-sample G/(G-1)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# Weighted LS with (cluster-)robust vcov and a joint Wald test on the
# non-intercept coefficients. `X` must already include the intercept column.
.ssb_wls <- function(y, X, w, cluster = NULL, intercept_col = 1L) {
  X <- as.matrix(X)
  XtWXi <- solve(crossprod(X, w * X))
  b  <- as.numeric(XtWXi %*% crossprod(X, w * y))
  e  <- as.numeric(y - X %*% b)
  n  <- nrow(X); k <- ncol(X)
  if (is.null(cluster)) {
    meat <- crossprod(X, (w^2 * e^2) * X)
    adj  <- n / max(n - k, 1)
  } else {
    Ug   <- rowsum(X * (w * e), group = cluster)
    meat <- crossprod(Ug)
    G    <- nrow(Ug)
    adj  <- (G / max(G - 1, 1)) * ((n - 1) / max(n - k, 1))
  }
  V   <- XtWXi %*% meat %*% XtWXi * adj
  se  <- sqrt(diag(V))
  sel <- setdiff(seq_len(k), intercept_col)
  wald <- NA_real_; q <- length(sel); pW <- NA_real_
  if (q > 0) {
    bb <- b[sel]; Vv <- V[sel, sel, drop = FALSE]
    wald <- as.numeric(t(bb) %*% solve(Vv) %*% bb)
    pW   <- stats::pchisq(wald, q, lower.tail = FALSE)
  }
  list(coef = b, se = se, tstat = b / se, vcov = V,
       wald = wald, wald_df = q, wald_p = pW, resid = e)
}

# Return a copy of a design restricted to a subset of sector-cells (logical or
# integer `keep`), recomputing the instrument, share sums and completeness.
.ssb_subset <- function(design, keep) {
  d <- design
  S <- d$mat$S[, keep, drop = FALSE]; g <- d$mat$g[keep]
  d$mat$S <- S; d$mat$g <- g
  d$mat$z <- as.numeric(S %*% g)
  d$mat$share_sum <- rowSums(S)
  d$mat$cell_sector <- d$mat$cell_sector[keep]
  d$mat$complete <- isTRUE(all.equal(unname(d$mat$share_sum),
                                     rep(1, nrow(S)), tolerance = 1e-6))
  d
}

# exposure weight per shock-cell: s_n = sum_i w_i s_{in}
.ssb_exposure <- function(design) as.numeric(colSums(.ssb_w(design) * design$mat$S))
