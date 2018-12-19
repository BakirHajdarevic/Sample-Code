#########################################################################
# Programmer: Bakir Hajdarevic
# Program: hajdarevic_murphy_stat_project.R
# Date: 12/7/18
# Assignment: This file contains the code used to generate
# plots of the relationship between an individual's smoking 
# status and their medical insurance cost. More specifically, 
# it contains the following predictors and response:
#
#     Predictors
#   - smoking status
#   - Region in the US (northwest, southwest, northeast, southesast)
#   - Sex
#   - Number of children
#   - Age
#   - Body Mass Index (BMI)
#
#   Response = Medical Insurance Costs
#
# From this data set, we analyzed the following:
#   - Correlation between quanitative predictors as well as response.
#   - ANOVA of entire dataset.
#   - X/Y plots of medical insurance and each predictor.
#   - X/Y plots of certain predictors.
#   - Polynomial regression of entire data set over 0-10 degs.
#   - Polynomail regression of entire data set AFTER splitting data into
#     smokers and non-smokers.
#   - Moodel selection of polynomial reg. fits using MSR, R2, AIC, and BIC.
#
########################################################################

# https://www.datacamp.com/community/blog/r-correlation-tutorial
# https://briatte.github.io/ggcorr/

# Set working directory
setwd("C:/Users/bhajd/Desktop/Statistical Learning/Project")

# Load database
dat = read.csv("insurance.csv", header = TRUE)
# Get number of rows
n = length(dat[,1])
# Set predictors
predictors = dat[2:n,1:6]

# Get matrices for each qualitative conversion
vect_gen = matrix(0,n-1,1)
vect_smoke = matrix(0,n-1,1)
vect_region = matrix(0,n-1,1)

# Convert qualitative predictors into quanitative data
# Sex (0 = Male, 1 = Female)
# Smoker/Nonsmoker (0 = nonsmoker, 1 = smoker)
# Region ( northeast = 0, northwest = 1, southeast = 2, southwest = 3)
vect_gen = as.numeric(predictors[,2])    # gender
vect_smoke = as.numeric(predictors[,5])  # smoking status
vect_region = as.numeric(predictors[,6]) # region

# Re-initialize predictors matrix with new quanititative vectors
pred_mat = matrix(c(predictors[,1],vect_gen,predictors[,3],predictors[,4],vect_smoke,vect_region), 
                            nrow=n-1, 
                            ncol=6, 
                            byrow=FALSE)
colnames(pred_mat) = c('Age', 'Gender', 'BMI', 'Children', 'Smoker', 'Region')

# Install library GGally
#install.packages('GGally', dependencies = TRUE)
library('GGally')
library('ggplot2')
ggcorr(pred_mat,label = TRUE,label_alpha = 0)

# Re-initialize predictors matrix with OUT new quanititative vectors
corr_mat = matrix(c(predictors[,1],predictors[,3],predictors[,4],resp_cost), 
                  nrow=n-1, 
                  ncol=4, 
                  byrow=FALSE)
colnames(corr_mat) = c('Age', 'BMI', 'Children', 'Medical Costs' )
ggcorr(corr_mat,label = TRUE,label_alpha = 0)
#cor.test(corr_mat,corr_mat)
install.packages('Hmisc', dependencies = TRUE)
library(Hmisc) # You need to download it first.
rcorr(corr_mat, type="pearson") # type can be pearson or spearman

#install.packages('ggplot2', dependencies = TRUE)
library('ggplot2')
par(mfrow=c(1,3))
 
pred_mat = data.frame(pred_mat)
# Plot Age vs BMI
qplot(pred_mat$Age, 
       pred_mat$BMI, 
       data = pred_mat, 
       geom = c("point", "smooth"), 
       method = "lm", 
       alpha = I(1 / 5), 
       se = FALSE)
 
# Plot BMI vs Region
qplot(pred_mat$BMI, 
       pred_mat$Region, 
       data = data.frame(pred_mat), 
       geom = c("point", "smooth"), 
       method = "lm", 
       alpha = I(1 / 5), 
       se = FALSE)
 
