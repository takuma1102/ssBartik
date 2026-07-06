#' Run the full shift-share analysis pipeline
#'
#' Given a design, runs the estimation and the route-appropriate battery of
#' diagnostics in one call, dispatching on `design$exogenous`:
#' \itemize{
#'   \item **share** (Goldsmith-Pinkham, Sorkin & Swift 2020): Rotemberg-weight
#'         decomposition, leave-one-out sensitivity, and --- if `covariates` are
#'         supplied --- a share-balance check; a pre-trend check if `pre_y` is
#'         supplied.
#'   \item **shift** (Borusyak, Hull & Jaravel 2022): effective-shock /
#'         exposure-concentration summary, leave-one-out sensitivity, and the
#'         shock-balance hook.
#' }
#' Estimation always reports the full SE panel (naive / EHW / cluster /
#' AKM / AKM0). The point estimate and first-stage F are common to both routes.
#'
#' @param design An [ssb_design()] object.
#' @param covariates Optional observables for the share-balance check (share
#'   route).
#' @param pre_y Optional pre-period outcome for [ssb_pretrend()].
#' @param placebo_y Optional placebo outcome for [ssb_placebo()].
#' @param shock_covariates Optional shock-level characteristics (a data.frame
#'   keyed by sector) for [ssb_shock_balance()] on the shift route.
#' @param top Number of top-weight sectors for the sensitivity diagnostics.
#' @param level Confidence level.
#' @return An `ssb_result` list with `estimate`, `route`, and route-specific
#'   diagnostic elements. `autoplot()` returns the headline figure.
#' @export
ssb_pipeline <- function(design, covariates = NULL, pre_y = NULL,
                         placebo_y = NULL, shock_covariates = NULL,
                         top = 5, level = 0.95) {
  stopifnot(inherits(design, "ssb_design"))
  res <- list(route = design$exogenous, design = design)

  res$estimate    <- ssb_estimate(design, level = level)
  res$first_stage <- ssb_first_stage(design)
  res$equivalence <- ssb_equivalence(design)
  res$overid      <- tryCatch(ssb_overid(design), error = function(e) NULL)
  res$loo         <- ssb_loo(design, top = top)

  if (design$exogenous == "share") {
    res$rotemberg      <- ssb_rotemberg(design)
    res$weight_summary <- ssb_weight_summary(design, covariates = covariates, top = top)
    if (!is.null(covariates))
      res$share_balance <- ssb_share_balance(design, covariates, top = top)
  } else {
    res$shocks <- ssb_shock_summary(design)
    if (!is.null(shock_covariates))
      res$shock_balance <- ssb_shock_balance(design, shock_covariates)
  }
  if (!is.null(pre_y))     res$pretrend <- ssb_pretrend(design, pre_y)
  if (!is.null(placebo_y)) res$placebo  <- ssb_placebo(design, placebo_y)

  class(res) <- "ssb_result"
  res
}

#' One-call shift-share analysis
#'
#' Convenience wrapper that builds an [ssb_design()] from raw pieces and runs
#' [ssb_pipeline()] --- the "give me everything" entry point. Specify the
#' identification route with `exogenous` and the rest flows through to
#' diagnostics and plots.
#'
#' @inheritParams ssb_design
#' @param covariates,pre_y,placebo_y,shock_covariates,top,level Passed to
#'   [ssb_pipeline()].
#' @return An `ssb_result` object.
#' @export
#' @examples
#' # Bring your own data; this is a small synthetic design for illustration.
#' set.seed(1)
#' n_loc <- 60L; n_sec <- 8L
#' shares <- expand.grid(location = seq_len(n_loc), sector = seq_len(n_sec))
#' shares$share <- stats::runif(nrow(shares))
#' tot <- tapply(shares$share, shares$location, sum)
#' shares$share <- shares$share / tot[as.character(shares$location)]
#' shocks <- data.frame(sector = seq_len(n_sec), shock = stats::rnorm(n_sec))
#' Z <- tapply(shares$share, list(shares$location, shares$sector), sum)
#' Z[is.na(Z)] <- 0
#' inst <- as.numeric(Z %*% shocks$shock)
#' dat <- data.frame(location = seq_len(n_loc),
#'                   x = 4 * inst + stats::rnorm(n_loc, sd = 0.3))
#' dat$y <- 1.2 * dat$x + stats::rnorm(n_loc, sd = 0.3)
#' res <- ssbartik(dat, shares, shocks, exogenous = "share")
#' res
#' \dontrun{
#' autoplot(res)                       # headline Rotemberg figure
#' autoplot(res$estimate)              # SE comparison
#' }
ssbartik <- function(data, shares, shocks,
                     y = "y", x = "x",
                     location = "location", sector = "sector",
                     time = NULL, controls = NULL,
                     weights = NULL, cluster = NULL,
                     share_col = "share", shock_col = "shock",
                     exogenous = c("shift", "share"),
                     covariates = NULL, pre_y = NULL, placebo_y = NULL,
                     shock_covariates = NULL, top = 5, level = 0.95) {
  d <- ssb_design(data, shares, shocks, y = y, x = x,
                  location = location, sector = sector, time = time,
                  controls = controls, weights = weights, cluster = cluster,
                  share_col = share_col, shock_col = shock_col,
                  exogenous = exogenous)
  ssb_pipeline(d, covariates = covariates, pre_y = pre_y, placebo_y = placebo_y,
               shock_covariates = shock_covariates, top = top, level = level)
}

#' @export
print.ssb_result <- function(x, ...) {
  cat("== ssBartik result ==============================================\n")
  cat(sprintf("route : exogenous %s\n\n", toupper(x$route)))
  print(x$estimate)
  if (!is.null(x$first_stage)) { cat("\n"); print(x$first_stage) }
  if (!is.null(x$equivalence)) { cat("\n"); print(x$equivalence) }
  if (!is.null(x$overid))      { cat("\n"); print(x$overid) }
  if (!is.null(x$rotemberg))   { cat("\n"); print(x$rotemberg, n = 5) }
  if (!is.null(x$weight_summary)) { cat("\n"); print(x$weight_summary) }
  if (!is.null(x$shocks))      { cat("\n"); print(x$shocks) }
  if (!is.null(x$share_balance)) {
    cat("\n[share balance] (coef, robust t) of covariates on top shares\n")
    print(format(x$share_balance, digits = 3), row.names = FALSE)
  }
  if (!is.null(x$shock_balance)) { cat("\n"); print(x$shock_balance) }
  if (!is.null(x$pretrend))    { cat("\n"); print(x$pretrend) }
  if (!is.null(x$placebo)) {
    cat("\n[placebo outcome: ", attr(x$placebo, "placebo"), "]\n", sep = "")
    print(x$placebo)
  }
  cat("\n[leave-one-out] overall beta =",
      sprintf("%.4f", attr(x$loo, "beta_hat")), "\n")
  loo_tab <- x$loo; class(loo_tab) <- "data.frame"   # plain df: don't dispatch to format.ssb_loo
  print(format(loo_tab, digits = 3), row.names = FALSE)
  cat("=================================================================\n")
  invisible(x)
}

#' @export
summary.ssb_result <- function(object, ...) print(object, ...)

#' @method autoplot ssb_result
#' @export
autoplot.ssb_result <- function(object, ...) {
  if (!is.null(object$rotemberg)) return(ssb_plot_rotemberg(object$rotemberg, ...))
  ssb_plot_ci(object$estimate, ...)
}
