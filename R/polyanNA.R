
#########################  polyanNA  ##################################

# assumption-free missing value method, for a prediction context

# the goal is to have polyanNA() run on both the training data and new
# data; some of the arguments have different meanings in the two cases

# arguments:

#    xy: input data, X and Y in training case, only X in new data case
#    yCol: column number of Y, training case
#    dtz: discretize the numeric variables
#    breaks:

# the input data frame xy has Y in column yCol; we'll use x to refer to
# xy without that column

# for each column in x that is a factor and has at least one NA value,
# add an 'na' level and recode the NA values to that level; then fit the
# regression model; that way, one can account for the potential
# predictive information that an NA value may convey

# if dtz option, then the numeric columns are run through
# 'discretize' 

# the latter case is specified via yCol = NULL, and then the
# 'ranges' argument must be non-NULL; it will be a list, with first
# component being the 

# the argument 'ranges', if non-NULL, 

# to account for multiple interactions, run the result through polyreg

polyanNA <- function(xy,yCol,dtz=FALSE,breaks=5,ranges=NULL) 
{
   x <- xy[,-yCol]
   for (i in 1:ncol(x)) {
      if (is.numeric(x[,i]) && dtz)  
         x[,i] <- discretize(x[,i],nLevels=breaks)
   }
   naByCol <- apply(x,2,function(col) any(is.na(col)))
   for (i in 1:ncol(x)) {
      if (naByCol[i]) {  # any NAs in this col?
         if (is.factor(x[,i])) x[,i] <- addNAlvl(x[,i]) 
      }
   }
   xy[,-yCol] <- x
   xy
}

#########################  addNAlvl  ##################################

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
#  > dNoNA <- polyanNA(d)
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
