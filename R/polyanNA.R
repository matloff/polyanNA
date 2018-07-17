
# assumption-free missing value method, for a prediction context

# for each column in the input data frame that is a factor and has at
# least one NA value, add an 'na' level and recode the NA values to that
# level; then fit the regression model; that way, one can account for
# the potential predictive information that an NA value may convey

# to account for multiple interactions, run the result through polyreg

polyanNA <- function(x) 
{
   naByCol <- apply(x,2,function(col) any(is.na(col)))
   for (i in 1:ncol(x)) {
      nm <- names(x)[i]
      if (is.factor(x[,1])) x[,i] <- addNAlvl(x[,i],nm)
   }
   x
}

addNAlvl <- function(f,nm) 
{
   f1 <- as.character(f,nm)
   f1[is.na(f1)] <- paste0(nm,'.na')
   as.factor(f1)
}

# example

#  > d <- data.frame(ans=factor(c('yes','no','maybe',NA,'yes','maybe')))
#  > d$clr <- factor(c(NA,'R','G','B','B',NA))
#  > d
#      ans  clr
#  1   yes <NA>
#  2    no    R
#  3 maybe    G
#  4  <NA>    B
#  5   yes    B
#  6 maybe <NA>
#  > dNoNA <- polyanNA(d)
#  > dNoNA
#       ans    clr
#  1    yes clr.na
#  2     no      R
#  3  maybe      G
#  4 ans.na      B
#  5    yes      B
#  6  maybe clr.na

