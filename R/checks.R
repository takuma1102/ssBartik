#' Overidentification test across the share instruments (Sargan-Hansen)
#'
#' Treats each sector's exposure share as a separate instrument --- the
#' exogenous-shares reading of a Bartik design (Goldsmith-Pinkham, Sorkin &
#' Swift 2020) --- estimates the corresponding overidentified IV, and reports
#' the Sargan-Hansen J test of the overidentifying restrictions. Rejection
#' points to a failure of shares exogeneity for some sectors **or** to
#' treatment-effect heterogeneity across instruments. This is a share-route
#' diagnostic; [ssb_pipeline()] runs it there.
#'
#' The J statistic comes from efficient two-step GMM with a
#' heteroskedasticity-robust weight matrix (cluster-robust when the design has
#' a `cluster` variable), so it accounts for the fact that the just-identified
#' estimates are estimated on the *same* sample and are mutually correlated.
#' Earlier versions reported a precision-weighted Cochran Q, which is only
#' valid when those estimates are independent; it has been replaced.
#'
#' Following the Borusyak-Hull-Jaravel JEP practical guide, several estimators
#' of the common coefficient are available: `"2sls"` and efficient two-step
#' `"gmm"` are natural when the number of instruments \eqn{K} is modest, while
#' `"liml"` and `"jive"` (JIVE1) guard against many-instrument bias when
#' \eqn{K} is large relative to the sample. `estimator = "auto"` (default)
#' picks 2SLS when \eqn{K \le \max(3, 0.05\,n)} and LIML otherwise, with a
#' message. When the shares sum to one (or the sum of shares is controlled)
#' the residualised share instruments are exactly collinear; redundant columns
#' are dropped automatically, so a complete-shares design with \eqn{K} sectors
#' uses \eqn{K-1} instruments and the test has \eqn{K-2} degrees of freedom,
#' matching the usual leave-one-share-out formulation.
#'
#' @param design An [ssb_design()] object.
#' @param estimator `"auto"` (default), `"2sls"`, `"gmm"`, `"liml"`, or
#'   `"jive"`. See Details.
#' @param min_F Drop instruments whose own first-stage F is below this before
#'   estimating and testing.
#' @param level Confidence level for the reported interval.
#' @return A list (class `ssb_overid`) with the chosen `estimator`, its `beta`,
#'   `se`, `conf.low`/`conf.high`, the Hansen `J` statistic, `df`, `p`, the
#'   number of instruments used `K` (plus `n_dropped`, `n_collinear`,
#'   `n_weak`), and the per-instrument table `instruments` of just-identified
#'   estimates for [ssb_plot_overid()].
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
#' ssb_overid(d, estimator = "2sls")
#' @export
ssb_overid <- function(design,
                       estimator = c("auto", "2sls", "gmm", "liml", "jive"),
                       min_F = 0, level = 0.95) {
  stopifnot(inherits(design, "ssb_design"))
  estimator <- match.arg(estimator)
  d <- design; w <- .ssb_w(d); C <- .ssb_C(d); S <- d$mat$S
  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  ry <- .ssb_resid(d$data[[d$vars$y]], C, w)
  n  <- length(rx)
  cl <- if (is.null(d$vars$cluster)) NULL else d$data[[d$vars$cluster]]

  # residualise every share instrument (FWL); keep the just-identified
  # estimates for the dispersion diagnostics / plot
  K <- ncol(S); bk <- vk <- Fk <- numeric(K)
  kp <- .ssb_np(C) + 1L                   # intercept + controls + slope
  Zt <- matrix(0, n, K)
  for (k in seq_len(K)) {
    sk <- .ssb_resid(S[, k], C, w)
    Zt[, k] <- sk
    sx <- .ssb_wip(sk, rx, w); sy <- .ssb_wip(sk, ry, w)
    bk[k] <- sy / sx
    ek <- ry - bk[k] * rx
    vk[k] <- sum((w * sk * ek)^2) / sx^2
    Fk[k] <- .ssb_uni_robust(rx, sk, w, p = kp)$fstat
  }
  ok <- is.finite(bk) & is.finite(vk) & vk > 0 & Fk >= min_F
  instruments <- data.frame(sector = d$mat$cell_sector[ok], beta = bk[ok],
                            se = sqrt(vk[ok]), F = Fk[ok],
                            stringsAsFactors = FALSE)

  # with complete shares (or a controlled share sum) the residualised shares
  # sum to zero, so one column is redundant: prune to a full-rank instrument set
  use  <- which(ok)
  keep <- .ssb_indep_cols(sqrt(w) * Zt[, use, drop = FALSE])
  n_collinear <- length(use) - length(keep)
  use  <- use[keep]
  Kz   <- length(use)
  if (Kz < 2L)
    stop("the overidentification test needs at least two linearly ",
         "independent share instruments (after `min_F` screening).")
  Z <- Zt[, use, drop = FALSE]

  if (estimator == "auto") {
    estimator <- if (Kz <= max(3L, ceiling(0.05 * n))) "2sls" else "liml"
    message("ssb_overid(): estimator = 'auto' resolved to '", estimator,
            "' (K = ", Kz, " instruments, n = ", n, "; see ?ssb_overid).")
  }

  A    <- crossprod(Z, w * Z)
  Ai   <- solve(A)
  Zx   <- crossprod(Z, w * rx); Zy <- crossprod(Z, w * ry)
  proj <- function(v) as.numeric(Z %*% (Ai %*% crossprod(Z, w * v)))
  omega <- function(e) {                  # robust / clustered moment variance
    U <- Z * (w * e)
    if (is.null(cl)) crossprod(U) else crossprod(rowsum(U, cl))
  }

  b_2sls <- as.numeric(crossprod(Zx, Ai %*% Zy) / crossprod(Zx, Ai %*% Zx))

  # Hansen J from efficient two-step GMM (weight matrix at the 2SLS residuals)
  gmmfit <- tryCatch({
    Oi <- solve(omega(ry - b_2sls * rx))
    b  <- as.numeric(crossprod(Zx, Oi %*% Zy) / crossprod(Zx, Oi %*% Zx))
    gb <- crossprod(Z, w * (ry - b * rx))
    list(beta = b, J = as.numeric(crossprod(gb, Oi %*% gb)),
         a = as.numeric(Z %*% (Oi %*% Zx)))
  }, error = function(e) NULL)
  J  <- if (is.null(gmmfit)) NA_real_ else gmmfit$J
  df <- Kz - 1L
  pJ <- if (is.na(J)) NA_real_ else stats::pchisq(J, df, lower.tail = FALSE)
  if (is.null(gmmfit) && estimator == "gmm") {
    warning("the efficient-GMM weight matrix is singular (too many ",
            "instruments relative to observations/clusters); falling back ",
            "to 2SLS.", call. = FALSE)
    estimator <- "2sls"
  }

  kappa <- NA_real_
  eff <- switch(estimator,
    "2sls" = list(beta = b_2sls, a = proj(rx)),
    "gmm"  = list(beta = gmmfit$beta, a = gmmfit$a),
    "liml" = {
      # k-class with kappa = smallest eigenvalue of (Y'MY)^{-1} Y'Y, all
      # exogenous variables already partialled out; weighted inner products
      Yw  <- cbind(ry, rx)
      PY  <- cbind(proj(ry), proj(rx))
      YY  <- crossprod(Yw, w * Yw)
      YMY <- YY - crossprod(Yw, w * PY)
      kappa <- min(Re(eigen(solve(YMY, YY), only.values = TRUE)$values))
      a <- (1 - kappa) * rx + kappa * proj(rx)
      list(beta = sum(w * a * ry) / sum(w * a * rx), a = a)
    },
    "jive" = {
      # JIVE1: leave-one-out first-stage fitted values via the hat diagonal
      h  <- rowSums((Z %*% Ai) * (w * Z))
      xh <- proj(rx)
      a  <- (xh - h * rx) / pmax(1 - h, .Machine$double.eps)
      list(beta = sum(w * a * ry) / sum(w * a * rx), a = a)
    })

  e_hat <- ry - eff$beta * rx
  momv  <- w * eff$a * e_hat
  den   <- sum(w * eff$a * rx)
  meat  <- if (is.null(cl)) sum(momv^2) * n / max(n - kp, 1)
           else .ssb_cluster_meat(momv, cl)
  se <- sqrt(meat) / abs(den)
  qq <- stats::qnorm(1 - (1 - level) / 2)

  structure(list(estimator = estimator, beta = eff$beta, se = se,
                 conf.low = eff$beta - qq * se, conf.high = eff$beta + qq * se,
                 J = J, df = df, p = pJ,
                 K = Kz, n_dropped = sum(!ok), n_collinear = n_collinear,
                 n_weak = sum(Fk[ok] < 10), kappa = kappa,
                 clustered = !is.null(cl),
                 instruments = instruments),
            class = "ssb_overid")
}

