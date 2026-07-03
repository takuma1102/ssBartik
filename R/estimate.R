#' Estimate a shift-share IV regression with several standard errors
#'
#' Computes the shift-share 2SLS point estimate of `x` on `y` (instrumented by
#' the constructed Bartik instrument, controls partialled out via FWL) and
#' reports a panel of standard errors side by side so the practical importance
#' of the correction is visible:
#' \itemize{
#'   \item `iid` --- classical (homoskedastic) IV,
#'   \item `ehw` --- Eicker-Huber-White (heteroskedasticity-robust),
#'   \item `cluster` --- naive cluster-robust (needs `cluster` in the design),
#'   \item `akm`, `akm0` --- Adao-Kolesar-Morales exposure-robust SE / CI,
#'         via \pkg{ShiftShareSE} when installed.
#' }
#' The point estimate is identical across rows; only the standard errors and
#' intervals differ, which is exactly what makes the comparison instructive.
#'
#' @param design An [ssb_design()] object.
#' @param methods Which SEs to report.
#' @param level Confidence level for the reported intervals.
#'
#' @return A `data.frame` of class `ssb_estimate` with one row per method
#'   (`estimate`, `std.error`, `conf.low`, `conf.high`), carrying the
#'   first-stage F as an attribute. Plot with [ssb_plot_se()].
#' @export
ssb_estimate <- function(design,
                         methods = c("iid", "ehw", "cluster",
                                     "akm", "akm0"),
                         level = 0.95) {
  stopifnot(inherits(design, "ssb_design"))
  methods <- ifelse(methods %in% c("homoskedastic", "homoscedastic"), "iid", methods)
  d <- design
  w <- .ssb_w(d); C <- .ssb_C(d)
  cl <- if (is.null(d$vars$cluster)) NULL else d$data[[d$vars$cluster]]

  ry <- .ssb_resid(d$data[[d$vars$y]], C, w)
  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  rz <- .ssb_resid(d$mat$z,            C, w)

  zx   <- .ssb_wip(rz, rx, w)
  beta <- .ssb_wip(rz, ry, w) / zx
  e    <- ry - beta * rx                 # IV residual
  gmom <- w * rz * e                     # score moments
  fs   <- .ssb_uni_robust(rx, rz, w)$fstat  # first-stage F (x on z)

  q <- stats::qnorm(1 - (1 - level) / 2)
  se_of <- function(meat) sqrt(meat) / abs(zx)
  n <- length(ry)
  row_native <- function(method, se, note = "") data.frame(
    method = method, estimate = beta, std.error = se,
    conf.low = beta - q * se, conf.high = beta + q * se,
    note = note, stringsAsFactors = FALSE)

  rows <- list()
  akm_req <- intersect(methods, c("akm", "akm0"))
  akm_tab <- if (length(akm_req)) .ssb_akm(d, akm_req, level) else NULL

  for (mth in methods) {
    if (mth == "iid") {
      sig2 <- sum(w * e^2) / max(n - 1, 1)
      rows[[mth]] <- row_native(mth, sqrt(sig2 * sum(w * rz^2)) / abs(zx))
    } else if (mth == "ehw") {
      rows[[mth]] <- row_native(mth, se_of(sum(gmom^2) * n / max(n - 1, 1)))
    } else if (mth == "cluster") {
      rows[[mth]] <- if (is.null(cl)) row_native(mth, NA_real_, "no cluster var")
                     else row_native(mth, se_of(.ssb_cluster_meat(gmom, cl)))
    } else if (mth %in% c("akm", "akm0")) {
      rows[[mth]] <- akm_tab[akm_tab$method == mth, , drop = FALSE]
    }
  }
  out <- do.call(rbind, rows); rownames(out) <- NULL
  attr(out, "fstat") <- fs
  attr(out, "level") <- level
  class(out) <- c("ssb_estimate", "data.frame")
  out
}

# Adao-Kolesar-Morales exposure-robust inference via ShiftShareSE::ivreg_ss.
# Calls the package once and returns a tidy block for the requested akm methods;
# degrades to NA rows with an informative note when the package/estimation fails.
.ssb_akm <- function(d, methods, level) {
  na_row <- function(m, note) data.frame(
    method = m, estimate = NA_real_, std.error = NA_real_,
    conf.low = NA_real_, conf.high = NA_real_, note = note,
    stringsAsFactors = FALSE)
  if (!requireNamespace("ShiftShareSE", quietly = TRUE))
    return(do.call(rbind, lapply(methods, na_row, note = "install ShiftShareSE")))

  v <- d$vars
  ctl <- v$controls %||% character(0)
  if (d$exogenous == "shift" && !d$mat$complete) {
    d$data[[".share_sum"]] <- d$mat$share_sum        # incomplete-shares control
    ctl <- c(ctl, ".share_sum")
  }
  rhs <- if (length(ctl)) paste(ctl, collapse = " + ") else "1"
  fml <- stats::as.formula(paste(v$y, "~", rhs, "|", v$x))
  wts <- if (is.null(v$weights)) NULL else d$data[[v$weights]]
  rcv <- if (is.null(v$cluster)) NULL else d$data[[v$cluster]]

  res <- tryCatch(
    ShiftShareSE::ivreg_ss(
      formula = fml, X = d$mat$z, data = d$data, W = d$mat$S,
      method = methods, weights = wts, region_cvar = rcv,
      alpha = 1 - level),
    error = function(e) e)
  if (inherits(res, "error"))
    return(do.call(rbind, lapply(methods, na_row,
                                 note = paste0("ShiftShareSE: ", conditionMessage(res)))))

  key <- c(akm = "AKM", akm0 = "AKM0")
  do.call(rbind, lapply(methods, function(m) {
    k <- key[[m]]
    data.frame(method = m, estimate = unname(res$beta),
               std.error = unname(res$se[[k]]),
               conf.low = unname(res$ci.l[[k]]),
               conf.high = unname(res$ci.r[[k]]),
               note = "", stringsAsFactors = FALSE)
  }))
}

#' @export
print.ssb_estimate <- function(x, ...) {
  cat("<ssBartik estimate>\n")
  cat(sprintf("  first-stage F : %.1f\n", attr(x, "fstat")))
  tab <- x[c("method", "estimate", "std.error", "conf.low", "conf.high", "note")]
  tab$method <- toupper(tab$method)
  print(format(tab, digits = 3), row.names = FALSE)
  invisible(x)
}
