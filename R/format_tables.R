## format() methods for the important result / diagnostic tables ---------------
## A shared engine turns a data.frame into paste-ready LaTeX (booktabs) or
## Markdown; each format.<class> method assembles the relevant columns and note.

# Generic paste-ready table. Numeric columns are formatted to `digits` (blank for
# NA, infinity symbols for +/-Inf); character columns pass through. A `note` is
# appended as a full-width footnote row (LaTeX) or an italic line (Markdown).
.ssb_df_table <- function(df, output = c("latex", "markdown"),
                          headers = names(df), align = NULL,
                          caption = NULL, label = NULL, note = NULL,
                          digits = 3) {
  output <- match.arg(output)
  fmt_col <- function(col) {
    if (is.numeric(col))
      vapply(col, function(v) {
        if (is.na(v)) ""
        else if (is.infinite(v))
          (if (output == "latex") (if (v > 0) "$\\infty$" else "$-\\infty$")
           else (if (v > 0) "Inf" else "-Inf"))
        else formatC(v, format = "f", digits = digits)
      }, character(1))
    else as.character(col)
  }
  cols <- lapply(df, fmt_col)
  nr <- if (length(cols)) length(cols[[1]]) else 0L
  nc <- length(cols)
  if (is.null(align)) align <- c("l", rep("r", max(nc - 1L, 0L)))
  cell <- function(i) vapply(cols, function(cc) cc[i], character(1))

  if (output == "markdown") {
    a_md <- ifelse(align == "l", ":--", ifelse(align == "c", ":-:", "--:"))
    out <- c(paste0("| ", paste(headers, collapse = " | "), " |"),
             paste0("| ", paste(a_md,   collapse = " | "), " |"),
             vapply(seq_len(nr),
                    function(i) paste0("| ", paste(cell(i), collapse = " | "), " |"),
                    character(1)))
    if (!is.null(note)) out <- c(out, "", paste0("*", note, "*"))
    out
  } else {
    body <- vapply(seq_len(nr),
                   function(i) paste0(paste(cell(i), collapse = " & "), " \\\\"),
                   character(1))
    note_row <- if (is.null(note)) character(0)
      else c("\\midrule",
             sprintf("\\multicolumn{%d}{l}{\\footnotesize %s} \\\\", nc, note))
    c("\\begin{table}[!ht]", "\\centering",
      if (!is.null(caption)) sprintf("\\caption{%s}", caption) else character(0),
      if (!is.null(label))   sprintf("\\label{%s}", label)     else character(0),
      sprintf("\\begin{tabular}{%s}", paste(align, collapse = "")),
      "\\toprule",
      paste0(paste(headers, collapse = " & "), " \\\\"),
      "\\midrule",
      body, note_row,
      "\\bottomrule", "\\end{tabular}", "\\end{table}")
  }
}

#' Render a leave-one-out table as LaTeX or Markdown
#'
#' Paste-ready version of the [ssb_loo()] sensitivity table (one row per dropped
#' shock, with the re-estimated coefficient); the overall estimate is in a note.
#'
#' @param x An [ssb_loo()] object.
#' @inheritParams format.ssb_estimate
#' @return A character vector of the table lines; pass to `writeLines()`.
#' @export
format.ssb_loo <- function(x, output = c("latex", "markdown"), digits = 3,
                           caption = NULL, label = "tab:ssb-loo", ...) {
  output <- match.arg(output)
  df <- data.frame(sector = as.character(x$sector), alpha = x$alpha,
                   beta = x$beta_drop, stringsAsFactors = FALSE)
  headers <- if (output == "latex")
    c("Sector", "$\\hat\\alpha_n$", "$\\hat\\beta_{-n}$")
  else c("Sector", "Rotemberg weight", "Estimate without shock")
  .ssb_df_table(df, output, headers = headers,
                caption = caption %||% "Leave-one-out sensitivity", label = label,
                note = sprintf("Overall estimate = %s.",
                               formatC(attr(x, "beta_hat"), format = "f", digits = digits)),
                digits = digits)
}

#' @export
print.ssb_loo <- function(x, ...) {
  cat(sprintf("<ssBartik leave-one-out>  overall beta = %.4f\n", attr(x, "beta_hat")))
  d <- x[c("sector", "alpha", "beta_drop")]; class(d) <- "data.frame"
  print(format(d, digits = 3), row.names = FALSE)
  invisible(x)
}

#' Render a shock-exposure summary as LaTeX or Markdown
#'
#' Paste-ready version of the [ssb_shock_summary()] diagnostic: the top shocks by
#' exposure weight, with the effective number of shocks and concentration in a
#' note.
#'
#' @param x An [ssb_shock_summary()] (`ssb_shocks`) object.
#' @param top Number of top-exposure shocks to include.
#' @inheritParams format.ssb_estimate
#' @return A character vector of the table lines; pass to `writeLines()`.
#' @export
format.ssb_shocks <- function(x, output = c("latex", "markdown"), digits = 3,
                              caption = NULL, label = "tab:ssb-shocks",
                              top = 8, ...) {
  output <- match.arg(output)
  w  <- utils::head(x$weights, min(top, nrow(x$weights)))
  df <- data.frame(sector = as.character(w$sector), weight = w$weight,
                   stringsAsFactors = FALSE)
  .ssb_df_table(df, output, headers = c("Sector", "Exposure weight"),
                caption = caption %||% "Shock-level exposure summary", label = label,
                note = sprintf("Effective shocks = %.1f (HHI %.3f); %d shocks total.",
                               x$effective_shocks, x$hhi, x$n_shocks),
                digits = digits)
}

