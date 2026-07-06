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
#'         via \pkg{ShiftShareSE} when installed,
#'   \item `twoway` --- two-way cluster-robust (needs `cluster` in the design
#'         and `cluster2` here).
#' }
#' The point estimate is identical across rows; only the standard errors and
#' intervals differ, which is exactly what makes the comparison instructive.
#'
#' @param design An [ssb_design()] object.
#' @param methods Which SEs to report (add `"twoway"` for two-way clustering).
#' @param level Confidence level for the reported intervals.
#' @param cluster2 Optional second clustering column in `data` for the
#'   `"twoway"` method (paired with the design's `cluster`).
#'
#' @return A `data.frame` of class `ssb_estimate` with one row per method
#'   (`estimate`, `std.error`, `conf.low`, `conf.high`), carrying the
#'   first-stage F as an attribute. Plot with [ssb_plot_se()].
#' @export
ssb_estimate <- function(design,
                         methods = c("iid", "ehw", "cluster",
                                     "akm", "akm0"),
                         level = 0.95, cluster2 = NULL) {
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
  akm_tab <- if (length(akm_req)) .ssb_akm(d, akm_req, level) else NULL

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
    if (l == "" && h == "") "" else sprintf("[%s, %s]", l, h)
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
