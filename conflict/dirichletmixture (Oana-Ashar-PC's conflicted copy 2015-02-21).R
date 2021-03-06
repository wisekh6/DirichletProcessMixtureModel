#################################################################################################
#################################################################################################
################## THE MAIN FUNCTION ###########################################################
#################################################################################################

dirichletmixture = function(Y, time, censoring, iter, F ) {

setwd('/home/bit/ashar/Dropbox/Code/DPmixturemodel/DPplusAFT')
  
Time <- cbind(time, censoring) 
  
D = NCOL(Y)
N = NROW(Y)
K = iter*50 



source('rchinese.R')
## Initialization of all the hyperparameters and 
alpha  = 2.0
beta  = D+1
ro = 0.5
epsilon = as.vector(apply(Y,2,mean))
W = cov(Y)
c <-  rchinese(N,alpha)
f <- table(factor(c, levels = 1:max(c)))


## Initialization of the parameters for Gaussian Mixture
mu = matrix(data = NA, nrow = K, ncol = D)
S = array(data = NA, dim =c(K,D,D))


## Initialization part for the parmaters of AFT Model

#Sparsity controlling parameter
r =1
si = 1.78

lambda2 <- numeric(K)
tau2 = matrix(data = NA, nrow = K, ncol = D)
betahat = matrix(data = NA, nrow = K, ncol = D)
sigma2 <- rep(NA, K)
beta0 <- rep(NA, K)
That <-  numeric(N)

### Setting Initial cluster assignments and cluster centres with k-means

grand.matrix <- cbind(Y, time)
# Let G be the potential number of cluster
G <- F
k.data <- kmeans(grand.matrix,G)
c <- k.data$cluster

### Getting an idea about the variance of the model using a linear model
Ysc <- scale(Y, center = TRUE, scale = TRUE)
lm.data <- lm(time ~ Ysc)
sig2.dat <- var(lm.data$residuals)


## Setting the parameters to the Probabilities
source('priorparameter.R')
prior <- priorparameter(c,S, mu, lambda2,tau2,sigma2,beta0, betahat,K, epsilon, W, beta, ro, D, r, si, Time, N)
mu <- prior$mu 
## We can intialize the cluster centres by k-means

prior.numclust <- table(factor(c, levels = 1:K))
prior.activeclass<- which(prior.numclust!=0)

for ( i in 1:length(prior.activeclass)){
mu[prior.activeclass[i],1:D] <-  k.data$centers[i,1:D] 
}


S <- prior$Sigma  
 
sigma2 <- prior$sigma2
betahat <- prior$betahat 
lambda2 <- prior$lambda2
tau2 <- prior$tau2

## We can initialize the sigma2 to the square of the residual
for ( i in 1:length(prior.activeclass)){
  sigma2[prior.activeclass[i]] <-  sig2.dat
}

## We can initialiize the betahat also to the linear model
for ( i in 1:length(prior.activeclass)){
  betahat[prior.activeclass[i],] <-  lm.data$coefficients[2:(D+1)]
}


beta0 <- prior$beta0
## We can intialize the cluster centres of time by k-means

for ( i in 1:length(prior.activeclass)){
beta0[prior.activeclass[i]] <- as.vector(k.data$centers[i,D+1])
}

# The Time has to be initialized
# source('updatetime.R')
# ti <- updatetime(c, Y, Time,That, beta0, betahat, sigma2)
# That <- ti$time


That <- Time[,1]






## MCMC sampling 



source('posteriorchineseAFT.R')
source('posteriorGMMparametrs.R')
source('posteriortimeparameters.R')
source('updatetime.R')
source('priordraw.R')


cognate <- NA
param <- NA
paramtime <- NA

for (o in 1:iter) {
 
  ## Updating the parameters based on the observations 
  param <- posteriorGMMparametrs(c,Y,mu,S, alpha,K, epsilon, W, beta, ro,N,D )
  mu <- param$mean
  S <- param$precision
  paramtime <- posteriortimeparameters(c, That, lambda2,tau2,sigma2,beta0, betahat, Y, K, epsilon, W, beta, ro,D, r, si, Time,N, sig2.data)
  beta0 <- paramtime$beta0
  betahat <- paramtime$betahat
  sigma2 <- paramtime$sigma2
  lambda2 <- paramtime$lambda2
  tau2 <- paramtime$tau2
  
  
  
  ## Updating the indicator variables and the parameters
  source('posteriorchineseAFT.R')
  cognate <- posteriorchineseAFT(c,Y,mu,S,alpha,That, beta0, betahat, sigma2, lambda2, tau2, K, epsilon, W, beta, ro,D, r, si, Time,N, sig2.dat)
  c <- cognate$indicator
  mu <- cognate$mean
  S <- cognate$precision
  beta0 <- cognate$beta0
  betahat <- cognate$betahat
  sigma2 <- cognate$sigma2
  lambda2 <- cognate$lambda2
  tau2 <- cognate$tau2
  

  
  
 
  
  

  
# source('posteriorhyper.R')  
# #  Updating the hyper paramters
# hypercognate <- posteriorhyper (c, Y, mu, S, epsilon, W, beta, ro )
# epsilon <- hypercognate$epsilon
# W <- hypercognate$W
#  W <- matrix(as.matrix(W),nrow = D, ncol =D)
# ro <- hypercognate$ro
#   
#   
# source('posteriorbeta.R')  
# # Updating beta
#  beta <- posteriorbeta(c, beta, D, S, W)
#   
# source('posterioralpha.R') 
# # Updating the concentration parameter
# alpha <- posterioralpha(c, N, alpha)
# 
#  
# Updating the Time Variable
# ti <- NA
# ti <- updatetime(c, Y, Time,That, beta0, betahat, sigma2)
# That <- ti$time
print(o/iter)
  
 } 
  
return(list('c' = c, 'time' = That, 'beta0' = beta0,'sigma2' = sigma2, 'betahat' = betahat, 'lambda2' = lambda2, 'tau2' =  tau2 ))

}
