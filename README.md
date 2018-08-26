# polyanNA

Novel, **nonimputational**  methods for handling missing values in
regression applications.

## Overview

The intended class of applications is regression modeling, at this time
linear and generalized linear models (nonparametric/ML models to be
included later).

To make things concrete, say we are regressing Y on a vector X of length
p.  We have data in a matrix D of n rows, thus of dimensions n X p.
Some of the elements of A are missing, i.e. are NA values in R.

Note carefully that in describing our methods as being for regression
applications, *we do NOT mean imputing missing values through some
regression technique.* Instead, our context is that of regression
applications themselves.

Again, all of our methods, both those currently in the package and those
under development (see below), are **nonimputational**.

## Treating NA as a factor level

Our first method is an extension of the Indicator Variable Method (IVM),
to be used on numerical variables, say Age.  It can be described as
follows.

*IVM method*

Say X includes some numeric variable, say Age. IVM add a new column
to A, say Age.NA, consisting of 1s and 0s.  For any row in A for
which Age is NA, the NA is replaced by 0, and Age.NA is set to 1;
otherwise Age.NA is 0.  So rather than trying to get the missing
value, we treat the missingness as informative, with the information
being carried in Age.NA.

It is clear that the insertion of that 0 value -- fake and likely highly
inaccurate data -- can induce substantial bias, say in the regression
coefficient of Age.  Indeed, some authors have dismissed IVM as only
useful back in the era before modern, fast computers (Nur, 2010).  

*Case of categorical variables*

But if one extends IVM to categorical variables, i.e. R factors,  the
picture changes radically. 

Say we have a variable EyeColor, taking on values Brown, Blue, Hazel and
Green, thus an R factor with these three levels.  Then instead of trying
to impute the NAs, we add a new level, EyeColor.na to this factor.  We
now proceed with our regression analysis as usual, using the modified
Age variable.

In a call to, say, R's lm() function, any R factor will be converted to
dummy variables, k-1 of them for a k level factor.  Let's assume we do
this explicitly, i.e. make this conversion before calling lm().

Let's call this method New NA Level, NNAL.

In this categorical varaible case, NNAL does work out to be IVM (even
though this is not traditional IVM).  We originally had dummy variables
for Brown, Blue and Hazel.  With IVM, we'd add one for EyeColor.na, and
if it is equal to 1, then the dummies for Brown, Blue and Hazel will be
0 -- i.e. we will indeed be setting EyeColor to 0 and have an indicator
variable that is 1 in this case. 

*Bias issue, assumptions*

This approach is then bias-free, in the sense that all the various
conditional distributions involving missingness and our data variables
is accounted for.  To be sure, one must keep in mind that, for instance,
a regression coefficient for Brown must now be interpreted as the
marginal effect on Y of "eye color known to be brown."  If one wants to
remove that "known to be" qualifier, an assumption is needed (see below.)

*Extension using a polynomial model*

Now, note that if single NA values are informative, then pairs or
triplets and so on may also carry information.  In other words, we 
should consider forming products of the dummy variables, between one of
the original factors and another.

We handle this by using our 
[polyreg package](http://github/matloff/polyreg), which forms polynomial
terms in a *multivariate* context, properly handling the case of
indicator variables, whose powers need not be computed.

## NNAL functions in this package:

 

## Coming attractions

We are developing further methods, again nonimputational, that exploit
the Tower Property:  For random variables Y, U and V, E[ E(Y|U,V) | U ]
= E(Y | U).  What this theoretical abstraction says is that if we take
the regression function of Y on U and V, and average it over V for fixed
U, we get the regression function of Y on U.  If V is missing but U is
known, this is very useful.
 


