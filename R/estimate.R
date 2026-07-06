#' Estimate a shift-share IV regression with several confidence intervals
#'
#' Computes the shift-share 2SLS point estimate of `x` on `y` (instrumented by
#' the constructed Bartik instrument, controls partialled out via FWL) and
#' reports a panel of intervals side by side so the practical importance of the
#' inference method is visible:
#' \itemize{
#'   \item `iid` --- classical (homoskedastic) IV,
#'   \item `ehw` --- Eicker-Huber-White (heteroskedasticity-robust),
#'   \item `akm`, `akm0` --- Adao-Kolesar-Morales exposure-robust inference,
#'         via \pkg{ShiftShareSE} when installed,
#'   \item `cluster` --- naive cluster-robust (needs `cluster` in the design),
#'   \item `twoway` --- two-way cluster-robust (needs `cluster` in the design
#'         and `cluster2` here).
#' }
#' The point estimate is identical across rows; only the standard errors and
#' intervals differ, which is exactly what makes the comparison instructive.
#'
#' The primary object of the comparison is the **confidence interval**, not the
#' standard error: AKM0 in particular is defined directly as a (possibly
#' asymmetric, possibly unbounded) interval, and the `std.error` reported for it
#' is a symmetric pseudo-SE implied by that interval rather than a conventional
#' standard error. Read the table and [ssb_plot_ci()] figure as a comparison of
#' intervals. When the instrument is weak the AKM0 confidence *set* need not be
#' an interval at all: it can be the whole real line or the complement of an
#' interval (a union of two rays). \pkg{ShiftShareSE} encodes the latter as
#' `conf.low > conf.high`; `ssb_estimate()` flags both cases in the `note`
#' column and the table/plot methods render them accordingly.
#'
#' `cluster` and `twoway` are **not** in the default panel --- they are usually
#' a secondary concern next to the exposure-robust AKM / AKM0 intervals. Request
#' them explicitly via `methods` when wanted (e.g.
#' `methods = c("iid", "ehw", "akm", "akm0", "cluster")`, adding `"twoway"` and
#' `cluster2` for two-way clustering).
#'
#' @param design An [ssb_design()] object.
#' @param methods Which methods to report. Defaults to the exposure-robust panel
#'   (`iid`, `ehw`, `akm`, `akm0`); add `"cluster"` and/or `"twoway"` for
#'   cluster-robust intervals.
#' @param level Confidence level for the reported intervals.
#' @param cluster2 Optional second clustering column in `data` for the
#'   `"twoway"` method (paired with the design's `cluster`).
#' @param shock_cluster Optional grouping of the shocks for the AKM / AKM0
#'   variance: a column name in the shocks table, or a vector of length equal
#'   to the number of shock-cells. Use it when shocks are mutually correlated
#'   within groups --- e.g. sub-industries within broader industries, or
#'   sector cells of the same sector across periods --- so the exposure-robust
#'   variance is clustered at the group level (Adao, Kolesar & Morales 2019;
#'   passed to \pkg{ShiftShareSE} as `sector_cvar`).
#'
#' @return A `data.frame` of class `ssb_estimate` with one row per method
#'   (`estimate`, `std.error`, `conf.low`, `conf.high`), carrying the
#'   first-stage F as an attribute. Plot with [ssb_plot_ci()].
#' @export
ssb_estimate <- function(design,
                         methods = c("iid", "ehw", "akm", "akm0"),
                         level = 0.95, cluster2 = NULL, shock_cluster = NULL) {
  stopifnot(inherits(design, "ssb_design"))
  methods <- tolower(methods)
  methods <- ifelse(methods %in% c("homoskedastic", "homoscedastic"), "iid", methods)
  known <- c("iid", "ehw", "cluster", "twoway", "akm", "akm0")
  bad <- setdiff(methods, known)
  if (length(bad))
    stop("unknown `methods`: ", paste(bad, collapse = ", "),
         " (available: ", paste(known, collapse = ", "), ")")
  methods <- unique(methods)
  d <- design
  w <- .ssb_w(d); C <- .ssb_C(d)
  cl <- if (is.null(d$vars$cluster)) NULL else d$data[[d$vars$cluster]]
  cl2 <- if (is.null(cluster2)) NULL else d$data[[cluster2]]

  ry <- .ssb_resid(d$data[[d$vars$y]], C, w)
  rx <- .ssb_resid(d$data[[d$vars$x]], C, w)
  rz <- .ssb_resid(d$mat$z,            C, w)

  zx   <- .ssb_wip(rz, rx, w)
  beta <- .ssb_wip(rz, ry, w) / zx
  e    <- ry - beta * rx                 # IV residual
  gmom <- w * rz * e                     # score moments
  # parameters consumed: intercept + controls + the structural coefficient, so
  # HC1/iid finite-sample factors use n - k (not n - 1).
  k    <- .ssb_np(C) + 1L
  fs   <- .ssb_uni_robust(rx, rz, w, p = k)$fstat  # first-stage F (x on z)

  q <- stats::qnorm(1 - (1 - level) / 2)
  se_of <- function(meat) sqrt(meat) / abs(zx)
  n <- length(ry)
  row_native <- function(method, se, note = "") data.frame(
    method = method, estimate = beta, std.error = se,
    conf.low = beta - q * se, conf.high = beta + q * se,
    note = note, stringsAsFactors = FALSE)

  rows <- list()
  akm_req <- intersect(methods, c("akm", "akm0"))
  scl <- if (is.null(shock_cluster)) NULL else .ssb_block(d, shock_cluster)
  akm_tab <- if (length(akm_req)) .ssb_akm(d, akm_req, level, scl) else NULL

  for (mth in methods) {
    if (mth == "iid") {
      sig2 <- sum(w * e^2) / max(n - k, 1)
      rows[[mth]] <- row_native(mth, sqrt(sig2 * sum(w * rz^2)) / abs(zx))
    } else if (mth == "ehw") {
      rows[[mth]] <- row_native(mth, se_of(sum(gmom^2) * n / max(n - k, 1)))
    } else if (mth == "cluster") {
      rows[[mth]] <- if (is.null(cl)) row_native(mth, NA_real_, "no cluster var")
                     else row_native(mth, se_of(.ssb_cluster_meat(gmom, cl)))
    } else if (mth == "twoway") {
      if (is.null(cl) || is.null(cl2)) {
        rows[[mth]] <- row_native(mth, NA_real_, "needs cluster + cluster2")
      } else {
        m1  <- .ssb_cluster_meat(gmom, cl)
        m2  <- .ssb_cluster_meat(gmom, cl2)
        m12 <- .ssb_cluster_meat(gmom, interaction(cl, cl2, drop = TRUE))
        rows[[mth]] <- row_native(mth, sqrt(max((m1 + m2 - m12) / zx^2, 0)))
      }
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
# `shock_cluster` (if given) is passed through as sector_cvar to cluster the
# exposure-robust variance across correlated shocks.
.ssb_akm <- function(d, methods, level, shock_cluster = NULL) {
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
      sector_cvar = shock_cluster,
      alpha = 1 - level),
    error = function(e) e)
  if (inherits(res, "error"))
    return(do.call(rbind, lapply(methods, na_row,
                                 note = paste0("ShiftShareSE: ", conditionMessage(res)))))

  key <- c(akm = "AKM", akm0 = "AKM0")
  do.call(rbind, lapply(methods, function(m) {
    k <- key[[m]]
    lo <- unname(res$ci.l[[k]]); hi <- unname(res$ci.r[[k]])
    note <- ""
    if (m == "akm0") {
      # ShiftShareSE encodes a disjoint AKM0 confidence set (weak instrument)
      # as ci.l > ci.r -- the set is (-Inf, ci.r] U [ci.l, Inf) -- and the
      # whole real line as (-Inf, Inf).
      if (is.finite(lo) && is.finite(hi) && lo > hi)
        note <- sprintf("disjoint CI: (-Inf, %.4g] U [%.4g, Inf)", hi, lo)
      else if (!is.finite(lo) || !is.finite(hi))
        note <- "unbounded CI (weak instrument)"
    }
    data.frame(method = m, estimate = unname(res$beta),
               std.error = unname(res$se[[k]]),
               conf.low = lo,
               conf.high = hi,
               note = note, stringsAsFactors = FALSE)
  }))
}

#' @export
print.ssb_estimate <- function(x, format = c("console", "latex", "markdown"),
                               digits = 3, caption = NULL,
                               label = "tab:ssb-estimate", ...) {
  format <- match.arg(format)
  if (format != "console") {
    cat(.ssb_est_text(x, output = format, digits = digits,
                      caption = caption, label = label), sep = "\n")
    return(invisible(x))
  }
  cat("<ssBartik estimate>\n")
  cat(sprintf("  first-stage F : %.1f\n", attr(x, "fstat")))
  tab <- x[c("method", "estimate", "std.error", "conf.low", "conf.high", "note")]
  tab$method <- .ssb_se_label(tab$method)
  class(tab) <- "data.frame"           # avoid dispatching to format.ssb_estimate
  print(format(tab, digits = digits), row.names = FALSE)
  invisible(x)
}


## Display labels + paste-ready estimate table --------------------------------

# Display labels for SE methods: acronyms stay upper-case, words are capitalized
# on the first letter only (Cluster, Two-way).
.ssb_se_label <- function(m) {
  map <- c(iid = "IID", ehw = "EHW", cluster = "Clustering SE",
           twoway = "Two-way SE", akm = "AKM", akm0 = "AKM0")
  out <- unname(map[m])
  ifelse(is.na(out), vapply(m, .ssb_ucfirst, character(1)), out)
}

# Build the paste-ready estimate table (shared by format() and print()).
.ssb_est_text <- function(x, output = c("latex", "markdown"),
                          digits = 3, caption = NULL, label = "tab:ssb-estimate") {
  output <- match.arg(output)
  d   <- x[!is.na(x$std.error), , drop = FALSE]
  lev <- attr(x, "level") %||% 0.95
  fst <- attr(x, "fstat")
  num <- function(v) {
    if (is.na(v)) return("")
    if (is.infinite(v))
      return(if (output == "latex") (if (v > 0) "$\\infty$" else "$-\\infty$")
             else (if (v > 0) "Inf" else "-Inf"))
    formatC(v, format = "f", digits = digits)
  }
  ci <- function(lo, hi) {
    l <- num(lo); h <- num(hi)
    if (l == "" && h == "") return("")
    if (is.finite(lo) && is.finite(hi) && lo > hi) {
      # disjoint AKM0 confidence set: the complement of an interval
      return(if (output == "latex")
               sprintf("$(-\\infty, %s] \\cup [%s, \\infty)$", h, l)
             else sprintf("(-Inf, %s] U [%s, Inf)", h, l))
    }
    sprintf("[%s, %s]", l, h)
  }
  meth <- .ssb_se_label(d$method)
  est  <- vapply(d$estimate,  num, character(1))
  se   <- vapply(d$std.error, num, character(1))
  cis  <- mapply(ci, d$conf.low, d$conf.high)

  if (output == "markdown") {
    hdr  <- c("Method", "Estimate", "Std. error", sprintf("%.0f%% CI", 100 * lev))
    algn <- c(":--", "--:", "--:", "--:")
    rows <- sprintf("| %s | %s | %s | %s |", meth, est, se, cis)
    note <- if (is.null(fst) || is.na(fst)) character(0)
            else sprintf("*First-stage F = %.1f.*", fst)
    c(paste0("| ", paste(hdr,  collapse = " | "), " |"),
      paste0("| ", paste(algn, collapse = " | "), " |"),
      rows, if (length(note)) c("", note))
  } else {
    if (is.null(caption))
      caption <- if (is.null(fst) || is.na(fst))
        "Shift-share estimate and standard errors."
      else sprintf(paste0("Shift-share estimate and standard errors ",
                          "(first-stage $F = %.1f$)."), fst)
    hdr  <- c("Method", "Estimate", "Std. error", sprintf("%.0f\\%% CI", 100 * lev))
    rows <- sprintf("%s & %s & %s & %s \\\\", meth, est, se, cis)
    c("\\begin{table}[!ht]", "\\centering",
      sprintf("\\caption{%s}", caption),
      sprintf("\\label{%s}", label),
      "\\begin{tabular}{lrrr}",
      "\\toprule",
      paste0(paste(hdr, collapse = " & "), " \\\\"),
      "\\midrule",
      rows,
      "\\bottomrule",
      "\\end{tabular}", "\\end{table}")
  }
}

#' Render the estimate / standard-error table as LaTeX or Markdown
#'
#' Turns an [ssb_estimate()] table into a publication-ready comparison of the
#' point estimate across standard-error methods. `"latex"` uses \pkg{booktabs}
#' rules; `"markdown"` emits a GitHub pipe table. Rows whose standard error is
#' unavailable are dropped. Mirrors [format.ssb_rotemberg()].
#'
#' @param x An [ssb_estimate()] object.
#' @param output `"latex"` (booktabs) or `"markdown"` (pipe table).
#' @param digits Decimal places for the estimate, SE and interval.
#' @param caption,label Table caption and cross-reference label (LaTeX only).
#' @param ... Unused.
#' @return A character vector of the table lines (paste-ready); pass to
#'   `writeLines()`.
#' @export
format.ssb_estimate <- function(x, output = c("latex", "markdown"),
                                digits = 3, caption = NULL,
                                label = "tab:ssb-estimate", ...) {
  .ssb_est_text(x, output = match.arg(output), digits = digits,
                caption = caption, label = label)
}