#' Placebo-outcome test
#'
#' Runs the *same* shift-share IV but on an outcome that the treatment should
#' not move (a placebo). A coefficient far from zero signals that the design is
#' picking up something other than the intended channel. This is distinct from
#' [ssb_pretrend()], which regresses a *pre-period* outcome on the instrument
#' (reduced form) to look for differential pre-trends.
#'
#' @param design An [ssb_design()] object.
#' @param placebo_y Column name of the placebo outcome in `data`.
#' @param methods Standard-error methods (see [ssb_estimate()]); `NULL`
#'   (default) uses the route-appropriate methods.
#' @param level Confidence level.
#' @return An `ssb_estimate` for the placebo outcome.
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' sim$data$y_placebo <- stats::rnorm(nrow(sim$data))   # an unrelated outcome
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
#' ssb_placebo(d, placebo_y = "y_placebo")
#' @export
ssb_placebo <- function(design, placebo_y, methods = NULL, level = 0.95) {
  stopifnot(inherits(design, "ssb_design"))
  if (!placebo_y %in% names(design$data))
    stop("`placebo_y` not found in data: ", placebo_y)
  d2 <- design; d2$vars$y <- placebo_y
  est <- ssb_estimate(d2, methods = methods, level = level)
  attr(est, "placebo") <- placebo_y
  est
}

