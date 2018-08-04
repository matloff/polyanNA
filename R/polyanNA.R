
#########################  polyanNA  ####################################

# assumption-free missing value method, for a prediction context

# for each column in the input data frame that is a factor and has at
# least one NA value, add an 'na' level and recode the NA values to that
# level; then fit the regression model; that way, one can account for
# the potential predictive information that an NA value may convey

# if dtz option, then the numeric columns are run through
# 'discretize' from the 'arules' package

# to account for multiple interactions, run the result through polyreg

polyanNA <- function(x,dtz=FALSE,breaks=3) 
{
   if (dtz) require(discretize)
   naByCol <- apply(x,2,function(col) any(is.na(col)))
   for (i in 1:ncol(x)) {
      if (naByCol[i]) {  # any NAs in this col?
         if (dtz)  
            xi <- discretize(x[,i],infinity=TRUE,breaks=breaks)
         nm <- names(x)[i]
         if (dtz || is.factor(x[,i])) 
            x[,i] <- addNAlvl(x[,i],nm) 
      }
   }
   x
}

addNAlvl <- function(f,nm) 
{
   f1 <- as.character(f)
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
