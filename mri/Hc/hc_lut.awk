(/^(226|231|232|700[0-9]|7010|7015) /){
   print $1,"left-"$2;print $1+500,"right-"$2
}
END{print 0,"unassigned"}
