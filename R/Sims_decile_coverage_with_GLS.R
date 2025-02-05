#Coverage of GLS and Sen's confidence intervals
#Sean Hardison
#NEFSC - Integrated Statistics

rm(list = ls())
#Mann kendall with pre-whitening coverage intervals
library(boot);library(Kendall)
library(zoo);library(zyp)
library(trend);library(dplyr)
library(AICcmodavg);library(nlme)
library(gtools)
setwd('c:/users/sean.hardison/desktop/simulations')
ptm <- proc.time()

fit_lm <- function(dat, ar, m, ARsd, trend, spec = FALSE){
  success <- FALSE
  while(!success){
    dat <- dat %>% dplyr::filter(complete.cases(.))
    
    # Constant model (null model used to calculate 
    # overall p-value)
    constant_norm <-nlme::gls(series ~ 1, data = dat)
    
    #spec parameter specifies whether arima.sim incorporated AR(1) error process. When there is no 
    #AR error in the time series, we switch the GLS models to all rely on a normal error generating process.
    if (!spec){
      constant_ar1 <-
        try(nlme::gls(series ~ 1,
                      data = dat,
                      correlation = nlme::corAR1(form = ~time)))
      if (class(constant_ar1) == "try-error"){
        return(best_lm <- data.frame(model = NA,
                                     aicc  = NA,
                                     coefs..Intercept = NA,
                                     coefs.time = NA,
                                     coefs.time2 = NA,
                                     pval = NA))
      }
      
    } else {
      constant_ar1 <-
        try(nlme::gls(series ~ 1,
                      data = dat))
      if (class(constant_ar1) == "try-error"){
        return(best_lm <- data.frame(model = NA,
                                     aicc  = NA,
                                     coefs..Intercept = NA,
                                     coefs.time = NA,
                                     coefs.time2 = NA,
                                     pval = NA))
      }
    }
    # Linear model with normal error
    linear_norm <- nlme::gls(series ~ time, data = dat)
    
    # Linear model with AR1 error
    if (!spec){
      linear_ar1 <- 
        try(nlme::gls(series ~ time, 
                      data = dat,
                      correlation = nlme::corAR1(form = ~time)))
      if (class(linear_ar1) == "try-error"){
        return(best_lm <- data.frame(model = NA,
                                     aicc  = NA,
                                     coefs..Intercept = NA,
                                     coefs.time = NA,
                                     coefs.time2 = NA,
                                     pval = NA))
        }
      } else {
        linear_ar1 <- 
          try(nlme::gls(series ~ time, 
                        data = dat))
        if (class(linear_ar1) == "try-error"){
          return(best_lm <- data.frame(model = NA,
                                       aicc  = NA,
                                       coefs..Intercept = NA,
                                       coefs.time = NA,
                                       coefs.time2 = NA,
                                       pval = NA))
      }
    }
    linear_phi <- linear_ar1$modelStruct$corStruct
    linear_phi <-coef(linear_phi, unconstrained = FALSE)
    
    # Polynomial model with normal error
    dat$time2 <- dat$time^2
    poly_norm <- nlme::gls(series ~ time + time2, data = dat)
    
    # Polynomial model with AR1 error
    if (!spec){
      poly_ar1 <- 
        try(nlme::gls(series ~ time + time2, 
                      data = dat,
                      correlation = nlme::corAR1(form = ~time)))
      if (class(poly_ar1) == "try-error"){
        return(best_lm <- data.frame(model = NA,
                                     aicc  = NA,
                                     coefs..Intercept = NA,
                                     coefs.time = NA,
                                     coefs.time2 = NA,
                                     pval = NA))
        
      }
    }else {
      poly_ar1 <- 
        try(nlme::gls(series ~ time + time2, 
                      data = dat))
      if (class(poly_ar1) == "try-error"){
        return(best_lm <- data.frame(model = NA,
                                     aicc  = NA,
                                     coefs..Intercept = NA,
                                     coefs.time = NA,
                                     coefs.time2 = NA,
                                     pval = NA))
        
      }
    }
    poly_phi <- poly_ar1$modelStruct$corStruct
    poly_phi <- coef(poly_phi, unconstrained = FALSE)
    
    # Calculate AICs for all models
    df_aicc <-
      data.frame(model = c("poly_norm",
                           "poly_ar1",
                           "linear_norm",
                           "linear_ar1"),
                 aicc  = c(AICc(poly_norm),
                           AICc(poly_ar1),
                           AICc(linear_norm),
                           AICc(linear_ar1)),
                 coefs = rbind(coef(poly_norm),
                               coef(poly_ar1),
                               c(coef(linear_norm), NA),
                               c(coef(linear_ar1),  NA)),
                 phi = c(0, 
                         poly_phi,
                         0,
                         linear_phi),
                 # Calculate overall signifiance (need to use
                 # ML not REML for this)
                 pval = c(anova(update(constant_norm, method = "ML"),
                                update(poly_norm, method = "ML"))$`p-value`[2],
                          anova(update(constant_ar1, method = "ML"),
                                update(poly_ar1, method = "ML"))$`p-value`[2],
                          anova(update(constant_norm, method = "ML"),
                                update(linear_norm, method = "ML"))$`p-value`[2],
                          anova(update(constant_ar1, method = "ML"),
                                update(linear_ar1, method = "ML"))$`p-value`[2]))
    
    best_lm <-
      df_aicc %>%
      dplyr::filter(aicc == min(aicc))
    if (nrow(best_lm) >1){
      best_lm <- best_lm[1,]
    }
    phi <- best_lm$phi
    success <- (phi <= 0.8 & !invalid(phi))
    
    
    dat <- trend + dat
    dat <- arima.sim(list(ar = ar), n=m, rand.gen=rnorm, sd = ARsd)
    dat <- data.frame(series = dat,
                      time = 1:length(dat))
    
  }
  if (best_lm$model == "poly_norm") {
    model <- poly_norm
  } else if (best_lm$model == "poly_ar1") {
    model <- poly_ar1
  } else if (best_lm$model == "linear_norm") {
    model <- linear_norm
  } else if (best_lm$model == "linear_ar1") {
    model <- linear_ar1
  }
  return(list(best_lm = best_lm, 
              model = model))
}


