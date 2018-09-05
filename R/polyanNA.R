
#########################  polyanNA  ##################################

# implements generalization of the Missing-Indicator Method

# the goal is to have polyanNA() run on both the training data and later
# on new data; some of the arguments have different meanings in the two
# cases

# typical usage: apply polyanNA() to training data; then run lm() or
# whatever; then run polyanNA() on the new data and feed the result into
# predict.pa1()

# arguments:

#    xy: input data frame, X and Y in training case, only X in 
#        new data (prediction) case
#    yCol: column number of Y, needed in training case
#    breaks: if non-NULL, number of desired levels in discretized 
#       vectors (not counting added 'na')
#    allCodeInfo: in the new-data case, an R list, obtained via a call
#    to polyanNA() in the training data (else NULL), one element for 
#       each column of X; the element is NULL unless that column had 
#       been discretized in the original, in which it is the codeInfo
#       attribute from that operation 

# we'll use x here to refer to xy without the Y column, if any

# if breaks is non_NULL, then the numeric columns are run through 
# 'discretize', and converted to factors 

# then for each column in x that is a factor and has at least one NA
# value, add an 'na' level and recode the NA values to that level; that
# way, one can account for the potential predictive information that an
# NA value may convey; replace the factor by the corresponding dummies

# to account for multiple interactions between NAs etc., run the full
# set of dummies through polyreg

polyanNA <- function(xy,yCol=NULL,breaks=NULL,allCodeInfo=NULL) 
{

   if (!is.data.frame(xy)) xy <- as.data.fraem(xy)

   # training-data or new-data case?
   newdata <- is.null(yCol)
   x <- if (newdata) xy else xy[,-yCol,drop=FALSE] 
   if (newdata) {
      # assert proper inputs
      stopifnot(is.null(breaks) && !is.null(allCodeInfo))
   } else { # training case
      allCodeInfo <- list(length = ncol(x))
      for (i in 1:ncol(x)) 
         # no code info yet, working on it in next block below
         allCodeInfo[[i]] <- 'no code info'
   }

   # go through each column, doing the following:

   # training case:
   #    if numeric and user wants discretization then discretize
   #    if factor (inc. discretized) record levels in allCodeInfo[[i]]
   # new-date case:
   #    if numeric and had been discretized in training phase then
   #       discretize here
   for (i in 1:ncol(x)) {
      if (!newdata) {
      }

      FIX HERE, PER COMMENTS ABOVE


      if (!newdata && is.numeric(x[,i]) || 
             allCodeInfo[[i]] != 'no code info') {
         # discretize and make it a factor
         codeInfo <- 
            if (newdata) allCodeInfo[[i]] else NULL
         nLevels <- if (newdata) NULL else breaks
         tmp <- discretize(x[,i],nLevels,codeInfo)
         x[,i] <- tmp$xDisc  # note: now an R factor
         allCodeInfo[[i]] <- tmp$codeInfo
      }
   }

   # which factor columns have NAs and need to be converted?
   naByCol <- which(apply(x,2,function(col) any(is.na(col))))
   for (i in naByCol) {
      if (is.factor(x[,i])) {
         tmp <- addNAlvl(x[,i])
         tmp <- dummy(tmp)
         dumms <- tmp[,-ncol(tmp),drop=FALSE]
         x <- cbind(x,dumms)
      }
   }
   x[,naByCol] <- NULL

   # if (!newdata) xy[,-yCol] <- x else xy <- x
   if (!newdata) xy <- cbind(x,xy[,yCol]) else xy <- xj
   
   # xy[,-yCol] <- x else xy <- x
   val <- list(xy=xy, allCodeInfo=allCodeInfo)
   class(val) <- 'pa'
   val
}

#########################  addNAlvl  ##################################

# if factor f has any NAs, add a new level to the factor, 'na', and
# replace any NAs by this level

# addNAlvl <- function(f,nm)
addNAlvl <- function(f)
{
   f1 <- as.character(f)
   # f1[is.na(f1)] <- paste0(nm,'.na')
   f1[is.na(f1)] <- 'na'
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

#########################  lm.pa() examples ###################################

# illustration of use of polyanNA() and lm.pa() on the prgeng dataset
# (in regtools package, included by polyanNA)

# in this one, artifically inject NAs into the highest-wage occupations

lm.pa.ex1 <- function()
{  getPE(Dummies=F)  # 2000 Census
   pe1 <- pe[,c(1,3,5,7:9)]  # age educ occ sex wageinc wkswrkd
   pe1$educ <- as.factor(pe1$educ)
   pe1$occ <- as.factor(pe1$occ)
   lmout <- lm(wageinc ~ .,data=pe1)  # full data
   print(lmout$coef['sex'])
   pe2 <- pe1[,c(1,2,3,4,6,5)]
   # simulate NAs, making high-wage Occ 102, 1042 more likely NA
   occ <- pe2$occ
   occ1024 <- which(occ == '102' | occ == '141')
   forNA <- sample(occ1024,2000)
   occ[forNA] <- NA
   pe102 <- pe2
   pe102$occ <- occ
   # complete cases only
   # print(summary(lm(wageinc ~ .,data=pe102)))  
   lmout <- lm(wageinc ~ .,data=pe102)  # full data
   print(lmout$coef['sex'])
   # polyanNA, no discretization
   pe3 <- polyanNA(pe102,yCol=6)
   # print(summary(lm.pa(pe3)$lmout))
   lmout <- lm(wageinc ~ .,data=pe3$xy)  # full data
   print(lmout$coef['sex'])
}

# here, set up an MCAR situation, NAs in categorical variables only

lm.pa.ex2 <- function()
{  stop('under construction')
#### need to change so that only NA cases are predicted, by both
###  polyanNA and imputational methods
   getPE(Dummies=F)  # 2000 Census
   pe1 <- pe[,c(1,3,5,7:9)]  # age educ occ sex wageinc wkswrkd
   pe1$educ <- as.factor(pe1$educ)
   pe1$occ <- as.factor(pe1$occ)
   pe1$sex <- as.factor(pe1$sex)
   print(summary(lm(wageinc ~ .,data=pe1)))  # full data
   pe2 <- pe1[,c(1,2,3,4,6,5)]
   pe2.save <- pe2
   tstidxs <- sample(1:nrow(pe2),4000)
   pe2trn <- pe2[-tstidxs,]
   pe2tst <- pe2[tstidxs,]
   lmout.full <- lm(wageinc ~ .,data=pe2trn)
   ypred.full <- predict(lmout.full,pe2tst[,-6])
   print(mean(abs(ypred.full-pe2tst[,6])))
   pe2 <- pe2.save
##    for (i in 2:4) {
##       naSpots <- sample(1:nrow(pe2),2000)
##       pe2[naSpots,i] <- NA
##    }
   occ <- pe2$occ
   occ1024 <- which(occ == '102' | occ == '141')
   forNA <- sample(occ1024,4000)
   occ[forNA] <- NA
   pe2$occ <- occ
   pe2trn <- pe2[-tstidxs,]
   pe2tst <- pe2[tstidxs,]
   lmout.cc <- lm(wageinc ~ .,data=pe2trn)
   browser()
   ypred.cc <- predict(lmout.cc,pe2tst[,-6])
   print(mean(abs(ypred.cc-pe2tst[,6]),na.rm=TRUE))
   pe2trn.pa <- polyanNA(pe2trn,yCol=6)
   lmout.pa <- lm.pa(pe2trn.pa)
   ypred.pa <- predict(lmout.pa,pe2tst[,-6])
   print(mean(abs(ypred.pa-pe2tst[,6])))
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