#' Randomization-inference (placebo-shock) test
#'
#' Re-draws the shocks by permutation (optionally within exchangeability
#' `block`s) and reports where the observed statistic falls in the resulting
#' placebo distribution, in the spirit of Adao-Kolesar-Morales (2019) and
#' Borusyak & Hull.
#'
#' The statistic is Anderson-Rubin-style: the reduced-form coefficient of
#' \eqn{y - \beta_0 x} on the reconstructed instrument, with
#' \eqn{\beta_0 =} `null`. Under the constant-effects null \eqn{\beta = \beta_0}
#' (plus the exclusion restriction), \eqn{y - \beta_0 x} does not respond to how
#' the shocks are assigned, so the permutation distribution of this statistic is
#' *exact* given the exchangeability encoded in `block`. Permuting the IV ratio
#' itself (holding the observed treatment fixed) would *not* be exact --- the
#' treatment also responds to the shocks through the first stage, and placebo
#' draws with weak first stages give the ratio very heavy tails --- so this
#' function does not do that.
#'
#' **The exchangeability assumption is stronger than shocks being
#' as-good-as-random.** Permutation validity requires the shocks (within a
#' `block`) to be *exchangeable* --- in particular, identically distributed up
#' to reordering. The Borusyak-Hull-Jaravel framework only assumes shocks are
#' as-good-as-randomly assigned (mean-independent of the unobservables), which
#' allows their variances and higher moments to differ across cells; under
#' that weaker assumption randomization inference can over- or under-reject.
#' Use `block` to group shocks that are plausibly comparable draws (and to
#' keep permutations within periods in panels), and treat the RI p-value as a
#' complement to --- not a substitute for --- the exposure-robust inference in
#' [ssb_estimate()] / [ssb_shock_iv()].
#'
#' @param design An [ssb_design()] object.
#' @param R Number of permutation draws.
#' @param block Optional exchangeability blocks for shocks: a column name in the
#'   shocks table, or a vector of length equal to the number of shock-cells.
#'   Shocks are permuted only within blocks. In sector x period panels you
#'   almost always want blocks that separate periods, so shocks are not permuted
#'   across time.
#' @param null The null value \eqn{\beta_0} of the coefficient (default 0).
#' @param seed Optional RNG seed.
#' @return A list (class `ssb_ri`) with the IV point estimate `beta`, the
#'   observed Anderson-Rubin `statistic`, `null`, `p_value`, `R`, and the vector
#'   `perm` of placebo statistics.
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
#' ssb_ri(d, R = 199, seed = 1)
#' @export
ssb_ri <- function(design, R = 999, block = NULL, null = 0, seed = NULL) {
  stopifnot(inherits(design, "ssb_design"))
  if (!is.null(seed)) set.seed(seed)
  d <- design; w <- .ssb_w(d); C <- .ssb_C(d); S <- d$mat$S; g <- d$mat$g
  ry <- .ssb_resid(d$data[[d$vars$y]], C, w)
  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  rz0  <- .ssb_resid(d$mat$z, C, w)
  b_iv <- .ssb_wip(rz0, ry, w) / .ssb_wip(rz0, rx, w)
  ynull <- ry - null * rx                # fixed under H0: beta = null
  t_of <- function(gg) {
    rz <- .ssb_resid(as.numeric(S %*% gg), C, w)
    .ssb_wip(rz, ynull, w) / .ssb_wip(rz, rz, w)
  }
  t_obs <- t_of(g)
  blk <- .ssb_block(design, block)
  ug <- unique(blk)
  perm <- vapply(seq_len(R), function(r) {
    gp <- g
    for (bb in ug) { idx <- which(blk == bb); gp[idx] <- g[idx][sample(length(idx))] }
    t_of(gp)
  }, numeric(1))
  p <- (1 + sum(abs(perm) >= abs(t_obs))) / (R + 1)   # centered at 0 under H0
  structure(list(beta = b_iv, statistic = t_obs, null = null,
                 p_value = p, R = R, perm = perm),
            class = "ssb_ri")
}

