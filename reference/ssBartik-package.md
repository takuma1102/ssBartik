# ssBartik: an end-to-end pipeline for shift-share (Bartik) IV designs

Shift-share / Bartik instrumental-variable analysis in R has been spread
across several single-purpose packages: ShiftShareSE (Kolesar) for AKM
inference, `bartik.weight` (jjchern) for Rotemberg weights, and
`ssaggregate` (Butts) for shock-level aggregation. ssBartik brings
construction, diagnostics, estimation, exposure-robust inference and
publication-ready visualisation into one consistent workflow, organised
around the two identification routes of the modern literature (exogenous
shares vs. exogenous shifts).

## Details

The single entry point is \[ssb_design()\] (or the one-call
\[ssbartik()\]). Choose the route with \`exogenous\`; the instrument is
constructed identically either way, and the flag governs which
diagnostics and controls apply.

## Acknowledgements & references

Built with gratitude on the work of Michal Kolesar (ShiftShareSE), Kyle
Butts (\`ssaggregate\`), Junjie (JJ) Chern (\`bartik.weight\`) and Paul
Goldsmith-Pinkham (\`bartik-weight\`, the original Stata
implementation). Core methods: Adao, Kolesar & Morales (2019, QJE);
Borusyak, Hull & Jaravel (2022, REStud), Borusyak, Hull & Jaravel (2025,
"A Practical Guide to Shift-Share Instruments") and Borusyak, Hull &
Jaravel (2025, "Design-based identification with formula instruments: a
review", Econometrics Journal 28(1), 83-108); Goldsmith-Pinkham, Sorkin
& Swift (2020, AER).

## See also

Useful links:

- <https://github.com/takuma1102/ssBartik>

- <https://takuma1102.github.io/ssBartik/>

- Report bugs at <https://github.com/takuma1102/ssBartik/issues>

## Author

**Maintainer**: Takuma Iwasaki <iwasakit@stanford.edu> (affiliation:
Stanford University)

Authors:

- Takuma Iwasaki <iwasakit@stanford.edu> (affiliation: Stanford
  University)