set.seed(123)
n = 100 #number of simulations
ARsd <- .54^.5 #standard deviation of innovations

#Autocorrelation
NOAR <- list()
weakAR <- 0.1
medAR <- 0.433
strongAR <- 0.8

#placeholders for results
gls.ts.NOAR.notrend <- NULL
gls.ts.NOAR.ltrendweak <- NULL
gls.ts.NOAR.ltrendmed <- NULL
gls.ts.NOAR.ltrendstrong <- NULL

gls.ts.medAR.notrend <- NULL
gls.ts.medAR.ltrendweak <- NULL
gls.ts.medAR.ltrendmed <- NULL
gls.ts.medAR.ltrendstrong <- NULL

gls.ts.strongAR.notrend <- NULL
gls.ts.strongAR.ltrendweak <- NULL
gls.ts.strongAR.ltrendmed <- NULL
gls.ts.strongAR.ltrendstrong <- NULL

sim_results_10 <- NULL
sim_results_20 <- NULL
sim_results_30 <- NULL


#Specify time series length
for (m in c(10,20,30)){
  
  notrend <- rep(0,m)
  ltrendweak <- -0.262 + (0.004 * c(1:m)) 
  ltrendmed <- -0.262 + (0.051 * c(1:m)) 
  ltrendstrong <- -0.262 + (0.147 * c(1:m)) 
  print(paste("m=",m))

    #Trend strength
    for (k in c("notrend","ltrendweak","ltrendmed","ltrendstrong")){
    
    #AR strength
    for (j in c("strongAR","medAR","NOAR")){
    
      true_trend <- get(k)
      
      for (i in 1:n){
        
        #generate simulations
        dat <- arima.sim(list(ar = get(j)), n=m, rand.gen=rnorm, sd = ARsd)
        
        #add autocorrelated error structure to trend
        dat <- get(k) + dat
        dat <- data.frame(series = dat,
                          time = 1:length(dat))
        
        #---------------------------------GLS---------------------------------#
        gls_sim <- tryCatch({
          newtime <- seq(1, m, 1)
          newdata <- data.frame(time = newtime,
                                time2 = newtime^2)
          
          #Correctly specifies model when no AR error in simulated time series
          if (j == "NOAR"){
            gls_sim <- fit_lm(dat = dat, ar = get(j),
                              ARsd = ARsd, m = m, trend = get(k), spec = TRUE)
          } else{
            gls_sim <- fit_lm(dat = dat, ar = get(j), ARsd = ARsd, m = m, trend = get(k))
            
          }
          
        }, 
        error = function(e) {
          gls_sim <- "error"
        })
        
        if (is.na(gls_sim[1]) | gls_sim[1] == "error"){
          gls_pred <- rep(NA, m)
        } else {
          gls_pred <- AICcmodavg::predictSE(gls_sim$model,
                                            newdata = newdata,
                                            se.fit = TRUE)
        }
        
        
        #---------------------------------Decile coverage---------------------------------#
        decile_of_true <- ceiling(10 * pnorm(q    = true_trend, 
                                           mean = gls_pred$fit, 
                                           sd   = gls_pred$se.fit))
        
        for (g in 1:m){
          if (is.na(gls_pred$fit[1])){
            print("NA")
            assign(paste0("gls.ts.",j,".",k),rbind(get(paste0("gls.ts.",j,".",k)),NA))
          } else {
            assign(paste0("gls.ts.",j,".",k),rbind(get(paste0("gls.ts.",j,".",k)),decile_of_true[g]))
          }
          
        }
          
        
      } 
      
    }
  }
  sim_results = data.frame(gls.NOAR.ltrendweak = gls.ts.NOAR.ltrendweak,
                           gls.NOAR.ltrendmed = gls.ts.NOAR.ltrendmed,
                           gls.NOAR.ltrendstrong = gls.ts.NOAR.ltrendstrong,
                           gls.NOAR.notrend = gls.ts.NOAR.notrend,

                           gls.medAR.ltrendweak = gls.ts.medAR.ltrendweak,
                           gls.medAR.ltrendmed = gls.ts.medAR.ltrendmed,
                           gls.medAR.ltrendstrong = gls.ts.medAR.ltrendstrong,
                           gls.medAR.notrend = gls.ts.medAR.notrend,

                           gls.strongAR.ltrendweak = gls.ts.strongAR.ltrendweak,
                           gls.strongAR.ltrendmed = gls.ts.strongAR.ltrendmed,
                           gls.strongAR.ltrendstrong = gls.ts.strongAR.ltrendstrong,
                           gls.strongAR.notrend = gls.ts.strongAR.notrend)

    assign(paste0('sim_results_',m), rbind(get(paste0('sim_results_',m)),sim_results))
    write.csv(sim_results, file = paste0("decile_coverage_results_",m,Sys.Date(),".csv"))
    
    gls.ts.NOAR.notrend <- NULL
    gls.ts.NOAR.ltrendweak <- NULL
    gls.ts.NOAR.ltrendmed <- NULL
    gls.ts.NOAR.ltrendstrong <- NULL
    
    gls.ts.medAR.notrend <- NULL
    gls.ts.medAR.ltrendweak <- NULL
    gls.ts.medAR.ltrendmed <- NULL
    gls.ts.medAR.ltrendstrong <- NULL
    
    gls.ts.strongAR.notrend <- NULL
    gls.ts.strongAR.ltrendweak <- NULL
    gls.ts.strongAR.ltrendmed <- NULL
    gls.ts.strongAR.ltrendstrong <- NULL
    
}