#' Render an overidentification test as LaTeX or Markdown
#'
#' Paste-ready statistic/value table for the [ssb_overid()] cross-instrument
#' homogeneity test.
#'
#' @param x An [ssb_overid()] object.
#' @inheritParams format.ssb_estimate
#' @return A character vector of the table lines; pass to `writeLines()`.
#' @export
format.ssb_overid <- function(x, output = c("latex", "markdown"), digits = 3,
                              caption = NULL, label = "tab:ssb-overid", ...) {
  output <- match.arg(output)
  i2   <- if (output == "latex") sprintf("%.1f\\%%", 100 * x$I2)
          else sprintf("%.1f%%", 100 * x$I2)
  stat <- if (output == "latex")
    c("$Q$", "df", "$p$-value", "$I^2$", "Weighted mean $\\hat\\beta$", "Instruments used")
  else c("Q", "df", "p-value", "I-squared", "Weighted mean estimate", "Instruments used")
  val  <- c(formatC(x$Q, format = "f", digits = 2), as.character(x$df),
            formatC(x$p, format = "f", digits = 4), i2,
            formatC(x$beta_bar, format = "f", digits = digits),
            as.character(x$n_instruments))
  df <- data.frame(statistic = stat, value = val, stringsAsFactors = FALSE)
  .ssb_df_table(df, output, headers = c("Statistic", "Value"), align = c("l", "r"),
                caption = caption %||% "Overidentification test", label = label,
                note = paste0("Small p rejects a common coefficient ",
                              "(exogeneity failure or heterogeneity)."),
                digits = digits)
}

#' Render a shock-balance test as LaTeX or Markdown
#'
#' Paste-ready coefficient table for the [ssb_shock_balance()] test, with the
#' joint Wald statistic in a note.
#'
#' @param x An [ssb_shock_balance()] object.
#' @inheritParams format.ssb_estimate
#' @return A character vector of the table lines; pass to `writeLines()`.
#' @export
format.ssb_shock_balance <- function(x, output = c("latex", "markdown"),
                                     digits = 3, caption = NULL,
                                     label = "tab:ssb-shock-balance", ...) {
  output <- match.arg(output)
  cf <- x$coefficients
  df <- data.frame(covariate = as.character(cf$covariate), coef = cf$coef,
                   se = cf$se, t = cf$t, p = cf$p, stringsAsFactors = FALSE)
  headers <- if (output == "latex")
    c("Characteristic", "Coef.", "SE", "$t$", "$p$")
  else c("Characteristic", "Coef.", "SE", "t", "p")
  .ssb_df_table(df, output, headers = headers,
                caption = caption %||% "Shock-level balance test", label = label,
                note = sprintf(paste0("Joint Wald = %.2f on %d df, p = %.3f. ",
                                      "Non-significant supports shock exogeneity."),
                               x$joint_wald, x$joint_df, x$joint_p),
                digits = digits)
}

#' Render a Rotemberg-weight summary as LaTeX or Markdown
#'
#' Paste-ready version of the [ssb_weight_summary()] table (top shocks by weight),
#' with the largest weight and the weight/estimate/F correlations in a note.
#'
#' @param x An [ssb_weight_summary()] object.
#' @inheritParams format.ssb_estimate
#' @return A character vector of the table lines; pass to `writeLines()`.
#' @export
format.ssb_weight_summary <- function(x, output = c("latex", "markdown"),
                                      digits = 3, caption = NULL,
                                      label = "tab:ssb-weights", ...) {
  output <- match.arg(output)
  tp <- x$top
  df <- data.frame(sector = as.character(tp$sector), alpha = tp$alpha,
                   beta = tp$beta, F = tp$F, g = tp$g, stringsAsFactors = FALSE)
  headers <- if (output == "latex")
    c("Sector", "$\\hat\\alpha_n$", "$\\hat\\beta_n$", "$F$", "$g_n$")
  else c("Sector", "Rotemberg weight", "Just-ID estimate", "First-stage F", "Shock")
  cc <- if (!is.null(x$cov_cor))
    paste0(", with covariate exposure ",
           paste(sprintf("(%s) %.2f", names(x$cov_cor), x$cov_cor), collapse = ", "))
  else ""
  note <- sprintf(paste0("Largest weight = %.3f (%s). Correlation of weights with ",
                         "just-ID estimates = %.2f, with first-stage F = %.2f%s."),
                  x$max_alpha, x$max_sector, x$cor[["alpha_vs_beta"]],
                  x$cor[["alpha_vs_F"]], cc)
  .ssb_df_table(df, output, headers = headers,
                caption = caption %||% "Rotemberg-weight summary", label = label,
                note = note, digits = digits)
}

#' Render a drop-top-shocks comparison as LaTeX or Markdown
#'
#' Paste-ready full-vs-reduced table from [ssb_drop_top()].
#'
#' @param x An [ssb_drop_top()] object.
#' @inheritParams format.ssb_estimate
#' @return A character vector of the table lines; pass to `writeLines()`.
#' @export
format.ssb_drop_top <- function(x, output = c("latex", "markdown"), digits = 3,
                                caption = NULL, label = "tab:ssb-droptop", ...) {
  output <- match.arg(output)
  df <- data.frame(method = .ssb_se_label(x$full$method),
                   full = x$full$estimate, reduced = x$reduced$estimate,
                   stringsAsFactors = FALSE)
  .ssb_df_table(df, output,
                headers = c("Method", "Full", sprintf("Drop top %d", x$n)),
                caption = caption %||% sprintf("Estimate after dropping the top %d shocks", x$n),
                label = label,
                note = sprintf("Dropped: %s.", paste(utils::head(x$dropped, 8), collapse = ", ")),
                digits = digits)
}
