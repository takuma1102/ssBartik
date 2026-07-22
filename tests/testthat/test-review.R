# Tests pinning down the behaviour fixed in the methodological review.

test_that("ssb_ri uses the AR reduced-form statistic and reports the IV estimate alongside", {
  sim <- ssb_simulate(n_loc = 200, n_sec = 12, beta = 1.2, seed = 101)
  d <- ssb_design(sim$data, sim$shares, sim$shocks, weights = "pop",
                  exogenous = "shift")

  ri <- ssb_ri(d, R = 199, seed = 1)
  expect_null(ri[["stat"]])                  # no stat switch any more
  expect_true(is.finite(ri$statistic))
  expect_true(ri$p_value > 0 && ri$p_value <= 1)
  # beta is still the IV point estimate, reported alongside the AR statistic
  expect_equal(ri$beta, ssb_estimate(d, methods = "ehw")$estimate[1],
               tolerance = 1e-10)
  # the AR statistic is not the IV ratio
  expect_false(isTRUE(all.equal(ri$statistic, ri$beta)))
})

test_that("AR-style RI: the statistic at null = beta_hat is (numerically) zero", {
  sim <- ssb_simulate(n_loc = 150, n_sec = 10, seed = 102)
  d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
  bh <- ssb_estimate(d, methods = "ehw")$estimate[1]
  ri <- ssb_ri(d, R = 49, null = bh, seed = 2)
  # y - beta_hat * x is orthogonal to the residualised instrument by construction
  expect_lt(abs(ri$statistic), 1e-8)
})

test_that("ssb_pretrend reports an exposure-robust (AKM) SE", {
  sim <- ssb_simulate(n_loc = 200, n_sec = 12, seed = 103)
  sim$data$y_pre <- stats::rnorm(nrow(sim$data))
  d <- ssb_design(sim$data, sim$shares, sim$shocks, weights = "pop",
                  exogenous = "shift")
  pt <- ssb_pretrend(d, pre_y = "y_pre")
  expect_true(is.finite(pt$se_akm) && pt$se_akm > 0)
  expect_true(is.finite(pt$p_akm))
  expect_equal(pt$conf.low_akm, pt$coef - stats::qnorm(0.975) * pt$se_akm,
               tolerance = 1e-12)
})

test_that("permute recentering subtracts the simple within-block mean shock", {
  sim <- ssb_simulate(n_loc = 120, n_sec = 12, seed = 104)
  sim$shocks$grp <- rep(1:3, length.out = nrow(sim$shocks))
  d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
  d2 <- ssb_recenter(d, method = "permute", block = "grp")
  bm <- attr(d2, "recentered")$block_means
  expect_equal(as.numeric(bm[as.character(1:3)]),
               as.numeric(tapply(sim$shocks$shock, sim$shocks$grp, mean)),
               tolerance = 1e-12)
  # recentered shocks average to zero within each block
  gc <- d2$shocks$shock
  expect_equal(unname(as.numeric(tapply(gc, sim$shocks$grp, mean))),
               rep(0, 3), tolerance = 1e-12)
})

test_that("factor controls are expanded into dummies (fixed effects)", {
  sim <- ssb_simulate(n_loc = 120, n_sec = 10, seed = 105)
  sim$data$fe <- factor(rep(letters[1:4], length.out = nrow(sim$data)))
  d <- ssb_design(sim$data, sim$shares, sim$shocks,
                  controls = c("w1", "fe"), weights = "pop",
                  exogenous = "share")
  est <- ssb_estimate(d, methods = "ehw")
  expect_true(is.finite(est$estimate[1]))

  # equals the estimate with hand-built dummies
  mm <- stats::model.matrix(~ fe, data = sim$data)[, -1]
  d2dat <- cbind(sim$data, as.data.frame(mm))
  d2 <- ssb_design(d2dat, sim$shares, sim$shocks,
                   controls = c("w1", colnames(mm)), weights = "pop",
                   exogenous = "share")
  est2 <- ssb_estimate(d2, methods = "ehw")
  expect_equal(est$estimate[1], est2$estimate[1], tolerance = 1e-10)
  expect_equal(est$std.error[1], est2$std.error[1], tolerance = 1e-10)
})

test_that("loo and drop_top agree on incomplete-share shift designs", {
  sim <- ssb_simulate(n_loc = 150, n_sec = 10, incomplete = TRUE, seed = 106)
  d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
  expect_false(d$mat$complete)
  loo <- ssb_loo(d, top = 1)
  dt  <- ssb_drop_top(d, n = 1, methods = "ehw")
  expect_equal(loo$beta_drop[1], dt$reduced$estimate[1], tolerance = 1e-10)
})

test_that("disjoint confidence sets render as complements, not reversed intervals", {
  est <- data.frame(method = c("ehw", "akm0"),
                    estimate = c(1.0, 1.0), std.error = c(0.2, Inf),
                    conf.low = c(0.6, 2.5), conf.high = c(1.4, -0.5),
                    note = c("", "disjoint CI: (-Inf, -0.5] U [2.5, Inf)"),
                    stringsAsFactors = FALSE)
  attr(est, "level") <- 0.95
  attr(est, "fstat") <- 1.3
  class(est) <- c("ssb_estimate", "data.frame")
  md <- format(est, "markdown")
  expect_true(any(grepl("(-Inf, -0.500] U [2.500, Inf)", md, fixed = TRUE)))
  tex <- format(est, "latex")
  expect_true(any(grepl("\\cup", tex, fixed = TRUE)))
})

test_that("ssb_design requires the identification route", {
  sim <- ssb_simulate(n_loc = 40, n_sec = 5, seed = 107)
  expect_error(ssb_design(sim$data, sim$shares, sim$shocks),
               "exogenous")
  expect_error(ssbartik(sim$data, sim$shares, sim$shocks),
               "exogenous")
  expect_silent(ssb_design(sim$data, sim$shares, sim$shocks,
                           exogenous = "shift"))
})
