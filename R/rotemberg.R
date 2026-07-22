#' Rotemberg weights for a Bartik instrument
#'
#' Decomposes the shift-share 2SLS estimate into a weighted sum of the
#' just-identified estimates that use each sector's share as a single
#' instrument, following Goldsmith-Pinkham, Sorkin and Swift (2020):
#' \deqn{\hat\beta = \sum_n \hat\alpha_n \hat\beta_n,\qquad
#'       \hat\alpha_n = \frac{g_n\, \tilde s_n' \tilde x}{\sum_{n'} g_{n'}\,
#'       \tilde s_{n'}' \tilde x},}
#' where tildes denote residualisation on the controls (and, in panels,
#' sector-cells are sector \eqn{\times} period pairs). The weights
#' \eqn{\hat\alpha_n} sum to one and measure the sensitivity of \eqn{\hat\beta}
#' to misspecification of each sector's instrument; a small number of large
#' weights is a warning sign. Unlike Goodman-Bacon weights, negative Rotemberg
#' weights are not automatically problematic.
#'
#' **Normalisation.** When the exposure shares sum to one (or the sum of
#' shares is controlled, as it is automatically on the shift route), adding a
#' constant to every shock leaves the instrument --- and \eqn{\hat\beta} ---
#' unchanged but changes the individual weights: the decomposition is unique
#' only up to a normalisation of the shocks. Following Goldsmith-Pinkham,
#' Sorkin & Swift and Borusyak-Hull-Jaravel, `demean = TRUE` (default)
#' resolves this by demeaning the shocks with exposure weights, **within
#' periods in a panel** (when the corresponding per-period constant directions
#' are absorbed by the controls). If the constant is *not* absorbed
#' (incomplete shares without a sum-of-shares control) the decomposition is
#' already pinned down by the raw shocks; demeaning would then change it, so
#' the raw shocks are kept, with a message. The just-identified estimates
#' \eqn{\hat\beta_n}, the first-stage Fs and \eqn{\hat\beta} itself are
#' unaffected by the normalisation --- only the weights are.
#'
#' @param design An [ssb_design()] object.
#' @param demean Normalise the shocks by (within-period, exposure-weighted)
#'   demeaning before computing the weights (default `TRUE`; see Details).
#'   `FALSE` reproduces the raw-shock formula.
#'
#' @return A `data.frame` of class `ssb_rotemberg`, one row per sector-cell,
#'   with columns `sector`, `g` (shock, after any demeaning), `alpha`
#'   (Rotemberg weight), `beta` (just-identified estimate), `F` (first-stage F
#'   of that instrument), and `sign`. Carries the overall estimate `beta_hat`
#'   and the normalisation used (`demeaned`) as attributes.
#'   Pass it to [ssb_plot_rotemberg()] for the canonical figure.
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
#' ssb_rotemberg(d)
#' @export
ssb_rotemberg <- function(design, demean = TRUE) {
  stopifnot(inherits(design, "ssb_design"))
  d <- design
  w <- .ssb_w(d); C <- .ssb_C(d)
  S <- d$mat$S; g <- d$mat$g

  norm_how <- "none (demean = FALSE)"
  if (isTRUE(demean)) {
    dm <- .ssb_demean_shocks(d)
    g <- dm$g; norm_how <- dm$how
  }

  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  ry <- .ssb_resid(d$data[[d$vars$y]], C, w)

  K <- ncol(S)
  sx <- numeric(K); sy <- numeric(K); Fk <- numeric(K)
  kp <- .ssb_np(C) + 1L                   # intercept + controls + share slope
  for (k in seq_len(K)) {
    sk <- .ssb_resid(S[, k], C, w)       # residualise the share itself (FWL)
    sx[k] <- .ssb_wip(sk, rx, w)
    sy[k] <- .ssb_wip(sk, ry, w)
    Fk[k] <- .ssb_uni_robust(rx, sk, w, p = kp)$fstat   # first stage: x on this share
  }

  num   <- g * sx                        # g_n * <s_n, x>
  alpha <- num / sum(num)
  beta  <- sy / sx
  beta_hat <- sum(num * beta) / sum(num) # == (sum g <s,y>) / (sum g <s,x>)

  out <- data.frame(
    sector = d$mat$cell_sector,
    g = as.numeric(g),
    alpha = alpha,
    beta = beta,
    F = Fk,
    sign = ifelse(alpha >= 0, "Positive", "Negative"),
    stringsAsFactors = FALSE
  )
  out <- out[order(-abs(out$alpha)), , drop = FALSE]
  rownames(out) <- NULL
  attr(out, "beta_hat") <- beta_hat
  attr(out, "max_alpha") <- out$alpha[which.max(abs(out$alpha))]
  attr(out, "demeaned") <- norm_how
  class(out) <- c("ssb_rotemberg", "data.frame")
  out
}

