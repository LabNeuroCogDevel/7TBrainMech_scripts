source('get_data.R')
source('funcs.R')
library(testthat)

context('Functions')
test_that("filter data", {
  # minimal dataframe for testing filter
  d <- data.frame(id=c(1,2),
          GPC.Cho.SD=1,
          NAA.NAAG.SD=1,
          Cr.SD=1,
          MM20.Cr=1)

  # nothing discarded
  expect_equal(remove_metabolite_thresh(d)$id,
               c(1,2))
    
  # bad GCP value in second removes it
  d_CPG <- d
  d_CPG$GPC.Cho.SD[2] <- 10.1
  expect_equal(remove_metabolite_thresh(d_CPG)$id,
               c(1))

  # MM20.Cr has lower cutoff
  d_MM <- d
  d_MM$MM20.Cr[2] <- 3.1
  expect_equal(remove_metabolite_thresh(d_MM)$id,
               c(1))

  # NA is kept
  # TODO: is this intended?
  d_NA <- d
  d_NA$GPC.Cho.SD[2] <- NA
  expect_equal(remove_metabolite_thresh(d_NA)$id,
               c(1, 2))

})