# resolve a `block` argument to a per-cell vector
.ssb_block <- function(design, block) {
  g <- design$mat$g
  if (is.null(block)) return(rep(1L, length(g)))
  if (length(block) == 1L && block %in% names(design$shocks))
    return(design$shocks[[block]])
  if (length(block) != length(g))
    stop("`block` must be a shocks-table column or a vector of length ", length(g))
  block
}

#' First-stage strength: standard and exposure-robust (effective) F
#'
#' Reports the standard heteroskedasticity-robust first-stage F of the treatment
#' on the constructed instrument, and an exposure-robust "effective" F whose
#' denominator uses the shock-level (AKM-type) variance of the first-stage
#' coefficient --- the relevant notion when weak *shocks* are the concern (in
#' the spirit of Montiel Olea & Pflueger 2013, adapted to shift-share).
#'
#' @param design An [ssb_design()] object.
#' @return A list (class `ssb_first_stage`) with `F_standard`, `F_effective`,
#'   and the first-stage coefficient `pi`.
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
#' ssb_first_stage(d)
#' @export
ssb_first_stage <- function(design) {
  stopifnot(inherits(design, "ssb_design"))
  d <- design; w <- .ssb_w(d); C <- .ssb_C(d)
  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  rz <- .ssb_resid(d$mat$z, C, w)
  std <- .ssb_uni_robust(rx, rz, w, p = .ssb_np(C) + 1L)
  zz <- .ssb_wip(rz, rz, w); pi <- .ssb_wip(rz, rx, w) / zz
  nu <- rx - pi * rz
  # per-shock scores use the shocks residualised on the shock-level controls
  # (constant + period FE) with exposure weights, not the raw g_n: the raw
  # version mis-states the exposure-robust variance (see ssb_shock_iv())
  s_n <- as.numeric(colSums(w * d$mat$S))
  gt  <- .ssb_resid(d$mat$g, .ssb_shock_C(d), s_n)
  mn  <- as.numeric(gt * colSums(w * d$mat$S * nu))
  var_eff <- sum(mn^2) / zz^2
  structure(list(F_standard = std$fstat, F_effective = pi^2 / var_eff,
                 pi = pi), class = "ssb_first_stage")
}

