
#########################  polyanNA  ##################################

# assumption-free missing value method, for a prediction context

# the goal is to have polyanNA() run on both the training data and new
# data; some of the arguments have different meanings in the two cases

# typical usage: apply polyanNA() to training data; then run rm() or
# whatever; then run polyanNA() on the new data and feed the result into
# predict.pa1()

# arguments:

#    xy: input data, X and Y in training case, only X in new data case
#    yCol: column number of Y, training case
#    dtz: discretize the numeric variables
#    breaks: if dtz, number of desired levels in the discretized vector
#       (not counting 'na')
#    ranges: in the new-data case, 2 x nX matrix, where nX is the number
#       of X variables; i-th column contains min, max for Xi; picked up
#       from output of polyanNA() on the training data

# we'll use x here to refer to xy without the Y column, if any

# if dtz , then the numeric columns are run through
# 'discretize', converted to factors 

# then for each column in x that is a factor and has at least one NA
# value, add an 'na' level and recode the NA values to that level; that
# way, one can account for the potential predictive information that an
# NA value may convey

# to account for multiple interactions between Ns etc., run the result
# through polyreg

polyanNA <- function(xy,yCol,dtz=FALSE,breaks=5,ranges=NULL) 
{
   if (!is.null(yCol)) x <- xy[,-yCol] else x <- xy
   if (dtz) {
      for (i in 1:ncol(x)) {
         if (is.numeric(x[,i]))  
            x[,i] <- discretize(x[,i],nLevels=breaks)
      }
   }
   # which columns have NAs?
   naByCol <- apply(x,2,function(col) any(is.na(col)))
   for (i in 1:ncol(x)) {
      if (naByCol[i]) {  # any NAs in this col?
         if (is.factor(x[,i])) x[,i] <- addNAlvl(x[,i]) 
      }
   }
   if (!is.null(yCol)) xy[,-yCol] <- x else xy <- x
   xy
}

#########################  addNAlvl  ##################################

# if factor f has any NAs, add a new level to the factor, 'na', and
# replace any NAs by this level

addNAlvl <- function(f) 
{
   f1 <- as.character(f)
   # f1[is.na(f1)] <- paste0(nm,'.na')
   f1[is.na(f1)] <- '.na'
   as.factor(f1)
}

########################  discretize  ##################################

# converts a numeric variable x to a factor with nLevels levels; divides
# range(x) into equal-width intervals, closed on the right, open on the
# left; the names of the levels are the right endpoints of the
# intervals, including the last, which is named 'Inf'

discretize <- function(x,nLevels) {
   xc <- cut(x,nLevels)
   lxc <- levels(xc)
   commaPts <- regexpr(',',lxc)
   bracketPts <- nchar(lxc)
   for (i in 1:(length(lxc)-1) ) 
      levels(xc)[i] <- 
         substr(lxc[i],commaPts[i]+1,bracketPts[i]-1)
   levels(xc)[length(lxc)] <- 'Inf'
   xc
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
#  > dNoNA <- polyanNA(d,NULL)
#  > dNoNA
#       ans    clr
#  1    yes clr.na
#  2     no      R
#  3  maybe      G
#  4 ans.na      B
#  5    yes      B
#  6  maybe clr.na

### ###########################  lm.marg  ####################################
### 
### # fit linear regression model to data xy, using only
### # complete cases
### 
### # arguments:
### 
### #    xy: input data frame
### #    frml: formula for lm() call; quoted string
### 
### # value:
### 
### # object of S3 class, with components:
### # 
### #    lmout: return value of the call to lm() on the complete cases
### #    ccNums: enumeration of the indices in xy of the complete cases
### 
### lm.marg <- function(xy,regModel='linear') {
###    ccNums <- complete.cases(xy)
###    if (sum(ccNums) == nrow(xy) 
###       stop('no complete cases')
###    xy.cc <- xy[ccNums,]
###    lmout <- lm(as.formula(frml),data=xy.cc)
###    res <- list(lmout=lmout,ccNums=ccNums)
###    class(res) <- 'lm.marg')
### }
### 
### #######################  predict.lm.marg  #################################
### 
### # arguments:
###  
### #    lmMargObj:  object of class 'lm.marg', output of lm.marg()
### #    newx:  data frame with same column names as xy above (without Y);
### #           for now, just one row
###  
### # value:  predicted value
### 
### predict.lm.marg <- function(lmMargObj,newx) {
###    whichNA <- which(is.na(newx))
###    if (sum(whichNA) == length(newx)) {
###       warning('failed prediction, as all data are NA')
###       return(NA)
###    }
###       
### }
