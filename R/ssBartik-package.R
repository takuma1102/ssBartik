#' ssBartik: End-to-End Pipeline for Shift-Share (Bartik) IV Designs
#'
#' Shift-share / Bartik instrumental-variable analysis in R has been spread
#' across several single-purpose packages: \pkg{ShiftShareSE} (Kolesar) for AKM
#' inference, \code{bartik.weight} (jjchern) for Rotemberg weights, and
#' \code{ssaggregate} (Butts) for shock-level aggregation. \pkg{ssBartik}
#' brings construction, diagnostics, estimation, exposure-robust inference and
#' publication-ready visualisation into one consistent workflow, organised
#' around the two identification routes of the modern literature (exogenous
#' shares vs. exogenous shifts).
#'
#' The single entry point is [ssb_design()] (or the one-call [ssbartik()]).
#' Choose the route with `exogenous`; the instrument is constructed identically
#' either way, and the flag governs which diagnostics and controls apply.
#'
#' @section Acknowledgements & references:
#' Built with gratitude on the work of Michal Kolesar (\pkg{ShiftShareSE}),
#' Kyle Butts (`ssaggregate`), Junjie (JJ) Chern (`bartik.weight`) and
#' Paul Goldsmith-Pinkham (`bartik-weight`, the original Stata implementation).
#' Core methods: Adao, Kolesar & Morales (2019, QJE); Borusyak, Hull & Jaravel
#' (2022, REStud), Borusyak, Hull & Jaravel (2025, "A Practical Guide to
#' Shift-Share Instruments") and Borusyak, Hull & Jaravel (2025, "Design-based
#' identification with formula instruments: a review", Econometrics Journal
#' 28(1), 83-108); Goldsmith-Pinkham, Sorkin & Swift (2020, AER).
#'
#' @keywords internal
#' @importFrom ggplot2 autoplot .data
"_PACKAGE"
