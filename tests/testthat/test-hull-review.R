# Regression tests for the 2026 methodological review (Peter Hull).
# Each block is tagged with the review point it pins down.

# hand-built two-period panel with incomplete shares (no panel simulator yet)
.hull_panel <- function(seed = 11, n_loc = 120, n_sec = 9, sd_x = 1) {
  set.seed(seed)
  periods <- c(1, 2)
  shares <- expand.grid(location = seq_len(n_loc), sector = seq_len(n_sec))
  shares$share <- stats::runif(nrow(shares), 0.02, 0.12)      # incomplete
  shocks <- expand.grid(sector = seq_len(n_sec), time = periods)
  shocks$shock <- stats::rnorm(nrow(shocks))
  Z <- tapply(shares$share, list(shares$location, shares$sector), sum)
  dat <- do.call(rbind, lapply(periods, function(t) {
    g <- shocks$shock[shocks$time == t]
    data.frame(location = seq_len(n_loc), time = t,
               x = 2 * as.numeric(Z %*% g) + stats::rnorm(n_loc, sd = sd_x))
  }))
  dat$y <- 1.5 * dat$x + stats::rnorm(nrow(dat))
  shares2 <- do.call(rbind, lapply(periods, function(t) transform(shares, time = t)))
  list(data = dat, shares = shares2, shocks = shocks)
}

# ---- point 1: mandatory route + route-tailored inference --------------------

test_that("point 1: exogenous is required and drives the default SE methods", {
  sim <- ssb_simulate(n_loc = 80, n_sec = 8, seed = 41)
  sim$data$y_pl <- stats::rnorm(nrow(sim$data))
  expect_error(ssb_design(sim$data, sim$shares, sim$shocks), "exogenous")

  d_sh <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
  d_sf <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
  expect_setequal(ssb_estimate(d_sh)$method, "ehw")
  expect_setequal(ssb_estimate(d_sf)$method, c("akm", "akm0"))
  # explicit methods override the route default (documented escape hatch)
  expect_setequal(ssb_estimate(d_sh, methods = c("ehw", "akm"))$method,
                  c("ehw", "akm"))
  # placebo / drop_top inherit the route defaults
  expect_setequal(ssb_placebo(d_sf, "y_pl")$method, c("akm", "akm0"))
  expect_setequal(ssb_drop_top(d_sh, n = 2)$full$method, "ehw")
  # the printed table names the route
  expect_output(print(ssb_estimate(d_sf)), "exogenous SHIFT")
})

# ---- point 2: route-gated pipeline and pretrend guidance --------------------

test_that("point 2: the pipeline reports only route-appropriate statistics", {
  sim <- ssb_simulate(n_loc = 90, n_sec = 8, seed = 42)
  sim$data$y_pre <- stats::rnorm(nrow(sim$data))
  scov <- data.frame(sector = sort(unique(sim$shocks$sector)),
                     size = stats::rnorm(length(unique(sim$shocks$sector))))

  d_sh <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
  r_sh <- ssb_pipeline(d_sh, covariates = "w1", pre_y = "y_pre")
  expect_false(is.null(r_sh$rotemberg))
  expect_false(is.null(r_sh$overid))
  expect_false(is.null(r_sh$share_balance))
  expect_null(r_sh$equivalence)          # shock-level stats not shown here
  expect_null(r_sh$shocks)
  expect_null(r_sh$shock_balance)
  expect_message(ssb_pipeline(d_sh, shock_covariates = scov), "SHARE route")

  d_sf <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
  r_sf <- ssb_pipeline(d_sf, shock_covariates = scov, pre_y = "y_pre")
  expect_false(is.null(r_sf$equivalence))
  expect_false(is.null(r_sf$shocks))
  expect_false(is.null(r_sf$shock_balance))
  expect_null(r_sf$rotemberg)            # share-route stats not shown here
  expect_null(r_sf$overid)
  expect_null(r_sf$share_balance)
  expect_message(ssb_pipeline(d_sf, covariates = "w1"), "SHIFT route")

  # pretrend: the headline follows the route
  expect_identical(r_sf$pretrend$headline, "exposure-robust (AKM)")
  expect_equal(r_sf$pretrend$se, r_sf$pretrend$se_akm)
  expect_identical(r_sh$pretrend$headline, "EHW")   # no cluster var set
  expect_equal(r_sh$pretrend$se, r_sh$pretrend$se_ehw)
  expect_output(print(r_sf$pretrend), "exposure-robust p is the one to read")
  expect_output(print(r_sh$pretrend), "reference only")
})

