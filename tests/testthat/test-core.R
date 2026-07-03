test_that("Rotemberg weights sum to one and match the 2SLS estimate", {
  sim <- ssb_simulate(n_loc = 300, n_sec = 20, beta = 1.2, seed = 42)
  d <- ssb_design(sim$data, sim$shares, sim$shocks,
                  controls = "w1", weights = "pop", exogenous = "share")
  rot <- ssb_rotemberg(d)
  expect_equal(sum(rot$alpha), 1, tolerance = 1e-8)

  est <- ssb_estimate(d, methods = "ehw")
  # FWL identity: the Rotemberg beta_hat equals the 2SLS point estimate
  expect_equal(attr(rot, "beta_hat"), est$estimate[1], tolerance = 1e-8)
})

test_that("point estimate recovers the truth in a clean simulation", {
  sim <- ssb_simulate(n_loc = 2000, n_sec = 30, beta = 1.2, endog = 0.6, seed = 1)
  d <- ssb_design(sim$data, sim$shares, sim$shocks, weights = "pop",
                  exogenous = "shift")
  est <- ssb_estimate(d, methods = "ehw")
  expect_equal(est$estimate[1], 1.2, tolerance = 0.1)
})

test_that("recentering (demean) leaves the point estimate unchanged", {
  sim <- ssb_simulate(seed = 3)
  d <- ssb_design(sim$data, sim$shares, sim$shocks, weights = "pop")
  b0 <- ssb_estimate(d, methods = "ehw")$estimate[1]
  b1 <- ssb_estimate(ssb_recenter(d), methods = "ehw")$estimate[1]
  expect_equal(b0, b1, tolerance = 1e-8)
})

test_that("incomplete shares trigger the sum-of-shares control on the shift route", {
  sim <- ssb_simulate(incomplete = TRUE, seed = 7)
  d <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
  expect_false(d$mat$complete)
  expect_silent(ssb_estimate(d, methods = "ehw"))
})
