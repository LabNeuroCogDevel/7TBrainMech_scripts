d <- read.csv('../../../txt/13MP20200207_LCMv2fixidx.csv')
# tests will assume roi 1 Glu is invage

# make sure we read in the data
# otherwise other tests will fail in weird ways
test_that("read data", {
  expect_gt(nrow(d),100)
})

# culmination of everything
test_that("can plot", {
  mrsi_plot_many(d, 1, list(Glu.Cr='Glu.SD', GABA.Cr="GABA.SD"))
})

test_that("clean", {
  clean <- mrsi_clean(d, 1, 'Glu.SD')
  # not empty
  expect_gt(nrow(clean), 1)
  # did something
  expect_lt(nrow(clean), nrow(d))
  # only one region
  expect_true(all(clean$roi==1))

  clean <- mrsi_clean(d, c(3, 5), 'Glu.SD')
  expect_equal(sort(unique(clean$roi)), c(3, 5))
})

test_that("model: lm", {
  clean <- mrsi_clean(d, 1, 'Glu.SD')
  m <- mrsi_bestmodel(clean, 'Glu.Cr')
  expect_s3_class(m, 'lm')
})

test_that("model: lmer", {
  clean <- mrsi_clean(d, c(1,2), 'Glu.SD')
  m <- mrsi_bestmodel(clean, 'Glu.Cr')
  expect_s4_class(m, 'lmerMod')
})
test_that("model: lm is invage", {
  clean <- mrsi_clean(d, 1, 'Glu.SD')
  m <- mrsi_bestmodel(clean, 'Glu.Cr')
  agefit <- what_age_y(summary(m)$coef)
  expect_equal(agefit, "invage")
})

test_that("fit", {
  clean <- mrsi_clean(d, 1, "Glu.SD")
  m <- mrsi_bestmodel(clean, "Glu.Cr")
  f <- mrsi_fitdf(m)
  expect_true(all(c("prediction", "age") %in% names(f)))
  expect_equal(f$bestfit[1], "invage")
  expect_equal(f$metabolite[1], "Glu.Cr")
  expect_equal(min(f$age), min(clean$age), tolerance=0.1)
  expect_equal(max(f$age), max(clean$age), tolerance=0.1)
})
