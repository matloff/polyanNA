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
We then proceed with our regression analysis as usual, using the modified
EyeColor factor/dummies.

Unlike the case of numeric variables, this doesn't use fake data, and
produces no distortion.  

**NOTE:** Below, all mentions of MIM refer to that method as applied to
categorical variables.
 
*Value of MIM*

As with imputational methods, the non-imputational MIM is motivated by a
desire to make use of rows of A having non-missing values, rather than
discarding them as in the complete-cases method (CCM).  

Moreover, MIM treats NA values as potentially *informative*; ignoring
them may induce a bias.  MIM, may reduce this bias, by indirectly
accounting for the distributional interactions between missingness and
other variables.  This occurs, for instance, in the cross-product terms
in A'A and A'B, where the lm() coefficient vector is (A'A)<sup>-1</sup>
A'B.


*The polyanNA package*

The first method offered in this package implements MIM for factors,
both in its traditional form, and with an extension to be described
below.

The polyanNA() function inputs a data frame and  converts all factor
columns according to MIM.  Optionally, the function will discretize the
numeric columns as well, so that these two can be fed through MIM.

There is also function lm.pa(), with an assciated predict(), to
implement linear modeling an predictor in the settings in which
categorical variables are subject to missingness.

*Example* 

The function lm.pa.ex(), included in the package, inputs some Census
data on programmer and engineer wages in 2000.  It regresses WageIncome
against Age, Education, Occupation, Gender and WeeksWorked.

We intentionally inject NA values in the Occupation variable,
specifically in about 10% of the cases in which Occupation has code 102,
one of the higher-paying categories.  In this (artificial) setting, the
missingness of Occupation tells us that the actual value 102 or 104.

We are primarily interested in prediction, but let's look at some
estimated coefficients:

<pre>
var.     orig. data     CCM        MIM
Occ102   11455.77       11713.99   11627.60 
Occ140   10852.95       10926.39   10856.78 
Age      477.65         475.15     475.84
Gender   8558.76        8398.90    8520.03
WksWrkd  1298.32        1281.12    1298.37
</pre>

These numbers are very gratifying. We see that CCM produces a bias, but
that the bias is ameliorated, and in some casesvirtually eliminated, by
MIM.

*Extension using a polynomial model*

Now, note that if single NA values are informative, then pairs or
triplets and so on may carry further information.  
In other words, we 
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
 


