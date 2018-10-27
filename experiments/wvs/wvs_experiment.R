
# uncomment and run. first line only needed once. paths may need updating...
# source("experiments/wvs/wvs_raw_to_csv.R")
# wvs <- read.csv("experiments/wvs.csv", stringsAsFactors = FALSE)
# source("experiments/wvs/wvs_csv_to_country_data_frames.R")

X <- wvs %>% select(country, birthyear, edu, 
                    income_bracket,
                    contains("econ_attitudes"))
W <- wvs %>% select(region, religion)
wv <- wvs_make_data(wvs$rightist, X, W)

# countries included
wv$countries
# inspect data dimensions by country
lapply(wv, function(country) lapply(country, dim))

N_countries <- length(wv$countries)
tmp <- matrix(nrow=N_countries, ncol=3)
dimnames(tmp) <- list(wv$countries, c("tower", "full", "mice"))
results <- data.frame(tmp)

seed <- 1
set.seed(seed)
for(i in 1:length(wv$countries)){
  
  cat("starting:", wv$countries[i], "\n\n")
  
  tried <- try(out <- doExpt2(wv[[wv$countries[i]]])) # could do parLapply(wv$countries, doExpt2)
  if(!inherits(tried, "try-error")){
    
    results[i, ] <- out
    cat("\nfinished:", wv$countries[[i]], "\n\n")

  }else{
    
    cat("\n something went wrong with ", wv$countries[[i]], "\n")
    print(tried)
    
  }
  
}
results$seed <- wv$seed
results$metric <- "MAPE"
colMeans(results[,1:3], na.rm=TRUE)
# tower     full     mice 
#1.770703 1.871491 1.890475
sum(!is.na(results$tower)) # 46 countries, seed 1
table(results$tower < results$mice) # tower better than mice 36 out of 46, seed 1
