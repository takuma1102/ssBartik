#' Define a shift-share (Bartik) IV design
#'
#' `ssb_design()` is the single entry point of the package. It takes the three
#' pieces of a shift-share design --- a unit-level table, a long table of
#' exposure shares, and a table of shocks (shifts) --- aligns them, and
#' constructs the Bartik instrument \eqn{z_i = \sum_n s_{in} g_n}. The resulting
#' object flows directly into diagnostics ([ssb_rotemberg()],
#' [ssb_shock_summary()], ...), estimation ([ssb_estimate()]) and plotting.
#'
#' The **instrument is constructed identically** whichever identification route
#' you take; the `exogenous` argument governs which *inference*, *diagnostics*
#' and *controls* are appropriate downstream (see [ssb_estimate()],
#' [ssb_pipeline()]). Set `exogenous = "share"` for the exogenous-shares route
#' (Goldsmith-Pinkham, Sorkin and Swift 2020; Rotemberg-weight diagnostics and
#' conventional inference) or `exogenous = "shift"` for the exogenous-shocks
#' route (Borusyak, Hull and Jaravel 2022; Adao, Kolesar and Morales 2019;
#' shock-level diagnostics and exposure-robust inference). Because the route is
#' an identification assumption, it **must be specified explicitly** -- there
#' is no default.
#'
#' On the shift route the package adds the Borusyak-Hull-Jaravel controls
#' automatically: with incomplete shares the per-unit **sum of exposure
#' shares**, and in panels that sum **interacted with period fixed effects**
#' (controlling only the overall sum is not enough in a panel -- shocks must be
#' compared within periods; with complete shares the interaction reduces to
#' period fixed effects). These automatic columns are pruned of anything
#' already spanned by your own `controls`, so supplying period fixed effects
#' yourself is harmless.
#'
#' @param data A unit-level `data.frame`: one row per location (or
#'   location-period). Must contain `y`, `x`, `location`, and any `controls`,
#'   `weights`, `cluster` columns referenced below.
#' @param shares A long `data.frame` of exposure shares with columns
#'   `location`, `sector`, the share column (`share_col`), and `time` for panels.
#' @param shocks A `data.frame` of shocks with columns `sector`, the shock
#'   column (`shock_col`), and `time` for panels.
#' @param y,x Column names (strings) of the outcome and endogenous treatment.
#' @param location,sector Column names of the unit and sector identifiers.
#' @param time Optional column name of a period identifier (present in `data`,
#'   `shares` and `shocks`) for panel designs.
#' @param controls Optional character vector of control columns in `data`.
#'   Numeric columns enter linearly; factor or character columns are expanded
#'   into dummies, so period or region fixed effects can be supplied as
#'   factors. On the shift route, period fixed effects (interacted with the
#'   sum of exposure shares) are added automatically in panels --- shocks are
#'   compared within periods; on the share route in panels, supply period
#'   fixed effects here yourself.
#' @param weights Optional column name of regression weights in `data`.
#' @param cluster Optional column name of a clustering variable in `data`.
#' @param share_col Name of the exposure-share column in `shares` (default
#'   `"share"`).
#' @param shock_col Name of the shock (shift) column in `shocks` (default
#'   `"shock"`).
#' @param exogenous **Required.** Which identification route the design rests
#'   on: `"shift"` (exogenous shocks) or `"share"` (exogenous shares).
#'   `"shock"`/`"shares"` are accepted aliases. There is no default: the route
#'   determines the automatic controls, the appropriate standard errors and the
#'   relevant diagnostics, so it must be chosen deliberately.
#'
#' @return An object of class `ssb_design`.
#' @examples
#' sim <- ssb_simulate(n_loc = 80, n_sec = 10, seed = 1)
#' d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
#' d
#' @export
ssb_design <- function(data, shares, shocks,
                       y = "y", x = "x",
                       location = "location", sector = "sector",
                       time = NULL, controls = NULL,
                       weights = NULL, cluster = NULL,
                       share_col = "share", shock_col = "shock",
                       exogenous) {

  # the route is an identification assumption (it also fixes the automatic
  # controls, the standard errors and the diagnostics): it must not default.
  if (missing(exogenous) || is.null(exogenous) ||
      length(exogenous) != 1L || is.na(exogenous))
    stop("ssb_design(): `exogenous` must be specified -- \"shift\" for ",
         "exogenous shocks (Borusyak-Hull-Jaravel) or \"share\" for exogenous ",
         "shares (Goldsmith-Pinkham-Sorkin-Swift). The identification route ",
         "determines which controls, standard errors and diagnostics apply, ",
         "so it cannot default.", call. = FALSE)

  exogenous <- match.arg(exogenous,
                         c("shift", "share", "shock", "shares"))
  exogenous <- switch(exogenous,
                      shock = "shift", shares = "share", exogenous)

  stopifnot(is.data.frame(data), is.data.frame(shares), is.data.frame(shocks))
  need <- c(y, x, location, controls, weights, cluster)
  miss <- setdiff(need, names(data))
  if (length(miss)) stop("columns not found in `data`: ",
                         paste(miss, collapse = ", "))
  miss <- setdiff(c(location, sector, share_col, time), names(shares))
  if (length(miss)) stop("columns not found in `shares`: ",
                         paste(miss, collapse = ", "))
  miss <- setdiff(c(sector, shock_col, time), names(shocks))
  if (length(miss)) stop("columns not found in `shocks`: ",
                         paste(miss, collapse = ", "))
  shock_key <- if (is.null(time)) shocks[[sector]]
               else paste(shocks[[sector]], shocks[[time]], sep = "\r")
  if (anyDuplicated(shock_key))
    stop("`shocks` must have one row per sector",
         if (is.null(time)) "" else " x period", " cell.")

  vars <- list(y = y, x = x, location = location, sector = sector,
               time = time, controls = controls,
               weights = weights, cluster = cluster,
               share_col = share_col, shock_col = shock_col)

  d <- list(data = data, shares = shares, shocks = shocks,
            vars = vars, exogenous = exogenous)
  class(d) <- "ssb_design"

  # Build aligned instrument / share matrix eagerly so the object is "ready".
  d <- .ssb_build(d)
  if (exogenous == "shift" && !is.null(time))
    message("ssb_design(): exogenous-shift panel -- the sum of exposure ",
            "shares interacted with period fixed effects is controlled ",
            "automatically (Borusyak-Hull-Jaravel); controlling only the ",
            "overall sum is not sufficient in panels.")
  d
}

