#' @keywords internal
#' @noRd
NULL

## ----- small internal helpers -------------------------------------------------

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
# Returns list(coef, var, fstat).
.ssb_uni_robust <- function(y, x, w) {
  sxx <- sum(w * x * x)
  b   <- sum(w * x * y) / sxx
  e   <- y - b * x
  n   <- length(y)
  meat <- sum((w * x)^2 * e^2)
  vr  <- meat / sxx^2
  vr  <- vr * n / max(n - 1, 1)          # HC1-style finite-sample scaling
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