# ---- point 3: Sargan-Hansen replaces Cochran Q ------------------------------

test_that("point 3: ssb_overid is a Sargan-Hansen J with JEP estimators", {
  sim <- ssb_simulate(n_loc = 150, n_sec = 10, seed = 43)
  d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")

  o <- ssb_overid(d, estimator = "2sls")
  expect_s3_class(o, "ssb_overid")
  expect_null(o$Q)                                   # Cochran Q is gone
  expect_true(is.finite(o$J))
  # complete shares: K sectors -> K-1 independent instruments, df = K-2
  expect_identical(o$K, ncol(d$mat$S) - 1L)
  expect_identical(o$n_collinear, 1L)
  expect_identical(o$df, o$K - 1L)
  expect_true(o$p >= 0 && o$p <= 1)
  expect_output(print(o), "Sargan-Hansen")

  # all JEP estimators run and give finite estimates; efficient GMM stays
  # close to 2SLS (LIML / JIVE are legitimately noisy when every individual
  # instrument is weak -- that is exactly the many-weak-IV case they handle)
  fits <- lapply(c("gmm", "liml", "jive"),
                 function(es) ssb_overid(d, estimator = es))
  expect_true(all(vapply(fits, function(f) is.finite(f$beta) && is.finite(f$se),
                         logical(1))))
  expect_lt(abs(fits[[1]]$beta - o$beta), 0.5)
  # J comes from the efficient-GMM step, so it is common to all estimators
  expect_true(all(vapply(fits, function(f) isTRUE(all.equal(f$J, o$J)),
                         logical(1))))
  expect_message(ssb_overid(d), "resolved to")       # auto announces itself

  # under the null (valid instruments, homogeneous effect) J should not be
  # a wild rejection on a healthy simulated design
  expect_gt(ssb_overid(d, estimator = "2sls")$p, 1e-4)
})

# ---- point 4: share balance selects by |Rotemberg weight| -------------------

test_that("point 4: share balance tests the top-|alpha| shares", {
  sim <- ssb_simulate(n_loc = 100, n_sec = 10, seed = 44)
  d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
  rot <- ssb_rotemberg(d)
  sb  <- ssb_share_balance(d, covariates = "w1", top = 3)
  expect_true("alpha" %in% names(sb))
  expect_identical(unique(sb$sector), rot$sector[1:3])
  # ... and NOT the top-average-exposure sectors when those differ
  w <- ssBartik:::.ssb_w(d)
  imp <- colSums(w * d$mat$S) / sum(w)
  top_exposure <- d$mat$cell_sector[order(-imp)][1:3]
  if (!setequal(top_exposure, rot$sector[1:3]))
    expect_false(setequal(unique(sb$sector), top_exposure))
})

# ---- point 5: Rotemberg normalisation + terminology -------------------------

test_that("point 5: Rotemberg weights are normalisation-invariant when demeaned", {
  sim <- ssb_simulate(n_loc = 100, n_sec = 10, seed = 45)   # complete shares
  d0 <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "share")
  sh <- sim$shocks; sh$shock <- sh$shock + 7                # add a constant
  d1 <- ssb_design(sim$data, sim$shares, sh, exogenous = "share")

  r0 <- ssb_rotemberg(d0); r1 <- ssb_rotemberg(d1)
  expect_identical(attr(r0, "demeaned"), "overall")
  expect_equal(sum(r0$alpha), 1, tolerance = 1e-10)
  # invariance of the whole decomposition (weights AND per-instrument betas)
  m0 <- r0[order(r0$sector), c("alpha", "beta")]
  m1 <- r1[order(r1$sector), c("alpha", "beta")]
  expect_equal(m0, m1, tolerance = 1e-8, ignore_attr = TRUE)
  expect_equal(attr(r0, "beta_hat"), attr(r1, "beta_hat"), tolerance = 1e-10)

  # without demeaning the raw-shock weights DO move (the old, nonunique ones)
  raw0 <- ssb_rotemberg(d0, demean = FALSE)
  raw1 <- ssb_rotemberg(d1, demean = FALSE)
  expect_gt(max(abs(raw0$alpha[order(raw0$sector)] -
                    raw1$alpha[order(raw1$sector)])), 1e-4)

  # incomplete shares with a location-varying sum, share route (sum NOT
  # absorbed by the intercept or controls): demeaning is skipped
  shares_inc <- sim$shares
  fac <- 0.3 + 0.5 * shares_inc$location / max(shares_inc$location)
  shares_inc$share <- shares_inc$share * fac
  d_inc <- ssb_design(sim$data, shares_inc, sim$shocks, exogenous = "share")
  expect_message(r_inc <- ssb_rotemberg(d_inc), "NOT demeaned")
  expect_identical(attr(r_inc, "demeaned"), "none")

  # terminology: high-weight *share instruments*, not "shocks"
  expect_output(print(ssb_weight_summary(d0)), "share instruments")
})