# Internal: build the units x sector-cells share matrix `S`, aligned shock
# vector `g`, instrument `z` and per-unit share sum. Handles cross-section and
# (sector x period) panels uniformly by keying on (location[,time]) rows and
# (sector[,time]) cells.
.ssb_build <- function(d) {
  v <- d$vars
  data <- d$data; shares <- d$shares; shocks <- d$shocks
  tt <- v$time

  row_key  <- if (is.null(tt)) as.character(data[[v$location]])
              else paste(data[[v$location]], data[[tt]], sep = "\r")
  sh_rowk  <- if (is.null(tt)) as.character(shares[[v$location]])
              else paste(shares[[v$location]], shares[[tt]], sep = "\r")
  sh_cellk <- if (is.null(tt)) as.character(shares[[v$sector]])
              else paste(shares[[v$sector]], shares[[tt]], sep = "\r")
  sk_cellk <- if (is.null(tt)) as.character(shocks[[v$sector]])
              else paste(shocks[[v$sector]], shocks[[tt]], sep = "\r")

  cells <- sk_cellk                      # cell order follows the shocks table
  g <- shocks[[v$shock_col]]
  names(g) <- cells

  ri <- match(sh_rowk,  row_key)
  ci <- match(sh_cellk, cells)
  ok <- !is.na(ri) & !is.na(ci)
  if (!all(ok))
    warning(sum(!ok), " row(s) of `shares` matched no unit in `data` or no ",
            "cell in `shocks` and were dropped.", call. = FALSE)
  idx  <- cbind(ri[ok], ci[ok])
  vals <- shares[[v$share_col]][ok]

  # duplicated (location, sector[, time]) rows would silently overwrite each
  # other in the matrix assignment below; sum them instead and tell the user.
  keys <- paste(idx[, 1], idx[, 2], sep = "\r")
  if (anyDuplicated(keys)) {
    warning("duplicated (location, sector) rows found in `shares`; ",
            "their shares were summed.", call. = FALSE)
    sums  <- rowsum(vals, keys)
    first <- !duplicated(keys)
    idx   <- idx[first, , drop = FALSE]
    vals  <- as.numeric(sums[keys[first], ])
  }

  S <- matrix(0, nrow(data), length(cells),
              dimnames = list(NULL, cells))
  S[idx] <- vals

  z         <- as.numeric(S %*% g)
  share_sum <- rowSums(S)

  d$mat <- list(
    S = S, g = g, z = z, share_sum = share_sum,
    cell_sector = if (is.null(tt)) shocks[[v$sector]]
                  else paste(shocks[[v$sector]], shocks[[tt]], sep = " @ "),
    cell_time = if (is.null(tt)) NULL else shocks[[tt]],
    complete = isTRUE(all.equal(share_sum, rep(1, length(share_sum)),
                                tolerance = 1e-6))
  )
  d$mat$auto_C <- .ssb_make_auto(d)
  d
}

