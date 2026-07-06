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
#' @param design An [ssb_design()] object.
#'
#' @return A `data.frame` of class `ssb_rotemberg`, one row per sector-cell,
#'   with columns `sector`, `g` (shock), `alpha` (Rotemberg weight),
#'   `beta` (just-identified estimate), `F` (first-stage F of that instrument),
#'   and `sign`. Carries the overall estimate `beta_hat` as an attribute.
#'   Pass it to [ssb_plot_rotemberg()] for the canonical figure.
#' @export
ssb_rotemberg <- function(design) {
  stopifnot(inherits(design, "ssb_design"))
  d <- design
  w <- .ssb_w(d); C <- .ssb_C(d)
  S <- d$mat$S; g <- d$mat$g

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
  class(out) <- c("ssb_rotemberg", "data.frame")
  out
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
    cat(sprintf("  ! one shock carries |alpha| = %.2f; check robustness via ssb_drop_top()\n",
                abs(x$alpha[j])))
  cat(sprintf("  top %d sectors by |alpha|:\n", min(n, nrow(x))))
  show <- utils::head(x, n)[c("sector", "alpha", "beta", "F")]
  class(show) <- "data.frame"          # avoid dispatching to format.ssb_rotemberg
  print(format(show, digits = digits), row.names = FALSE)
  cat("  (negative weights are not by themselves a red flag; see GPSS 2020)\n")
  invisible(x)
}