#' Re-estimate after dropping the top-weight sectors
#'
#' Removes the `n` sector-cells with the largest absolute Rotemberg weight
#' *together* and re-estimates, to see whether the headline result survives
#' without the most influential share instruments. (Contrast [ssb_loo()],
#' which drops one at a time.)
#'
#' @param design An [ssb_design()] object.
#' @param n Number of top-weight sectors to drop.
#' @param methods Inference methods for the comparison, passed to
#'   [ssb_estimate()]. `NULL` (default) uses the route-appropriate methods of
#'   [ssb_estimate()].
#' @return A list (class `ssb_drop_top`) with the `dropped` sectors and the
#'   `full` and `reduced` [ssb_estimate()] tables.
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
#' ssb_drop_top(d, n = 3)
#' @export
ssb_drop_top <- function(design, n = 5, methods = NULL) {
  stopifnot(inherits(design, "ssb_design"))
  rot <- ssb_rotemberg(design)
  dropped <- utils::head(rot$sector, n)
  d2 <- .ssb_subset(design, !(design$mat$cell_sector %in% dropped))
  structure(list(dropped = dropped, n = n,
                 full = ssb_estimate(design, methods = methods),
                 reduced = ssb_estimate(d2, methods = methods)),
            class = "ssb_drop_top")
}

#' Rotemberg-weight summary and correlations (GPSS diagnostic table)
#'
#' Summarises the Rotemberg-weight diagnostic in the spirit of Goldsmith-Pinkham,
#' Sorkin & Swift (2020): the top-weight share instruments, the largest single
#' weight, the correlation of the weights with the just-identified estimates
#' and first-stage F, and --- if `covariates` are supplied --- the correlation
#' between each share instrument's Rotemberg weight and its exposure-weighted
#' average of unit observables (do the high-weight share instruments load on
#' systematically different places?).
#'
#' @param design An [ssb_design()] object.
#' @param covariates Optional unit-level observable columns in `data`.
#' @param top Number of top-weight share instruments to display.
#' @return A list (class `ssb_weight_summary`).
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
#' ssb_weight_summary(d, covariates = "w1")
#' @export
ssb_weight_summary <- function(design, covariates = NULL, top = 5) {
  stopifnot(inherits(design, "ssb_design"))
  rot <- ssb_rotemberg(design)
  cors <- c(alpha_vs_beta = suppressWarnings(stats::cor(rot$alpha, rot$beta)),
            alpha_vs_F    = suppressWarnings(stats::cor(rot$alpha, rot$F)))
  cov_cor <- NULL
  if (!is.null(covariates)) {
    d <- design; w <- .ssb_w(d); S <- d$mat$S; s_n <- colSums(w * S)
    cbar <- vapply(covariates,
                   function(cv) as.numeric(colSums(w * S * d$data[[cv]]) / s_n),
                   numeric(ncol(S)))
    idx <- match(rot$sector, d$mat$cell_sector)
    cbar <- cbar[idx, , drop = FALSE]
    cov_cor <- vapply(seq_along(covariates),
                      function(j) suppressWarnings(stats::cor(rot$alpha, cbar[, j])),
                      numeric(1))
    names(cov_cor) <- covariates
  }
  top_tab <- utils::head(rot[c("sector", "alpha", "beta", "F", "g")], top)
  class(top_tab) <- "data.frame"       # plain df: don't dispatch to format.ssb_rotemberg
  structure(list(top = top_tab,
                 max_alpha = rot$alpha[1], max_sector = rot$sector[1],
                 cor = cors, cov_cor = cov_cor), class = "ssb_weight_summary")
}

