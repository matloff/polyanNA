# polyanNA

Novel, **nonimputational**  methods for handling missing values (MVs) in
prediction applications.

## Overview

The intended class of applications is regression modeling, at this time
linear and generalized linear models (nonparametric/ML models to be
included later).  

Unlike most of the MV literature, our emphasis is on prediction, rather
than on estimation of regression coefficients and the like.  This is
important first because we are in the era of Big Data, which is
prediction-oriented, but just as importantly, also because of the issue
of assumptions.  Most MV methods (including ours) make strong
assumptions, which are difficult or impossible to verify.  We posit that
the prediction context is more robust to the assumptions than is
estimation.  This would be similar to the non-MV setting, in which
models can be rather questionable yet still have strong predictive
power.

We are especially interested in predicting new cases that have missing
values. In such settings, the classic Complete Cases method (CCM) --
use only fully intact rows -- is useless.

To make things concrete, say we are regressing Y on a vector X of length
p.  We have data in a matrix A of n rows, thus of dimensions n X p.
Some of the elements of A are missing, i.e. are NA values in the R
language.

Note carefully that in describing our methods as being for regression
applications, *we do NOT mean imputing missing values through some
regression technique.* Instead, our context is that of regression
applications themselves.  Again, all of our methods are
**nonimputational**.  (For some other nonimputational methods, see for
instance (Soysal, 2018) and (Matloff, 2015).)

## Contributions of This Package

1. Cross-product extensions of the Missing-Indicator Method.

2. A novel approach, based on the Tower Property of expected values.

## Extending the Missing-Indicator Method

Our first method is an extension of the Missing-Indicator Method
(Miettinen, 1983) (Jones 1996).  MIM can be described as follows.

*MIM method*

Say X includes some numeric variable, say Age. MIM add a new column to
A, say Age.NA, consisting of 1s and 0s.  Age.NA is a missingness
indicator for Age:  For any row in A for which Age is NA, the NA is
replaced by 0, and Age.NA is set to 1; otherwise Age.NA is 0.  So rather
than trying to get the missing value, we treat the missingness as
informative, with the information being carried in Age.NA.

It is clear that replacement of an NA by a 0 value -- fake and likely highly
inaccurate data -- can induce substantial bias, say in the regression
coefficient of Age.  Indeed, some authors have dismissed MIM as only
useful back in the era before modern, fast computers that 
can handle computationally intensive imputational methods
(Nur, 2010). 

*Case of categorical variables*

However, now consider categorical variables, i.e. R factors.  Here,
instead of adding a fake 0, we in essence merely add a legitimate new
level to the factor (Jones, 1996).

Say we have a predictor variable EyeColor, taking on values Brown, Blue,
Hazel and Green, thus an R factor with these four levels.  In, say,
**lm()**, R will convert this one factor to three dummy variables, say
EyeColor.Brown, EyeColor.Blue and EyeColor.Hazel.  MIM then would add a
dummy variable for missingness, EyeColor.na, and in rows having a
value of 1 for this variable, the other three dummies would be set to 0, 
We then proceed with our regression analysis as usual, using the modified
EyeColor factor/dummies.

Unlike the case of numeric variables, this doesn't use fake data, and
produces no distortion.  

**NOTE:** Below, all mentions of MIM refer specifically to that method
as applied to categorical variables.
 
*Value of MIM*

As with imputational methods, the non-imputational MIM is motivated by a
desire to make use of rows of A having non-missing values, rather than
discarding them as in CCM.  Note again that this is crucial in our
prediction context; CCM simply won't work here.

