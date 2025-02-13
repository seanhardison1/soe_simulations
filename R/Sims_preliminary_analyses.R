library(dplyr)
library(ggplot2)
library(cowplot)

load('data.dir/SOE_data_2017.RData')

fields <- c('GOM Benthos Landings','GOM Mesoplanktivore Landings',
            'GOM Macroplanktivore Landings','GOM Macrozoo-piscivore Landings',
            'GOM Benthivore Landings','GOM Piscivore Landings',
            'GOM Benthos Revenue','GOM Mesoplanktivore Revenue',
            'GOM Macroplanktivore Revenue','GOM Macrozoo-piscivore Revenue',
            'GOM Benthivore Revenue','GOM Piscivore Revenue','GOM Benthos Fall',
            'GOM Mesoplanktivore Fall','GOM Macroplanktivore Fall',
            'GOM Macrozoo-piscivore Fall','GOM Benthivore Fall',
            'GOM Piscivore Fall','GOM Benthos Spring',
            'GOM Mesoplanktivore Spring','GOM Macroplanktivore Spring',
            'GOM Macrozoo-piscivore Spring','GOM Benthivore Spring',
            'GOM Piscivore Spring','FALL GOM ESn',
            'SPRING GOM ESn','Right whale population',
            'GOM PPD','GOM Yearly Calanus Anomaly',
            'GOM Yearly Zooplankton Biovolume','GOM Yearly small copeopods anomaly',
            'MAB Benthos Landings','MAB Mesoplanktivore Landings',
            'MAB Macroplanktivore Landings', 'MAB Macrozoo-piscivore Landings',
            'MAB Benthivore Landings','MAB Piscivore Landings',
            'MAB Benthos Revenue','MAB Mesoplanktivore Revenue',
            'MAB Macroplanktivore Revenue', 'MAB Macrozoo-piscivore Revenue',
            'MAB Benthivore Revenue','MAB Piscivore Revenue','MAB Benthos Fall',
            'MAB Mesoplanktivore Fall','MAB Macroplanktivore Fall',
            'MAB Macrozoo-piscivore Fall','MAB Benthivore Fall',
            'MAB Piscivore Fall','MAB Benthos Spring',
            'MAB Mesoplanktivore Spring','MAB Macroplanktivore Spring',
            'MAB Macrozoo-piscivore Spring','MAB Benthivore Spring',
            'MAB Piscivore Spring','FALL MAB ESn',
            'SPRING MAB ESn','Right whale population',
            'MAB PPD','MAB Yearly Calanus Anomaly',
            'MAB Yearly Zooplankton Biovolume','MAB Yearly small copeopods anomaly',
            'Sea Surface Temperature','Gulf Stream Index',
            'Surface temp GB','Bottom temp GB','Stratification (0-50m) GB core',
            'Surface Salinity GB','Bottom salinity GB',
            'Surface temp GOM','Bottom temp GOM',
            'Stratification (0-50m) GOM core',
            'Bottom salinity GOM','Gulf Stream Index',
            'New England fleet count','New England average fleet diversity',
            'New England commercial species diversity','North Atlantic Rec participation',
            'North Atlantic angler trips','Mid-Atlantic fleet count',
            'Mid-Atlantic average fleet diversity','Mid-Atlantic commercial species diversity',
            'Mid-Atlantic Rec participation','Mid-Atlantic angler trips',
            'aquaculture VA hard clams sold','aquaculture VA oysters sold',
            'aquaculture VA hard clams planted','aquaculture VA oysters planted',
            'aquaculture ME Atlantic salmon harvest weight','aquaculture ME trout harvest weight',
            'aquaculture ME blue mussels harvest weight','aquaculture ME oysters harvest weight',
            'aquaculture RI total value value','aquaculture RI oysters sold',
            'GB Benthos Landings','GB Mesoplanktivore Landings',
            'GB Macroplanktivore Landings','GB Macrozoo-piscivore Landings',
            'GB Benthivore Landings','GB Piscivore Landings',
            'GB Benthos Revenue','GB Mesoplanktivore Revenue',
            'GB Macroplanktivore Revenue','GB Macrozoo-piscivore Revenue',
            'GB Benthivore Revenue','GB Piscivore Revenue',
            'GB Piscivore Fall', 'GB Benthivore Fall',
            'GB Macrozoo-piscivore Fall','GB Macroplanktivore Fall',
            'GB Mesoplanktivore Fall','GB Benthos Fall',
            'GB Piscivore Spring', 'GB Benthivore Spring',
            'GB Macrozoo-piscivore Spring','GB Macroplanktivore Spring',
            'GB Mesoplanktivore Spring','GB Benthos Spring',
            'FALL GB ESn','SPRING GB ESn','GBK PPD',
            'GBK Yearly Calanus Anomaly','GBK Yearly Zooplankton Biovolume',
            'GBK Yearly small copeopods anomaly')


