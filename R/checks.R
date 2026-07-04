#' Overidentification / cross-instrument homogeneity test
#'
#' Treats each sector's share as a separate instrument and tests whether the
#' just-identified estimates \eqn{\hat\beta_n} are mutually consistent, using a
#' precision-weighted Cochran's Q statistic
#' \eqn{Q=\sum_n (\hat\beta_n-\bar\beta)^2/\widehat{\mathrm{Var}}(\hat\beta_n)}
#' with \eqn{Q\sim\chi^2_{K-1}} under the null of a common coefficient.
#' Rejection points to a failure of shares/shocks exogeneity **or** to
#' treatment-effect heterogeneity across instruments (Goldsmith-Pinkham, Sorkin
#' & Swift 2020). Very weak instruments are down-weighted automatically; use
#' `min_F` to drop near-dead instruments entirely.
#'
#' @param design An [ssb_design()] object.
#' @param min_F Drop instruments whose own first-stage F is below this.
#' @return A list (class `ssb_overid`) with `Q`, `df`, `p`, `I2`, `beta_bar`,
#'   `n_instruments`, `n_dropped`.
#' @export
ssb_overid <- function(design, min_F = 0) {
  stopifnot(inherits(design, "ssb_design"))
  d <- design; w <- .ssb_w(d); C <- .ssb_C(d); S <- d$mat$S
  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  ry <- .ssb_resid(d$data[[d$vars$y]], C, w)
  K <- ncol(S); bk <- vk <- Fk <- numeric(K)
  for (k in seq_len(K)) {
    sk <- .ssb_resid(S[, k], C, w)
    sx <- .ssb_wip(sk, rx, w); sy <- .ssb_wip(sk, ry, w)
    bk[k] <- sy / sx
    ek <- ry - bk[k] * rx
    vk[k] <- sum((w * sk * ek)^2) / sx^2
    Fk[k] <- .ssb_uni_robust(rx, sk, w)$fstat
  }
  ok <- is.finite(bk) & is.finite(vk) & vk > 0 & Fk >= min_F
  bb <- bk[ok]; ww <- 1 / vk[ok]
  bbar <- sum(ww * bb) / sum(ww)
  Q  <- sum(ww * (bb - bbar)^2); df <- length(bb) - 1
  instruments <- data.frame(sector = design$mat$cell_sector[ok], beta = bb,
                            se = sqrt(vk[ok]), F = Fk[ok], stringsAsFactors = FALSE)
  structure(list(Q = Q, df = df, p = stats::pchisq(Q, df, lower.tail = FALSE),
                 I2 = max(0, (Q - df) / Q), beta_bar = bbar,
                 n_instruments = length(bb), n_dropped = sum(!ok),
                 n_weak = sum(Fk[ok] < 10), instruments = instruments),
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
#' @param methods Standard-error methods (see [ssb_estimate()]).
#' @param level Confidence level.
#' @return An `ssb_estimate` for the placebo outcome.
#' @export
ssb_placebo <- function(design, placebo_y,
                        methods = c("ehw", "cluster", "akm"), level = 0.95) {
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
#' `block`s), recomputes the shift-share estimate each time, and reports where
#' the observed estimate falls in this placebo distribution. The two-sided
#' randomization-inference p-value tests the sharp null that the shocks do not
#' affect the outcome, and is robust to the exposure structure (Borusyak & Hull;
#' Adao-Kolesar-Morales).
#'
#' @param design An [ssb_design()] object.
#' @param R Number of permutation draws.
#' @param block Optional exchangeability blocks for shocks: a column name in the
#'   shocks table, or a vector of length equal to the number of shock-cells.
#'   Shocks are permuted only within blocks.
#' @param null The null value of the coefficient (default 0).
#' @param seed Optional RNG seed.
#' @return A list (class `ssb_ri`) with `beta`, `p_value`, `R`, and the vector
#'   `perm` of placebo estimates.
#' @export
ssb_ri <- function(design, R = 999, block = NULL, null = 0, seed = NULL) {
  stopifnot(inherits(design, "ssb_design"))
  if (!is.null(seed)) set.seed(seed)
  d <- design; w <- .ssb_w(d); C <- .ssb_C(d); S <- d$mat$S; g <- d$mat$g
  ry <- .ssb_resid(d$data[[d$vars$y]], C, w)
  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  b_of <- function(gg) {
    rz <- .ssb_resid(as.numeric(S %*% gg), C, w)
    .ssb_wip(rz, ry, w) / .ssb_wip(rz, rx, w)
  }
  b_obs <- b_of(g)
  blk <- .ssb_block(design, block)
  ug <- unique(blk)
  perm <- vapply(seq_len(R), function(r) {
    gp <- g
    for (bb in ug) { idx <- which(blk == bb); gp[idx] <- g[idx][sample(length(idx))] }
    b_of(gp)
  }, numeric(1))
  p <- (1 + sum(abs(perm - null) >= abs(b_obs - null))) / (R + 1)
  structure(list(beta = b_obs, null = null, p_value = p, R = R, perm = perm),
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
#' @export
ssb_first_stage <- function(design) {
  stopifnot(inherits(design, "ssb_design"))
  d <- design; w <- .ssb_w(d); C <- .ssb_C(d)
  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  rz <- .ssb_resid(d$mat$z, C, w)
  std <- .ssb_uni_robust(rx, rz, w)
  zz <- .ssb_wip(rz, rz, w); pi <- .ssb_wip(rz, rx, w) / zz
  nu <- rx - pi * rz
  mn <- as.numeric(d$mat$g * colSums(w * d$mat$S * nu))   # per-shock scores
  var_eff <- sum(mn^2) / zz^2
  structure(list(F_standard = std$fstat, F_effective = pi^2 / var_eff,
                 pi = pi), class = "ssb_first_stage")
}

#' Re-estimate after dropping the top-weight shocks
#'
#' Removes the `n` shocks with the largest absolute Rotemberg weight *together*
#' and re-estimates, to see whether the headline result survives without the
#' most influential shocks. (Contrast [ssb_loo()], which drops one at a time.)
#'
#' @param design An [ssb_design()] object.
#' @param n Number of top-weight shocks to drop.
#' @param methods Standard-error methods for the comparison.
#' @return A list (class `ssb_drop_top`) with the `dropped` sectors and the
#'   `full` and `reduced` [ssb_estimate()] tables.
#' @export
ssb_drop_top <- function(design, n = 5,
                         methods = c("iid", "ehw", "cluster", "akm", "akm0")) {
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
#' Sorkin & Swift (2020): the top-weight shocks, the largest single weight, the
#' correlation of the weights with the just-identified estimates and first-stage
#' F, and --- if `covariates` are supplied --- the correlation between each
#' shock's Rotemberg weight and its exposure-weighted average of unit
#' observables (do high-weight shocks load on systematically different places?).
#'
#' @param design An [ssb_design()] object.
#' @param covariates Optional unit-level observable columns in `data`.
#' @param top Number of top-weight shocks to display.
#' @return A list (class `ssb_weight_summary`).
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
  cat("<ssBartik overidentification test (cross-instrument homogeneity)>\n")
  cat(sprintf("  Q = %.2f on %d df,  p = %.4f\n", x$Q, x$df, x$p))
  cat(sprintf("  I^2 = %.1f%%   precision-weighted mean beta = %.4f\n",
              100 * x$I2, x$beta_bar))
  cat(sprintf("  instruments used: %d (dropped %d; %d weak, F<10)\n",
              x$n_instruments, x$n_dropped, x$n_weak))
  cat("  small p => reject a common coefficient (exogeneity failure OR heterogeneity)\n")
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
  cat(sprintf("  observed beta : %.4f   (null %.3f)\n", x$beta, x$null))
  cat(sprintf("  RI p-value    : %.4f   (%d permutations)\n", x$p_value, x$R))
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
  cat("  top shocks by |alpha|:\n")
  print(format(x$top, digits = 3), row.names = FALSE)
  invisible(x)
}