# ---- point 6: panels control share-sum x period FE automatically ------------

test_that("point 6: shift-route panels interact the share sum with period FE", {
  pn <- .hull_panel(seed = 46)
  expect_message(
    d <- ssb_design(pn$data, pn$shares, pn$shocks, time = "time",
                    exogenous = "shift"),
    "interacted with period fixed effects")
  expect_identical(colnames(d$mat$auto_C),
                   c(".share_sum@1", ".share_sum@2"))

  # per-period constants added to the shocks are absorbed: beta AND the
  # exposure-robust SE are unchanged (fails if only the overall sum is
  # controlled, and fails with the raw-g scores of point 7)
  sh <- pn$shocks; sh$shock <- sh$shock + ifelse(sh$time == 1, 5, -3)
  suppressMessages({
    dc <- ssb_design(pn$data, pn$shares, sh, time = "time",
                     exogenous = "shift")
  })
  skip_if_not_installed("ShiftShareSE")
  e0 <- ssb_estimate(d,  methods = "akm")
  ec <- ssb_estimate(dc, methods = "akm")
  expect_equal(e0$estimate,   ec$estimate,   tolerance = 1e-8)
  expect_equal(e0$std.error,  ec$std.error,  tolerance = 1e-6)

  # the location / shock equivalence is exact in the panel
  eq <- ssb_equivalence(d)
  expect_lt(abs(eq$location - eq$shock), 1e-8)

  # user-supplied period FE do not break anything (auto columns get pruned)
  pn$data$per <- factor(pn$data$time)
  suppressMessages({
    d_fe <- ssb_design(pn$data, pn$shares, pn$shocks, time = "time",
                       controls = "per", exogenous = "shift")
  })
  e_fe <- ssb_estimate(d_fe, methods = "akm")
  expect_true(is.finite(e_fe$std.error))

  # .ssb_subset keeps cells, times and auto controls aligned
  d2 <- ssBartik:::.ssb_subset(d, seq_len(ncol(d$mat$S)) > 2)
  expect_identical(length(d2$mat$cell_time), ncol(d2$mat$S))
  expect_identical(ncol(d2$mat$auto_C), 2L)
})

# ---- point 7: exposure-robust scores use the residualised shocks ------------

