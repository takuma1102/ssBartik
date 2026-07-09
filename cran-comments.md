## Submission summary

This is a new submission. ssBartik (0.1.1) provides an end-to-end workflow for
shift-share (Bartik) instrumental-variable designs: instrument construction,
2SLS estimation with a panel of confidence intervals (including exposure-robust
AKM / AKM0), credibility diagnostics for both the exogenous-shares and
exogenous-shocks identification routes, and publication-ready figures and
tables.

## Test environments

* Local: Ubuntu 24.04, R 4.3.3
* win-builder: R-devel and R-release (`devtools::check_win_devel()`,
  `devtools::check_win_release()`)

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE

      Maintainer: 'Takuma Iwasaki <iwasakit@stanford.edu>'

      New submission

  This is the first submission of ssBartik to CRAN.

## Notes for the reviewer

* The incoming-feasibility check may also list "possibly misspelled words" in
  the DESCRIPTION. These are author surnames and established technical terms in
  the shift-share econometrics literature (e.g. Bartik, Rotemberg, Borusyak,
  Jaravel, Goldsmith-Pinkham, Sorkin, Adao, Kolesar, Morales, AKM, AKM0,
  exogenous) and are spelled correctly.

* The three `<doi:...>` identifiers in the Description field resolve to the
  cited articles (American Economic Review 2018; Review of Economic Studies
  2022; Quarterly Journal of Economics 2019).

* Exposure-robust (AKM / AKM0) inference optionally uses the suggested package
  'ShiftShareSE'. All examples and tests degrade gracefully when it is not
  installed -- the affected rows are returned as NA with an informative note
  rather than erroring -- so the package checks cleanly both with and without
  the suggested dependency.

## Downstream dependencies

There are no reverse dependencies (new package).