# Normalise the shocks for the Rotemberg decomposition (GPSS 2020; BHJ JEP).
# When the constant direction (the sum of shares; per-period sums in panels)
# is absorbed by the controls, adding a constant to every shock leaves the
# instrument and beta_hat unchanged but shifts the individual weights: the
# decomposition is unique only up to a normalisation. It is resolved by
# demeaning the shocks with exposure weights, within periods when the
# per-period directions are absorbed. When nothing is absorbed the weights
# already depend on the raw shock scale and demeaning would *change* the
# decomposition, so the raw shocks are kept (with a message).
.ssb_demean_shocks <- function(d) {
  g <- d$mat$g
  w <- .ssb_w(d); C <- .ssb_C(d)
  s_n <- as.numeric(colSums(w * d$mat$S))
  absorbed <- function(v) {
    r <- .ssb_resid(v, C, w)
    sqrt(sum(w * r^2)) <= 1e-6 * (1 + sqrt(sum(w * v^2)))
  }
  tt <- d$mat$cell_time
  if (!is.null(tt)) {
    per_cell <- factor(tt)
    per_loc  <- as.character(d$data[[d$vars$time]])
    dirs <- lapply(levels(per_cell), function(l)
      d$mat$share_sum * (per_loc == l))
    if (all(vapply(dirs, absorbed, logical(1)))) {
      idx  <- split(seq_along(g), per_cell)
      gbar <- vapply(idx, function(i) sum(s_n[i] * g[i]) / sum(s_n[i]),
                     numeric(1))
      return(list(g = g - gbar[as.character(per_cell)], how = "within-period"))
    }
  }
  if (absorbed(d$mat$share_sum)) {
    return(list(g = g - sum(s_n * g) / sum(s_n), how = "overall"))
  }
  message("ssb_rotemberg(): shocks were NOT demeaned -- the sum of exposure ",
          "shares is not absorbed by the controls, so the decomposition ",
          "already depends on the shock normalisation. Complete shares (or a ",
          "sum-of-shares control, automatic on the shift route) make the ",
          "weights normalisation-invariant.")
  list(g = g, how = "none")
}

#' @export
print.ssb_rotemberg <- function(x, n = 6,
                                format = c("console", "latex", "markdown"),
                                digits = 3, caption = NULL,
                                label = "tab:rotemberg", ...) {
  format <- match.arg(format)
  if (format != "console") {
    cat(.ssb_rot_text(x, output = format, n = n, digits = digits,
                      caption = caption, label = label), sep = "\n")
    return(invisible(x))
  }
  bh <- attr(x, "beta_hat")
  pos <- sum(x$alpha[x$alpha > 0]); neg <- sum(x$alpha[x$alpha < 0])
  cat("<ssBartik Rotemberg weights>\n")
  cat(sprintf("  overall beta_hat : %.4f\n", bh))
  cat(sprintf("  sum positive alpha : %.3f   sum negative alpha : %.3f\n", pos, neg))
  j <- which.max(abs(x$alpha))
  cat(sprintf("  largest weight   : alpha = %.3f (%s)\n", x$alpha[j], x$sector[j]))
  if (abs(x$alpha[j]) > 0.2)
    cat(sprintf("  ! one share instrument carries |alpha| = %.2f; check robustness via ssb_drop_top()\n",
                abs(x$alpha[j])))
  dm <- attr(x, "demeaned")
  if (!is.null(dm) && dm %in% c("within-period", "overall"))
    cat(sprintf("  shocks demeaned (%s, exposure-weighted) before weighting -- GPSS/BHJ normalisation\n",
                dm))
  cat(sprintf("  top %d sectors by |alpha|:\n", min(n, nrow(x))))
  show <- utils::head(x, n)[c("sector", "alpha", "beta", "F")]
  class(show) <- "data.frame"          # avoid dispatching to format.ssb_rotemberg
  print(format(show, digits = digits), row.names = FALSE)
  cat("  (negative weights are not by themselves a red flag; see GPSS 2020)\n")
  invisible(x)
}
