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

test_that("share rows matching no shock cell are dropped without corrupting z", {
  sim <- ssb_simulate(n_loc = 50, n_sec = 6, seed = 11)
  extra <- data.frame(location = 1L, sector = 999L, share = 0.5)
  expect_warning(
    d2 <- ssb_design(sim$data, rbind(sim$shares, extra), sim$shocks,
                     exogenous = "shift"),
    "matched no unit"
  )
  d1 <- ssb_design(sim$data, sim$shares, sim$shocks, exogenous = "shift")
  expect_equal(d2$mat$z, d1$mat$z)
})

test_that("duplicated (location, sector) share rows are summed with a warning", {
  sim <- ssb_simulate(n_loc = 50, n_sec = 6, seed = 12)
  shares2 <- rbind(sim$shares, sim$shares[1, ])
  expect_warning(d <- ssb_design(sim$data, shares2, sim$shocks), "summed")
  i <- sim$shares$location[1]; k <- sim$shares$sector[1]
  expect_equal(d$mat$S[i, as.character(k)], 2 * sim$shares$share[1])
})

test_that("ssb_design validates the shares and shocks tables", {
  sim <- ssb_simulate(seed = 13)
  expect_error(
    ssb_design(sim$data, sim$shares[c("location", "sector")], sim$shocks),
    "shares"
  )
  expect_error(
    ssb_design(sim$data, sim$shares, rbind(sim$shocks, sim$shocks[1, ])),
    "one row per sector"
  )
})

test_that("ssb_estimate rejects unknown SE methods", {
  sim <- ssb_simulate(n_loc = 50, n_sec = 6, seed = 14)
  d <- ssb_design(sim$data, sim$shares, sim$shocks)
  expect_error(ssb_estimate(d, methods = "bootstrap"), "unknown")
  expect_silent(ssb_estimate(d, methods = "EHW"))   # case-insensitive
})

test_that("share_col / shock_col allow non-default column names", {
  sim <- ssb_simulate(n_loc = 80, n_sec = 8, seed = 21)
  shares2 <- sim$shares; names(shares2)[names(shares2) == "share"] <- "w_in"
  shocks2 <- sim$shocks; names(shocks2)[names(shocks2) == "shock"] <- "g_n"

  d0 <- ssb_design(sim$data, sim$shares, sim$shocks, weights = "pop")
  d1 <- ssb_design(sim$data, shares2, shocks2, weights = "pop",
                   share_col = "w_in", shock_col = "g_n")
  expect_equal(d0$mat$z, d1$mat$z)
  expect_equal(d0$mat$g, d1$mat$g)

  # recentering must write back to the renamed shock column and stay consistent
  b0 <- ssb_estimate(ssb_recenter(d0), methods = "ehw")$estimate[1]
  b1 <- ssb_estimate(ssb_recenter(d1), methods = "ehw")$estimate[1]
  expect_equal(b0, b1, tolerance = 1e-10)
})

test_that("EHW SE grows when controls consume degrees of freedom", {
  # with k controls the finite-sample factor is n/(n-k-1) > n/(n-1), so the
  # control-aware EHW SE must be (weakly) larger than the naive n/(n-1) version.
  sim <- ssb_simulate(n_loc = 40, n_sec = 6, seed = 22)
  sim$data$w2 <- stats::rnorm(nrow(sim$data))
  d <- ssb_design(sim$data, sim$shares, sim$shocks,
                  controls = c("w1", "w2"), weights = "pop", exogenous = "share")
  se <- ssb_estimate(d, methods = "ehw")$std.error[1]
  # reconstruct the old n/(n-1) SE by hand and confirm the reported one exceeds it
  w <- sim$data$pop
  C <- as.matrix(sim$data[, c("w1", "w2")])
  ry <- lm.wfit(cbind(1, C), sim$data$y, w)$residuals
  rx <- lm.wfit(cbind(1, C), sim$data$x, w)$residuals
  rz <- lm.wfit(cbind(1, C), d$mat$z,    w)$residuals
  zx <- sum(w * rz * rx); beta <- sum(w * rz * ry) / zx
  e <- ry - beta * rx; n <- length(ry)
  se_old <- sqrt(sum((w * rz * e)^2) * n / (n - 1)) / abs(zx)
  expect_gt(se, se_old)
})