nlm <- function(field, lin = NULL, norm = NULL){
  time <- SOE.data[SOE.data$Var == field,]$Time
  end = max(time)
  time = time[1:which(time == end)]
  
  var <- SOE.data[SOE.data$Var == field,]$Value
  var <- var[1:length(time)]
  
  
  if(norm == TRUE){
    var = (var-mean(var))/sd(var)
  } else {
    var = var
  }
  
  if(lin == TRUE){
    time <- c(1:length(time))
    mod <- lm(var ~ time)
    int <- mod$coefficients[1]
    beta <- mod$coefficients[2]
  } else if (lin == FALSE){
    time <- c(1:length(time))
    time2 <- time^2
    mod <- lm(var ~ time + time2)
    int <- mod$coefficients[1]
    beta <- mod$coefficients[c(2,3)]
  }
  out <- c(int, beta)
  return(out)
}
lm_resid <- function(field, lin = NULL, norm = NULL){
  time <- SOE.data[SOE.data$Var == field,]$Time
  end = max(time)
  time = time[1:which(time == end)]
  
  var <- SOE.data[SOE.data$Var == field,]$Value
  var <- var[1:length(time)]
  
  if(norm == TRUE){
    var = (var-mean(var))/sd(var)
  } else {
    var = var
  }
  
  if(lin == TRUE){
    time <- c(1:length(time))
    mod <- lm(var ~ time)$residuals
  } else if (lin == FALSE){
    time <- c(1:length(time))
    time2 <- time^2
    mod <- lm(var ~ time + time2)$residuals
  }
  return(mod)
}



get_dat <- function(field,norm = NULL){
  time <- SOE.data[SOE.data$Var == field,]$Time
  end = max(time)
  time = time[1:which(time == end)]
  
  var <- SOE.data[SOE.data$Var == field,]$Value
  var <- var[1:length(time)]
  
  
  if(norm == TRUE){
    var = (var-mean(var))/sd(var)
  } else {
    var = var
  }
  
  out <- data.frame(var = field,
                    value = var,
                    time = time)
  
  return(out)
  
}

#residuals
lin_resid <- mapply(lm_resid,fields, lin = TRUE, norm = TRUE)

#linear coefficients
beta_lin <- mapply(nlm, fields, lin = TRUE, norm = TRUE)
lin_coefficients <- data.frame("Fields"  = fields,
                               "Intercept" = beta_lin[1,],
                               "beta1" = beta_lin[2,])

#AR
AR_coef <- NULL
arima_intercept <- NULL
sigma2 <- NULL
for (i in 1:length(lin_resid)){
  z <- arima(lin_resid[[i]], c(1,0,0))
  AR_coef[i] <- z$coef[1]
  arima_intercept[i] <- z$coef[2]
  sigma2[i] <- z$sigma2
}
arima_lin_df <- data.frame("Fields" = fields,
                           "AR1 Coef"=AR_coef,
                           "Intercept" = arima_intercept,
                           "Variance" = sigma2)

#normalized time series
out_df <- NULL
for (i in 1:length(fields)){
  out <- get_dat(fields[[i]], norm = TRUE)
  assign('out_df',rbind(out,out_df))
}

#summaries
abs_beta <- abs(beta_lin[2,])
mean_beta1_linear <- mean(abs_beta)
lower_95_beta1 <- quantile(x = abs_beta, probs = 0.05)
upper_95_beta1 <- quantile(x = abs_beta, probs = 0.95)
mean_AR_coef_lin <- mean(AR_coef)
mean_AR_var <- mean(arima_lin_df$Variance)

#plotting 

# out_df <- out_df %>% filter(time > 1965)
# ggplot(data = out_df) + geom_line(aes(x = time, y = value, group = var),
#                                   show.legend = F, color = "grey50")

beta <- ggplot(data = lin_coefficients, aes(x = abs(beta1))) +
  geom_histogram(bins = 124, binwidth = 0.005,
                 fill = "lightblue", color = "black",
                 position = "dodge") +
  scale_y_continuous(expand = c(0,0),
                     limits = c(0,18)) +
  xlab(expression(beta)) +
  ylab("") +
  geom_vline(aes(xintercept = mean_beta1_linear), col = "indianred", size = 1) +
  geom_vline(aes(xintercept = upper_95_beta1), col = "indianred", size = 1, linetype = "dashed") +
  theme_bw() +
  theme(plot.title = element_blank(),
        strip.background = element_blank(),
        axis.text = element_text(size = 9),
        axis.title = element_text(size = 10),
        strip.text = element_text(size = 10)) +
  annotate("text", x = 0, y = 17, label = "A")

ar <- ggplot(data = arima_lin_df, aes(x = abs(AR1.Coef))) +
  geom_histogram(bins = 124, binwidth = 0.05,
                 fill = "lightblue", color = "black",
                 position = "dodge") +
  scale_y_continuous(expand = c(0,0),
                     limits = c(0,18)) +
  xlab(expression(rho)) +
  ylab("") +
  geom_vline(aes(xintercept = mean_AR_coef_lin), col = "indianred", size = 1) +
  theme_bw() +
  theme(plot.title = element_blank(),
        strip.background = element_blank(),
        axis.text = element_text(size = 9),
        axis.title = element_text(size = 10),
        strip.text = element_text(size = 10))  +
  annotate("text", x = 0, y = 17, label = "B")


iv <- ggplot(data = arima_lin_df, aes(x = Variance)) +
  geom_histogram(bins = 124, binwidth = 0.05,
                 fill = "lightblue", color = "black",
                 position = "dodge") +
  scale_y_continuous(expand = c(0,0),
                     limits = c(0,18)) +
  xlab("Innovation variance") +
  ylab("") +
  geom_vline(aes(xintercept = mean_AR_var), col = "indianred", size = 1) +
  theme_bw() +
  theme(plot.title = element_blank(),
        strip.background = element_blank(),
        axis.text = element_text(size = 9),
        axis.title = element_text(size = 10),
        strip.text = element_text(size = 10)) +
  annotate("text", x = 0, y = 17, label = "C")

grid.arrange(arrangeGrob(beta, 
                         ar,
                         iv, 
                         nrow = 1,
                         left = textGrob("Frequency", rot = 90, vjust = 1)), 
             nrow=1)

