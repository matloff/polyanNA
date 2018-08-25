
#########################  polyanNA  ##################################

# assumption-free missing value method, for a prediction context

# the goal is to have polyanNA() run on both the training data and new
# data; some of the arguments have different meanings in the two cases

# typical usage: apply polyanNA() to training data; then run lm() or
# whatever; then run polyanNA() on the new data and feed the result into
# predict.pa1()

# arguments:

#    xy: input data frame, X and Y in training case, only X in 
#        new data (prediction) case
#    yCol: column number of Y, training case
#    breaks: if non-NULL, number of desired levels in the discretized 
#       vector (not counting 'na')
#    allCodeInfo: in the new-data case, an R list, one element for each
#       column of X; the element is NULL unless that column had been
#       discretized in the original, in which it is the codeInfo
#       attribute from that operation 

# we'll use x here to refer to xy without the Y column, if any

# if breaks is non_NULL, then the numeric columns are run through #
# 'discretize', and converted to factors 

# then for each column in x that is a factor and has at least one NA
# value, add an 'na' level and recode the NA values to that level; that
# way, one can account for the potential predictive information that an
# NA value may convey

# to account for multiple interactions between NAs etc., run the result
# through polyreg

polyanNA <- function(xy,yCol=NULL,breaks=NULL,allCodeInfo=NULL) 
{
   newdata <- is.null(yCol)
   x <- if (newdata) xy else xy[,-yCol,drop=FALSE] 
   if (newdata) {
      # assert proper inputs
      stopifnot(is.null(breaks) && !is.null(allCodeInfo))
   } else { # training case
      allCodeInfo <- list(length = ncol(x))
      for (i in 1:ncol(x)) 
         allCodeInfo[[i]] <- 'no code info'
   }
   # any columns need to be discretized?
   needDisc <- !is.null(breaks) || any(allCodeInfo != 'no code info')
   if (needDisc) {
      for (i in 1:ncol(x)) {
         if (!newdata && is.numeric(x[,i]) || 
                allCodeInfo[[i]] != 'no code info') {
            # discretize and make it a factor
            codeInfo <- 
               if (newdata) allCodeInfo[[i]] else NULL
            nLevels <- if (newdata) NULL else breaks
            tmp <- discretize(x[,i],nLevels,codeInfo)
            x[,i] <- tmp$xDisc
            allCodeInfo[[i]] <- tmp$codeInfo
         }
      }
   }
   # which columns have NAs and need to be converted?
   naByCol <- apply(x,2,function(col) any(is.na(col)))
   for (i in 1:ncol(x)) {
      if (naByCol[i]) {  # any NAs in this col?
         nm <- names(x)[i]
         if (is.factor(x[,i])) x[,i] <- addNAlvl(x[,i],nm) 
      }
   }
   if (!newdata) xy[,-yCol] <- x else xy <- x
   val <- list(xy=xy, allCodeInfo=allCodeInfo)
   class(val) <- 'pa'
   val
}

#########################  addNAlvl  ##################################

# if factor f has any NAs, add a new level to the factor, 'na', and
# replace any NAs by this level

addNAlvl <- function(f,nm)
{
   f1 <- as.character(f)
   # f1[is.na(f1)] <- paste0(nm,'.na')
   f1[is.na(f1)] <- paste0(nm,'.na')
   as.factor(f1)
}

########################  discretize  ##################################

# converts a numeric variable x to a factor with nLevels levels; divides
# range(x) into nLevels equal-width intervals, and codes accordingly; if
# new X for prediction, then use the pre-existing levels information,
# encoded as an attribute,

# arguments:

# x: a numeric vector
# nLevels: if x is in training set, the number of desired intervals;
#          NULL if new X
# codeInfo:  information on subintervls; NULL if training set; for new
#            obtain from training set, produced by original call to
#            discretize() on this column

# value: an R list: xDisc, a factor, coded accordingly the the
#        intervals, and codeInfo (training case), the information on the
#        discretization

discretize <- function(x,nLevels=NULL,codeInfo=NULL) {
   newdata <- is.null(nLevels)
   if (!newdata) {  # x is training data, not new x
      # intervals based on dividing range of x into equal-width subintervls
      rng <- range(x,na.rm=T); xmn <- rng[1]; xmx <- rng[2]
      increm <- (xmx - xmn) / nLevels
      xDisc <- round((x - xmn) / increm)  # discretized x
      # later, when do prediction, will need to know the range of codes
      # in xDisc
      xdu <- unique(xDisc)
      xdu <- xdu[!is.na(xdu)]
      codeMin <- min(xdu)
      codeMax <- max(xdu)
      # record so can discretize future x, consistently with this one
      codeInfo <- list(xmn=xmn,increm=increm,breaks=nLevels,
         codeMin=codeMin,codeMax=codeMax)
      xDisc <- as.factor(xDisc)
   } else {  # new data case
      xmn <- codeInfo$xmn
      increm <- codeInfo$increm
      nLevels <- codeInfo$nLevels
      codeMin <- codeInfo$codeMin
      codeMax <- codeInfo$codeMax
      xDisc <- round((x - xmn) / increm)
      xDisc <- pmax(xDisc,codeMin)
      xDisc <- pmin(xDisc,codeMax)
      xDisc <- as.character(xDisc)
      xDisc <- as.factor(xDisc)
   }
   list(xDisc=xDisc,codeInfo=codeInfo)
}

test <- function() 
{
   ans <- factor(c('yes','no','maybe',NA,'yes','maybe'))
   ht <- c(62,NA,68,72,68,71)
   clr <- factor(c('R','R','G','B','B','B'))
   y <- runif(6)
   d <- data.frame(ans,ht,clr,y)
   d1 <- polyanNA(d,yCol=4,breaks=2)
   newx <- data.frame(ans=c('no',NA,'yes'),
                      ht=c(NA,70,75),clr=c('G','G','R'))
   polyanNA(newx,allCodeInfo=d1$allCodeInfo)
browser()
   d1lm <- lm.pa(d1)
   predict(d1lm,newx)
}

# ********************     cpWithAttrr    ##################################

# R attributes do NOT get copied upon assignment, so need this

require(gtools)
cpWithAttr <- defmacro(x,y,xattr,expr={y <- x; attr(y,xattr) <- attr(x,xattr)})

####################    lm.pa(), predict.lm.pa()    #########################

# does usual lm() but on data with 'na' values

# arguments:

#    paout: object of class'pa', output of polyanNA()
#    maxDeg, maxInteractDeg: as in polyFit

lm.pa <- function(paout,maxDeg=1,maxInteractDeg=1) {
   # some columns may not have been "de-NAed", so need to use only
   # complete cases
   xy <- paout$xy
   xy <- xy[complete.cases(xy),]
   frml <- names(xy)[ncol(xy)]
   frml <- paste0(frml,' ~ .')
   frml <- as.formula(frml)
   lmout <- lm(frml,data=xy)
   # set up return value; note that allCodeInfo is needed for prediction
   val <- list(lmout=lmout,maxDeg=maxDeg,maxInteractDeg=maxInteractDeg,
      allCodeInfo=paout$allCodeInfo)
   class(val) <- 'lm.pa'
   val
}

# predicts Ys for newdata from lmpa, an object of class 'lm.pa' from lm.pa()

predict.lm.pa <- function(lmpa,newx) {
   # convert newx
   newx <- polyanNA(newx,allCodeInfo=lmpa$allCodeInfo)
   predict(lmpa$lmout,newx$xy)
}


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