## ---- print methods -----------------------------------------------------------

#' @export
print.ssb_overid <- function(x, ...) {
  cat("<ssBartik overidentification test (Sargan-Hansen)>\n")
  cat(sprintf("  estimator : %s over %d share instruments%s\n",
              toupper(x$estimator), x$K,
              if (isTRUE(x$n_collinear > 0))
                sprintf(" (%d collinear dropped)", x$n_collinear) else ""))
  cat(sprintf("  beta = %.4f   se = %.4f   [%.3f, %.3f]\n",
              x$beta, x$se, x$conf.low, x$conf.high))
  if (is.na(x$J)) {
    cat("  Hansen J unavailable: robust weight matrix is singular\n")
    cat("  (too many instruments relative to observations/clusters)\n")
  } else {
    cat(sprintf("  Hansen J = %.2f on %d df,  p = %.4f%s\n", x$J, x$df, x$p,
                if (isTRUE(x$clustered)) "  (cluster-robust)" else ""))
  }
  cat(sprintf("  instruments dropped: %d (min_F / degenerate); weak (F<10): %d\n",
              x$n_dropped, x$n_weak))
  cat("  small p => reject joint validity of the share instruments\n")
  cat("  (exclusion failure for some shares OR treatment-effect heterogeneity)\n")
  invisible(x)
}

#' @export
print.ssb_first_stage <- function(x, ...) {
  cat("<ssBartik first-stage strength>\n")
  cat(sprintf("  standard robust F         : %.1f\n", x$F_standard))
  cat(sprintf("  effective (exposure) F    : %.1f\n", x$F_effective))
  invisible(x)
}

#' @export
print.ssb_ri <- function(x, ...) {
  cat("<ssBartik randomization inference>\n")
  cat(sprintf("  IV estimate   : %.4f   (H0: beta = %.3f)\n", x$beta, x$null))
  cat(sprintf("  AR statistic  : %.4f   (reduced form of y - beta0*x on the instrument)\n",
              x$statistic))
  cat(sprintf("  RI p-value    : %.4f   (%d permutations)\n", x$p_value, x$R))
  cat("  note: valid if shocks are EXCHANGEABLE (within blocks) -- stronger than\n")
  cat("        the as-good-as-random assumption of Borusyak-Hull-Jaravel, which\n")
  cat("        allows shock variances to differ; see ?ssb_ri\n")
  invisible(x)
}

#' @export
print.ssb_drop_top <- function(x, ...) {
  cat(sprintf("<ssBartik drop-top-%d>\n", x$n))
  cat("  dropped:", paste(utils::head(x$dropped, 8), collapse = ", "), "\n")
  cmp <- data.frame(method = .ssb_se_label(x$full$method),
                    full = x$full$estimate, reduced = x$reduced$estimate)
  print(format(cmp, digits = 3), row.names = FALSE)
  invisible(x)
}

#' @export
print.ssb_weight_summary <- function(x, ...) {
  cat("<ssBartik Rotemberg-weight summary>\n")
  cat(sprintf("  largest weight: alpha = %.3f (%s)\n", x$max_alpha, x$max_sector))
  cat(sprintf("  cor(alpha, beta_k) = %.2f   cor(alpha, F) = %.2f\n",
              x$cor[["alpha_vs_beta"]], x$cor[["alpha_vs_F"]]))
  if (!is.null(x$cov_cor)) {
    cat("  cor(alpha, exposure-weighted covariate):\n")
    for (nm in names(x$cov_cor)) cat(sprintf("    %-16s % .2f\n", nm, x$cov_cor[[nm]]))
  }
  cat("  top share instruments by |alpha|:\n")
  print(format(x$top, digits = 3), row.names = FALSE)
  invisible(x)
}
