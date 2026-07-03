#' Simulate a shift-share (Bartik) design
#'
#' Generates a small, self-contained shift-share dataset in the long format
#' expected by [ssb_design()]: a unit-level table, a long shares table, and a
#' shocks table. Useful for examples, tests, and demonstrations.
#'
#' @param n_loc Number of locations (units).
#' @param n_sec Number of sectors/shocks.
#' @param beta True structural coefficient of `x` on `y`.
#' @param share_conc Dirichlet concentration for exposure shares (smaller = more
#'   concentrated exposure, i.e. fewer effective shocks).
#' @param endog Strength of the endogeneity (correlation between the treatment
#'   error and the outcome error).
#' @param incomplete If `TRUE`, shares deliberately do not sum to one within a
#'   location (an incomplete-shares design).
#' @param seed Optional RNG seed.
#'
#' @return A list with elements `data`, `shares`, `shocks`, and `beta`
#'   (the true coefficient), suitable for passing to [ssb_design()].
#' @keywords internal
ssb_simulate <- function(n_loc = 300, n_sec = 20, beta = 1.2,
                         share_conc = 0.5, endog = 0.6,
                         incomplete = FALSE, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  # Exposure shares: Dirichlet(share_conc) per location -> concentrated exposure.
  raw <- matrix(stats::rgamma(n_loc * n_sec, shape = share_conc), n_loc, n_sec)
  S   <- raw / rowSums(raw)
  if (incomplete) {                       # drop mass so shares sum to < 1
    keep <- matrix(stats::rbinom(n_loc * n_sec, 1, 0.85), n_loc, n_sec)
    S <- S * keep
  }

  g <- stats::rnorm(n_sec, 0, 1)          # sector shocks (shifts)

  z <- as.numeric(S %*% g)                # Bartik instrument

  # first stage + endogeneity
  u <- stats::rnorm(n_loc)                # outcome structural error
  v <- endog * u + sqrt(1 - endog^2) * stats::rnorm(n_loc)
  x <- 0.9 * z + v                        # endogenous treatment
  y <- beta * x + u                       # outcome

  loc <- seq_len(n_loc)
  sec <- seq_len(n_sec)

  data <- data.frame(
    location = loc,
    y = y, x = x,
    pop = stats::runif(n_loc, 0.5, 1.5),  # a plausible regression weight
    w1 = stats::rnorm(n_loc),             # an observable control / covariate
    stringsAsFactors = FALSE
  )

  shares <- data.frame(
    location = rep(loc, times = n_sec),
    sector   = rep(sec, each = n_loc),
    share    = as.numeric(S),
    stringsAsFactors = FALSE
  )
  shares <- shares[shares$share > 0, , drop = FALSE]

  shocks <- data.frame(sector = sec, shock = g, stringsAsFactors = FALSE)

  list(data = data, shares = shares, shocks = shocks, beta = beta)
}
