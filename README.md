# polyanNA

Novel, **nonimputational**  methods for handling missing values in
prediction applications.

## Overview

The intended class of applications is regression modeling, at this time
linear and generalized linear models (nonparametric/ML models to be
included later).  Our emphasis is on prediction, rather than on
estimation of regression coefficients and the like.

To make things concrete, say we are regressing Y on a vector X of length
p.  We have data in a matrix D of n rows, thus of dimensions n X p.
Some of the elements of A are missing, i.e. are NA values in R.

Note carefully that in describing our methods as being for regression
applications, *we do NOT mean imputing missing values through some
regression technique.* Instead, our context is that of regression
applications themselves.

Again, all of our methods, both those currently in the package and those
under development (see below), are **nonimputational**.

## Polynomial extension of the Missing-Indicator Method

Our first method is an extension of the Missing-Indicator Method
(Miettinen, 1985).  MIM can be described as follows.

*MIM method*

Say X includes some numeric variable, say Age. MIM add a new column
to A, say Age.NA, consisting of 1s and 0s.  For any row in A for
which Age is NA, the NA is replaced by 0, and Age.NA is set to 1;
otherwise Age.NA is 0.  So rather than trying to get the missing
value, we treat the missingness as informative, with the information
being carried in Age.NA.

It is clear that the insertion of that 0 value -- fake and likely highly
inaccurate data -- can induce substantial bias, say in the regression
coefficient of Age.  Indeed, some authors have dismissed MIM as only
useful back in the era before modern, fast computers (Nur, 2010) that
can handle computationally intensive imputational methods.

*Case of categorical variables*

However, now consider categorical variables, i.e. R factors.  Here,
instead of adding a fake 0, we in essence merely add a legitimate new
level to the factor (Jones, 1996).

Say we have a predictor variable EyeColor, taking on values Brown, Blue,
Hazel and Green, thus an R factor with these four levels.  In, say,
lm(), R will convert this one factor to three dummy variables, say
EyeColor.Brown, EyeColor.Blue and EyeColor.Hazel.  MIM then would add a
dummy variable for missingness, EyeColor.na, and in rows having a
value of 1 for this variable, the other three dummies would be set to 0, 

Unlike the case of numeric variables, this doesn't use fake data, and
produces no distortion.  

We now proceed with our regression analysis as usual, using the modified
EyeColor factor/dummies.

In a call to, say, R's lm() function, any R factor will be converted to
dummy variables, k-1 of them for a k level factor.  Let's assume we do
this explicitly, i.e. make this conversion before calling lm().

*The polyanNA package: the polyanNA() function*

The polyanNA() function inputs a data frame and  converts all factor columns
according to MIM.  Optionally, the function will discretize the numeric
columns as well, so that these two can be fed through MIM.

 

*Value of MIM*

As with imputational methods, the non-imputational MIM enables us to
make use of rows of A having non-missing values, rather than discarding
them as in the complete-cases method (CCM).  Moreover, MIM treats NA values as
potentially *informative*.  If the missingness mechanism is not MCAR,
CCM may induce a bias in our analyses.

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
 


