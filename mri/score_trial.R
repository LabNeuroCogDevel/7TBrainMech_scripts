
# mgs_recall.py -- but not for all subjects
# ---- scores ----
# -- didn't see  
# 1   = said saw (but didn't)
# 101 = said maybe didn't
# 201 = confidently correct
# --- did see
# 0 = said didn't
# 100 = maybe known
# 200 = confidently correct
# -- choose correct side
# +5  = correct side    (105, 205)
# +15 = exactly correct (115,215)

get_key_known <- function(key) ifelse(key %in% c(1, 2), "K",
                                 ifelse(key %in% c(9, 0), "U", "WTF"))
get_key_side <- function(key) ifelse(key %in% c(1, 2), "L",
                                 ifelse(key %in% c(9, 0), "R", "U"))
# input: known correct, pushed, direction correct, pushed
score_keys <- function(kc, kp, dc, dp) {
   score<-0
   # actually uknown (unseen)
   if ( get_key_known(kc) == "U" ) {
      if ( get_key_known(kp) == "K" )  return(1)
      # more certian, more points
      else if ( kp == 9 ) score <- 101
      else if ( kp == 0 ) score <- 201
      else return(NA)
   } else {
      # did actually see
      #   but said do not know
      if ( get_key_known(kp) != "K" )  return(0)
      # more certian, more points
      else if ( kp == 1 ) score <- 200
      else if ( kp == 2 ) score <- 100
      else return(Inf) # said 0 or 9 -- didn't know, but did actually see
      # add points for correct side
      if ( get_key_side(dc) == get_key_side(dp) ) {
         score <- score + 5
      }
      if ( !is.na(dp) &&  dc == dp ) {
         score <- score + 10
      }
   }
   return(score)
}
