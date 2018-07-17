
# assumption-free missing value method, for a prediction context

# for each column in the input data frame that is a factor and has at
# least one NA value, add an 'na' level and recode the NA values to that
# level; then fit the regression model; that way, one can account for
# the potential predictive information that an NA value may convey

# to account for multiple interactions, run the result through polyreg

