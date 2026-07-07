# Pre-trend test

Reduced-form regression of a pre-period outcome on the constructed
instrument (controls partialled out). A coefficient far from zero
indicates that exposure predicts differential pre-trends — a threat to
identification. This is distinct from \[ssb_placebo()\], which runs the
\*full IV\* on a placebo outcome; pre-trends ask whether exposure
predicts the outcome \*before\* the shocks, placebo asks whether the
design moves an outcome it should not.

## Usage

``` r
ssb_pretrend(design, pre_y, level = 0.95)
```

## Arguments

- design:

  An \[ssb_design()\] object.

- pre_y:

  Column name of the pre-period outcome (or pre-period change).

- level:

  Confidence level.

## Value

A list (class \`ssb_pretrend\`) with the reduced-form coefficient, EHW /
cluster / exposure-robust (AKM) standard errors, the corresponding
p-values (\`p_ehw\`, \`p_akm\`), and intervals
(\`conf.low\`/\`conf.high\` use the EHW SE;
\`conf.low_akm\`/\`conf.high_akm\` the exposure-robust SE).

## Details

Because the regressor is itself a shift-share variable, EHW / cluster
standard errors are subject to exactly the over-rejection documented by
Adao, Kolesar & Morales (2019): residuals are correlated across units
with similar exposure. The test therefore also reports an
exposure-robust (AKM-type) standard error that clusters the score at the
shock level; treat that one as the headline, especially on the shift
route, or spurious "pre-trends" will appear too often.