# Route-specific automatic controls (Borusyak, Hull & Jaravel): with exogenous
# shocks the per-unit sum of exposure shares must be controlled when shares
# are incomplete, and in panels the sum must be *interacted with period fixed
# effects* -- controlling only the overall sum is not enough because shocks
# have to be compared within periods (this matters a lot in the BHJ ADH
# application). With complete shares the interaction reduces to period FE.
# Redundant columns (vs the intercept, or vs user controls) are pruned later
# by .ssb_auto_kept().
.ssb_make_auto <- function(d) {
  if (d$exogenous != "shift") return(NULL)
  tt <- d$vars$time
  ss <- d$mat$share_sum
  if (is.null(tt)) {
    if (d$mat$complete) return(NULL)
    return(cbind(.share_sum = ss))
  }
  per <- factor(d$data[[tt]])
  A <- stats::model.matrix(~ 0 + per) * ss
  colnames(A) <- paste0(".share_sum@", levels(per))
  A
}

#' @export
print.ssb_design <- function(x, ...) {
  v <- x$vars; m <- x$mat
  cat("<ssBartik design>\n")
  cat(sprintf("  route      : exogenous %s\n", toupper(x$exogenous)))
  cat(sprintf("  units      : %d   sectors/cells : %d%s\n",
              nrow(x$data), length(m$g),
              if (is.null(v$time)) "" else "  (panel)"))
  cat(sprintf("  outcome/trt: %s ~ %s\n", v$y, v$x))
  cat(sprintf("  controls   : %s\n",
              if (is.null(v$controls)) "(none)" else paste(v$controls, collapse = ", ")))
  cat(sprintf("  weights    : %s   cluster : %s\n",
              v$weights %||% "(none)", v$cluster %||% "(none)"))
  cat(sprintf("  shares sum to one : %s\n", if (m$complete) "yes" else "NO (incomplete)"))
  invisible(x)
}

#' @export
summary.ssb_design <- function(object, ...) print(object, ...)

# accessors used across the package
.ssb_w <- function(d) {
  w <- if (is.null(d$vars$weights)) rep(1, nrow(d$data)) else d$data[[d$vars$weights]]
  as.numeric(w)
}
.ssb_user_C <- function(d) {
  ctl <- d$vars$controls
  C <- NULL
  if (!is.null(ctl)) {
    df <- d$data[, ctl, drop = FALSE]
    if (anyNA(df))
      stop("control columns contain missing values: ",
           paste(ctl[vapply(df, anyNA, logical(1))], collapse = ", "))
    if (all(vapply(df, is.numeric, logical(1)))) {
      C <- as.matrix(df)
    } else {
      # expand factor / character controls into dummies (e.g. period or region
      # fixed effects); drop the intercept column since .ssb_resid adds one.
      C <- stats::model.matrix(~ ., data = df)[, -1, drop = FALSE]
    }
  }
  C
}

# Automatic controls (see .ssb_make_auto) pruned of anything already spanned by
# the intercept and the user controls, so downstream solvers never face an
# exactly collinear design (e.g. complete-share panels, where the interactions
# reduce to period dummies the user may already control).
.ssb_auto_kept <- function(d, C_user) {
  A <- d$mat$auto_C
  if (is.null(A) || !ncol(A)) return(NULL)
  keep <- .ssb_indep_cols(A, X0 = cbind(rep(1, nrow(A)), C_user))
  if (!length(keep)) return(NULL)
  A[, keep, drop = FALSE]
}

.ssb_C <- function(d) {
  # user controls plus the route-specific automatic controls: on the shift
  # route the sum of exposure shares (Borusyak, Hull & Jaravel 2022, sec. 3.2),
  # interacted with period fixed effects in panels (see .ssb_make_auto).
  C <- .ssb_user_C(d)
  A <- .ssb_auto_kept(d, C)
  if (!is.null(A)) C <- cbind(C, A)
  C
}
