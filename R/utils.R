
# see how many NAs in each column of df; mvchar is the character
# indicating missingness, e.g. '?', if not coded NA

countnas <- function(df,mvchar=NULL)  {
   if (is.null(mvchar)) 
      sapply(df,function(cl) sum(is.na(cl)))
   else
      sapply(df,function(cl) sum(cl == mvchar))
}