test_that("point 7: shock-level SEs use g-tilde, matching a hand computation", {
  sim <- ssb_simulate(n_loc = 200, n_sec = 12, seed = 47)
  # give the shocks a nonzero exposure-weighted mean so raw g and g-tilde differ
  sim$shocks$shock <- sim$shocks$shock + 0.8
  d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")

  s_iv <- ssb_shock_iv(d)
  agg <- ssb_aggregate(d)
  s <- agg$s_bar
  rz <- function(v) stats::lm.wfit(matrix(1, length(v), 1), v, s)$residuals
  gt <- rz(agg$g); xt <- rz(agg$x_bar); yt <- rz(agg$y_bar)
  den <- sum(s * gt * xt); b <- sum(s * gt * yt) / den
  K <- length(gt)
  se_hand <- sqrt(sum((s * gt * (yt - b * xt))^2) * K / (K - 2)) / abs(den)
  expect_equal(s_iv$estimate,  b,       tolerance = 1e-10)
  expect_equal(s_iv$std.error, se_hand, tolerance = 1e-10)

  # regression: on a complete design, adding a constant to every shock must
  # leave all exposure-robust SEs unchanged (raw-g scores fail this)
  sh <- sim$shocks; sh$shock <- sh$shock + 4
  dc <- ssb_design(sim$data, sim$shares, sh, exogenous = "shift")
  expect_equal(ssb_shock_iv(dc)$std.error, s_iv$std.error, tolerance = 1e-8)

  f0 <- ssb_first_stage(d); f1 <- ssb_first_stage(dc)
  expect_equal(f0$F_effective, f1$F_effective, tolerance = 1e-6)

  sim$data$y_pre <- stats::rnorm(nrow(sim$data))
  d_p  <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
  dc_p <- ssb_design(sim$data, sim$shares, sh, exogenous = "shift")
  expect_equal(ssb_pretrend(d_p, "y_pre")$se_akm,
               ssb_pretrend(dc_p, "y_pre")$se_akm, tolerance = 1e-6)
})

# ---- point 8: shock_cluster genuinely clusters the shocks -------------------

test_that("point 8: shock_cluster reaches the AKM variance and matches hand clustering", {
  skip_if_not_installed("ShiftShareSE")
  set.seed(48)
  sim <- ssb_simulate(n_loc = 300, n_sec = 24, seed = 48)
  grp <- rep(1:6, each = 4)
  sim$shocks$shock <- stats::rnorm(6)[grp] + 0.3 * stats::rnorm(24)
  sim$shocks$grp <- grp
  Z <- tapply(sim$shares$share, list(sim$shares$location, sim$shares$sector), sum)
  Z[is.na(Z)] <- 0
  inst <- as.numeric(Z %*% sim$shocks$shock)
  sim$data$x <- 0.9 * inst + stats::rnorm(nrow(sim$data))
  sim$data$y <- 1.2 * sim$data$x + stats::rnorm(nrow(sim$data))
  d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")

  e_iid <- ssb_estimate(d, methods = "akm")
  e_cl  <- ssb_estimate(d, methods = "akm", shock_cluster = "grp")
  expect_false(isTRUE(all.equal(e_iid$std.error, e_cl$std.error)))

  # ShiftShareSE's sector_cvar equals hand-rolled clustered shock-level scores
  agg <- ssb_aggregate(d); s <- agg$s_bar
  rz <- function(v) stats::lm.wfit(matrix(1, length(v), 1), v, s)$residuals
  gt <- rz(agg$g); xt <- rz(agg$x_bar); yt <- rz(agg$y_bar)
  den <- sum(s * gt * xt); b <- sum(s * gt * yt) / den
  ug <- tapply(s * gt * (yt - b * xt), grp, sum)
  expect_equal(e_cl$std.error, sqrt(sum(ug^2)) / abs(den), tolerance = 1e-6)

  # ssb_shock_iv accepts a shocks-table column for the same clustering
  s_cl <- ssb_shock_iv(d, cluster = "grp")
  G <- length(unique(grp))
  expect_equal(s_cl$std.error,
               sqrt(sum(ug^2) * G / (G - 1)) / abs(den), tolerance = 1e-6)
})

# ---- point 9: RI documents its exchangeability assumption -------------------

test_that("point 9: randomization inference flags exchangeability", {
  sim <- ssb_simulate(n_loc = 60, n_sec = 6, seed = 49)
  d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
  ri <- ssb_ri(d, R = 30)
  expect_output(print(ri), "EXCHANGEABLE")
  expect_output(print(ri), "stronger")
})

# ---- point 10: shock-balance language is calibrated -------------------------

test_that("point 10: non-rejection is not reported as proof of balance", {
  sim <- ssb_simulate(n_loc = 90, n_sec = 8, seed = 50)
  d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
  scov <- data.frame(sector = sort(unique(sim$shocks$sector)),
                     size = stats::rnorm(length(unique(sim$shocks$sector))))
  sb <- ssb_shock_balance(d, scov)
  expect_output(print(sb), "NOT rejected")
  expect_output(print(sb), "does not establish")
  txt <- paste(utils::capture.output(print(sb)), collapse = " ")
  expect_false(grepl("shocks unrelated to observed characteristics", txt))
})