Moreover, MIM treats NA values as potentially *informative*; ignoring
them may induce a bias.  MIM may reduce this bias, by indirectly
accounting for the distributional interactions between missingness and
other variables.  This occurs, for instance, in the cross-product terms
in A'A and A'B, where the **lm()** coefficient vector is (A'A)<sup>-1</sup>
A'B.


*The polyanNA package*

The first method offered in our **polyanNA**  package implements MIM for
factors, both in its traditional form, and with extensions to be
described below.

The **polyanNA()** function inputs a data frame and  converts all factor
columns according to MIM.  Optionally, the function will discretize the
numeric columns as well, so that these two can be fed through MIM.

There is also a function **lm.pa()**, with an associated method for the
generic **predict()**, to implement linear modeling and prediction in
the settings in which categorical variables are subject to missingness.

*Example* 

The function **lm.pa.ex1()**, included in the package, inputs some Census
data on programmer and engineer wages in 2000.  It regresses WageIncome
against Age, Education, Occupation, Gender and WeeksWorked.

We intentionally inject NA values in the Occupation variable,
specifically in about 10% of the cases in which Occupation has code 102,
one of the higher-paying categories:  

```
> tapply(pe$wageinc,pe$occ,mean)
     100      101      102      106      140      141 
50396.47 51373.53 68797.72 53639.86 67019.26 69494.44 
```

In this (artificial) setting, the missingness of Occupation tells us
that the actual value 102 or 104.

This experiment is interesting because the proportion of women in those
two occupations is low:

```
> table(pe[,c(5,7)])
     sex
occ      0    1
  100 1530 3062
  101 1153 3345
  102 1607 5213
  106  209  292
  140  127  675
  141  282 2595
```

Due to the fact that there are fewer women in occupations 102 and 140, two
high-paying occupations, a naive regression analysis using CCM might bias
the gender effect downward.  Let's see.

Though we are primarily interested in prediction, let's look at the
estimated coefficient for Gender.

<pre>
Run    full           CC         MIM
1      8558.765       8391.369   8581.544 
2      8558.765       8358.057   8438.852 
3      8558.765       8717.961   8544.091
4      8558.765       8573.875   8585/638
5      8558.765       8270.693   8473.888
</pre>

These numbers are very gratifying. We see that CCM produces a bias, but
that the bias is ameliorated by MIM.

*Extension using a polynomial model*

Now, note that if single NA values are informative, then pairs or
triplets of NAs and so on may carry further information.  In other
words, we should consider forming products of the dummy variables,
between one of the original factors and another.

We handle this by using our 
[polyreg package](http://github/matloff/polyreg), which forms polynomial
terms in a *multivariate* context, properly handling the case of
indicator variables. It accounts for the fact that 
powers of dummies need not be computed, and that products of dummy
columns from the same categorical variable will be 0.

*MIM functions in this package*

**polyanNA(xy,yCol=NULL,breaks=NULL,allCodeInfo=NULL)**

Applies MIM to all columns in **xy** that are factors, other than a Y
column if present (non-NULL **yCol**, with the value indicating the
column number of Y).  Optionally first discretizes all numeric columns
(other than Y), setting breaks levels.  When applied to "new data" after
fitting, say, **lm()**, set **allCodeInfo**. to the value returned by
**polyanNA()** on the original data.
 
**lm.pa(paout,maxDeg=1,maxInteractDeg=1)**



## Coming attractions

We are developing further methods, again nonimputational, that exploit
the Tower Property:  For random variables Y, U and V, E[ E(Y|U,V) | U ]
= E(Y | U).  What this theoretical abstraction says is that if we take
the regression function of Y on U and V, and average it over V for fixed
U, we get the regression function of Y on U.  If V is missing but U is
known, this is very useful.
 
## References

X. Gu and N. Matloff, A Different Approach to the Problem of Missing
Data, *Proceedings of the Joint Statistical Meetings*, 2015

M. Jones, Indicator and Stratification Methods for Missing Explanatory
Variables in Multiple Linear Regression, *JASA*m 1996

O.S. Miettinen, Regression Analysis, in *Theoretical Epidemiology:
Principles of Occurrence Research in Medicine*, 1983

S. Soysal *et al*, the Effects of Sample Size and Missing Data Rates on
Generalizability Coefficients, *Eurasian J. of Ed. Res.*, 2018