# Plot Gender vs Smoker
qplot(pred_mat$Gender, 
       pred_mat$Smoker, 
       data = pred_mat, 
       geom = c("point", "smooth"), 
       method = "lm", 
       alpha = I(1 / 5), 
       se = FALSE)

# Run ANOVA for all predictors in regards to the response, medical costs
fit = aov(resp_cost ~ predictors[,1] + vect_gen + predictors[,3] + predictors[,4] + vect_smoke + vect_region)
layout(matrix(c(1,2,3,4),2,2)) # optional layout 
plot(fit) # diagnostic plots
summary(fit) # display Type I ANOVA table

# Evaluate Model Effects
#  In a nonorthogonal design with more than one term on the right hand side of the 
# equation order will matter (i.e., A+B and B+A will produce different results)! 
# We will need use the drop1( ) function to produce the familiar Type III results. 
# It will compare each term with the full model.
#drop1(fit,~.,test="F") # type III SS and F Tests

# Tukey Honestly Significant Differences
# it calculates post hoc comparisons on each factor in the model. 
# TukeyHSD(fit) # where fit comes from aov()

########################################################################################
# Polynomial Regression
# Example: model <- lm(noisy.y ~ poly(q,3))
set.seed(20)
num = 10
fit_vals_msr <- array(0, dim=c(1,10))
fit_vals_aic <- array(0, dim=c(1,10))
fit_vals_bic <- array(0, dim=c(1,10))
fit_vals_r2 <- array(0, dim=c(1,10))

X = cbind(predictors[,1],vect_gen,predictors[,3], predictors[,4], vect_smoke, vect_region)

for (ii in 1:num){
  # Get model fit
  model = lm(resp_cost ~ polym(X, degree = ii, raw=TRUE))
  # Obtain MSR
  fit_vals_msr[ii] = mean(model$residuals^2)
  # Obtain R^2
  fit_vals_r2[ii] = summary(model)$r.squared
  # Obtain AIC
  fit_vals_aic[ii] = AIC(model)
  # Obtain BIC
  fit_vals_bic[ii] = BIC(model)
}

best_fits <- array(0, dim=c(4,2))

# Find min. MSR 
best_fits[1,1] = min(fit_vals_msr)
best_fits[1,2] = which.min(fit_vals_msr)

# Find max. R^2
best_fits[2,1] = max(fit_vals_r2)
best_fits[2,2] = which.max(fit_vals_r2)

# Find min. AIC 
best_fits[3,1] = min(fit_vals_aic)
best_fits[3,2] = which.min(fit_vals_aic)

# Find min. BIC
best_fits[4,1] = min(fit_vals_bic)
best_fits[4,2] = which.min(fit_vals_bic)

##########################################################################
# Split data into two groups: non-smoking and smoking
smoke_ind_arr = which(vect_smoke %in% c(1))

fit_vals_2 <- array(0, dim=c(10,2,4))
best_fits_2 <- array(0, dim=c(2,4,2))

for (ii in 1:num){
  for (jj in 1:2){
    # Get model fit
    if (jj == 1){
      model = lm(resp_cost[smoke_ind_arr] ~ polym(X[smoke_ind_arr,], degree=ii, raw=TRUE)) 
    }else{
      model = lm(resp_cost[-smoke_ind_arr] ~ polym(X[-smoke_ind_arr,], degree=ii, raw=TRUE))
    }
    for (kk in 1:4){
      fit_vals_2[ii,jj,kk] = switch(kk,
             mean(model$residuals^2),   # Obtain MSR
             summary(model)$r.squared,  # Obtain R^2
             AIC(model),                # Obtain AIC
             BIC(model))                # Obtain BIC
      if(kk==2){
        best_fits_2[jj,kk,1]=max(fit_vals_2[ii,jj,kk])
        best_fits_2[jj,kk,2]=which.max(fit_vals_2[ii,jj,kk])
      }else{
        best_fits_2[jj,kk,1]=min(fit_vals_2[ii,jj,kk])
        best_fits_2[jj,kk,2]=which.min(fit_vals_2[ii,jj,kk])
      }
    }
  }
}
