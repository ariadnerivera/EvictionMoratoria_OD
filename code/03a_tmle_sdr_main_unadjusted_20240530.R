#This code includes in models:
# - CDC Moratoria
# - Lagged outcome



# For lmtp package use the package on Nick William's repository as it allows
# for different covariate sets for treatment and outcome regressions
# devtools::install_github("nt-williams/lmtp@separate-variable-sets")

library(haven)
library(future)
library(lmtp)
library(progressr)
library(tidyverse)
library(SuperLearner)
library(foreach)
library(doParallel)


#setwd
setwd("~/EvictionMoratoria_OD")

#load dataset
data <- read_dta("data/analysis_county_march2020_dec2021.dta")

data <- data %>% rename(StringencyIndex = StringencyIndex_Average,
                        GovernmentResponseIndex = GovernmentResponseIndex_Average,
                        ContainmentHealthIndex = ContainmentHealthIndex_Average)


# Subset variables needed
myvars <- c("geofips", "StateFIPS", "Year", "YearMonth", "MonthNum", 
            "popdensity_state", "mhhinc_state", "pct_pop18under_state", 
            "pct_pop18_34_state", "pct_pop35to64_state", "pct_pop65plus_state",
            "pct_popfemale_state", "pct_popNHWhite_state", 
            "pct_popNHBlack_state", "pct_popHispanic_state", 
            "pct_popNHOther_state", "pct_hhssinc_state",
            "pct_hhpai_state", "pct_poprenterhu_state",
            "pct_rent30to49_state", "pct_rent50plus_state",
            "pct_pophealthins_state", "pct_poppoverty_state", 
            "anymentaldx18plus_p", "needtrx18plus_p", "needtrx26plus_p", "sud18plus_p", 
            "pctfentintopdrug", "covidratenew_state", "coviddeathratenew_state",       
            "GovernmentResponseIndex", "StringencyIndex", 
            "ContainmentHealthIndex", "administered_dose1_pop_pct_state",             
            "totpop", "popdensity", "mhhinc", "gini", "pct_pop18under",
            "pct_pop18_34", "pct_pop35to64", "pct_pop65plus", "pct_popfemale", 
            "pct_popNHWhite", "pct_popNHBlack", "pct_popHispanic", 
            "pct_hhssinc", "pct_hhpai", "pct_poprenterhu", "pct_poppoverty", 
            "pct_rent30to49", "pct_rent50plus", "pct_pophealthins", 
            "pct_repvotes2016", "pct_demvotes2016", "pct_othervotes2016",
            "rxrate", "metro", "covidratenew", "coviddeathratenew",        
            "medcomtranscat",  "medcomtranscat_state",
            "administered_dose1_pop_pct", "LiftMoratoria", "LiftMoratoriaO", 
            "LiftMoratoriaObin", "CDC_moratoria", "ODDeathOccurrenceCount", 
            "odtotal_state", "odrate", "odrate_state", "econimpactindex",  
            "econimpactindex_median", "lau_unemprate", "pct_overcrowding", 
            "pct_overcrowding_state", "L_overcrowding", "L_pct_overcrowding",
            "L_overcrowding_state", "L_pct_overcrowding_state", "CaresAct", 
            "cumodcount", "cumodrate", "cumodratemon", "pct_repvotes_state2016",
            "L_covidratenew_state", "L_coviddeathratenew_state", 
            "L_GovernmentResponseIndex", "L_econimpactindex_median") 

data2 <- data[myvars]

data2 <- data2[order(data2$geofips, data2$YearMonth),]

data2$intercept <- 1

#data3 <- subset(data2, StateFIPS !=2)

# Reshape dataset from long to wide format
df <- data2 %>%
  pivot_wider(
    id_cols = c(geofips, StateFIPS),
    names_from = MonthNum,
    names_sep = "",
    values_from = c("popdensity_state", "mhhinc_state",      
                    "pct_pop18under_state", "pct_pop18_34_state", 
                    "pct_pop35to64_state", "pct_pop65plus_state",
                    "pct_popfemale_state", "pct_popNHWhite_state",
                    "pct_popNHBlack_state", "pct_popHispanic_state", 
                    "pct_popNHOther_state", "pct_hhssinc_state",
                    "pct_hhpai_state", "pct_poprenterhu_state",
                    "pct_rent30to49_state", "pct_rent50plus_state",
                    "pct_pophealthins_state", "pct_poppoverty_state", 
                    "anymentaldx18plus_p", 
                    "needtrx18plus_p", "needtrx26plus_p", "sud18plus_p",
                    "pctfentintopdrug", "covidratenew_state", 
                    "coviddeathratenew_state",
                    "GovernmentResponseIndex", "StringencyIndex", 
                    "ContainmentHealthIndex", "administered_dose1_pop_pct_state",             
                    "totpop", "popdensity", "mhhinc", "gini", "pct_pop18under",
                    "pct_pop18_34", "pct_pop35to64", "pct_pop65plus",   
                    "pct_popfemale", "pct_popNHWhite", "pct_popNHBlack",
                    "pct_popHispanic", "pct_hhssinc", "pct_hhpai",
                    "pct_poprenterhu", "pct_poppoverty", "pct_rent30to49",
                    "pct_rent50plus", "pct_pophealthins", "pct_repvotes2016", 
                    "pct_demvotes2016", "pct_othervotes2016","rxrate", "metro", 
                    "covidratenew", "coviddeathratenew",       
                    "medcomtranscat", "medcomtranscat_state", 
                    "administered_dose1_pop_pct", "LiftMoratoria", 
                    "LiftMoratoriaObin", "LiftMoratoriaO", "CDC_moratoria",
                    "odrate", "odrate_state", "econimpactindex",
                    "econimpactindex_median", "lau_unemprate", "pct_overcrowding", 
                    "pct_overcrowding_state", "L_overcrowding", 
                    "L_pct_overcrowding", "L_overcrowding_state", 
                    "L_pct_overcrowding_state", "CaresAct", "intercept",
                    "ODDeathOccurrenceCount", "odtotal_state", "cumodcount", 
                    "cumodrate", "cumodratemon", "pct_repvotes_state2016",
                    "L_covidratenew_state", "L_coviddeathratenew_state", 
                    "L_GovernmentResponseIndex", "L_econimpactindex_median")) 

#Check if there are counties with missing data
complete_rows <- complete.cases(df)

sum(complete_rows)

#which(is.na(df$L_coviddeathratenew_state1))

which(is.na(df))

#Identify the exposure
a <- names(df[, paste0("LiftMoratoriaObin", 2:20)])

# CDC Eviction Moratoria
CDC_moratoria <- c("CDC_moratoria")

# State covariates
## Baseline state-level - not time-varying demographic data is annual
statebaseline <- c("popdensity_state", 
                   "mhhinc_state", 
                   "pct_pop18_34_state", 
                   "pct_pop35to64_state", 
                   "pct_pop65plus_state",
                   "pct_popNHWhite_state",
                   "pct_poprenterhu_state", 
                   "pct_rent30to49_state", 
                   "pct_rent50plus_state", 
                   "pct_repvotes_state2016",
                   "pct_overcrowding_state")

#State-level covariates time-varying (covid deaths, cases, & unemployment rate)
statetimevarying <- c("covidratenew_state", "coviddeathratenew_state", 
                      "ContainmentHealthIndex", "econimpactindex_median")

statevaccines <- c("administered_dose1_pop_pct_state")


ctybaseline <- c("popdensity", "mhhinc", "gini", "pct_pop18_34", 
                 "pct_pop35to64", "pct_pop65plus", "pct_popfemale", 
                 "pct_popNHWhite", "pct_hhssinc", "pct_hhpai", 
                 "pct_poprenterhu", "pct_poppoverty", "pct_rent30to49", 
                 "pct_rent50plus", "pct_pophealthins", "pct_repvotes2016", 
                 "pct_demvotes2016","rxrate", "anymentaldx18plus_p", 
                 "needtrx18plus_p", "sud18plus_p","metro", "pctfentintopdrug", 
                 "pct_overcrowding")

#County-level covariates time-varying (demographic data are annual, _Index variables are state-level)
ctytimevarying <- c("covidratenew", "coviddeathratenew", 
                    "ContainmentHealthIndex", 
                    "medcomtranscat", "lau_unemprate")

ctyvaccines <- c("administered_dose1_pop_pct")

#Outcome at the state
outcomestate <- c("odrate_state")

#Outcome at the county
outcomecty <- c("odrate")

interceptvar <- c("intercept")

#Treatment uses variables at the state-evel and the outcome at the state and county level
unadjusted <- list(trt = 
                     list(c(paste0(interceptvar, "2")),
                          c(paste0(interceptvar, "3")),
                          c(paste0(interceptvar, "4")),
                          c(paste0(interceptvar, "5")),
                          c(paste0(interceptvar, "6")),
                          c(paste0(interceptvar, "7")),
                          c(paste0(interceptvar, "8")),
                          c(paste0(interceptvar, "9")),
                          c(paste0(interceptvar, "10")),
                          c(paste0(interceptvar, "11")),
                          c(paste0(interceptvar, "12")),
                          c(paste0(interceptvar, "13")),
                          c(paste0(interceptvar, "14")),
                          c(paste0(interceptvar, "15")),
                          c(paste0(interceptvar, "16")),
                          c(paste0(interceptvar, "17")),
                          c(paste0(interceptvar, "18")),
                          c(paste0(interceptvar, "19")),
                          c(paste0(interceptvar, "20"))),
                   cens = c(lapply(1:19, function(x) NULL)),
                   outcome =
                     list(c(paste0(interceptvar, "2")),
                          c(paste0(interceptvar, "3")), 
                          c(paste0(interceptvar, "4")), 
                          c(paste0(interceptvar, "5")), 
                          c(paste0(interceptvar, "6")),
                          c(paste0(interceptvar, "7")),
                          c(paste0(interceptvar, "8")),
                          c(paste0(interceptvar, "9")),
                          c(paste0(interceptvar, "10")),
                          c(paste0(interceptvar, "11")),
                          c(paste0(interceptvar, "12")),
                          c(paste0(interceptvar, "13")),
                          c(paste0(interceptvar, "14")),
                          c(paste0(interceptvar, "15")),
                          c(paste0(interceptvar, "16")),
                          c(paste0(interceptvar, "17")),
                          c(paste0(interceptvar, "18")),
                          c(paste0(interceptvar, "19")),
                          c(paste0(interceptvar, "20")))) 


multisession(workers = 8)
options(mc.cores=8)
availableCores()
getOption("mc.cores")
plan(multisession)

set.seed(29022024)

learner <- c("SL.glmnet", "SL.mean", "SL.xgboost", "SL.earth")


##############################################
##############################################

### TMLE models
startTime <- Sys.time() 
startTime
with_progress(psi.tmle.mtp.county.unadjusted_updated.shift <- lmtp_tmle(df, trt = a,
                                                                      outcome="cumodratemon21",
                                                                     time_vary=unadjusted,
                                                                     cens = NULL,
                                                                     shift = static_binary_on,
                                                                     id="geofips" ,
                                                                     outcome_type="continuous",
                                                                     learners_outcome = learner,
                                                                     learners_trt = learner,
                                                                     folds = 2,
                                                                     k = 4))
                
warnings()

endTime <- Sys.time() 
endTime

startTime-endTime

saveRDS(psi.tmle.mtp.county.unadjusted_updated.shift, "results/manuscript_updated/main_unadjusted/shift_tmle_unadjusted_20240530.rds")

startTime2 <- Sys.time() 

with_progress(psi.tmle.mtp.county.unadjusted_updated.ref <- lmtp_tmle(df, trt = a,
                                                                   outcome="cumodratemon21",
                                                                   time_vary=unadjusted,
                                                                   cens = NULL,
                                                                   shift = static_binary_off,
                                                                   id="geofips" ,
                                                                   outcome_type="continuous",
                                                                   learners_outcome = learner,
                                                                   learners_trt = learner,
                                                                   folds = 2,
                                                                   k = 4))


warnings()

endTime2 <- Sys.time() 
endTime2
startTime2-endTime2

saveRDS(psi.tmle.mtp.county.unadjusted_updated.ref, "results/manuscript_updated/main_unadjusted/ref_tmle_unadjusted_20240530.rds")

##############################################
##############################################

### SDR models

startTime <- Sys.time() 
startTime
with_progress(psi.sdr.mtp.county.unadjusted_updated.shift <- lmtp_sdr(df, trt = a,
                                                                   outcome="cumodratemon21",
                                                                   time_vary=unadjusted,
                                                                   cens = NULL,
                                                                   shift = static_binary_on,
                                                                   id="geofips" ,
                                                                   outcome_type="continuous",
                                                                   learners_outcome = learner,
                                                                   learners_trt = learner,
                                                                   folds = 2,
                                                                   k = 4))
warnings()

endTime <- Sys.time() 

startTime-endTime

saveRDS(psi.sdr.mtp.county.unadjusted_updated.shift, "results/manuscript_updated/main_unadjusted/shift_sdr_unadjusted_20240530.rds")

startTime2 <- Sys.time() 

with_progress(psi.sdr.mtp.county.unadjusted_updated.ref <- lmtp_sdr(df, trt = a,
                                                                 outcome="cumodratemon21",
                                                                 time_vary=unadjusted,
                                                                 cens = NULL,
                                                                 shift = static_binary_off,
                                                                 id="geofips" ,
                                                                 outcome_type="continuous",
                                                                 learners_outcome = learner,
                                                                 learners_trt = learner,
                                                                 folds = 2,
                                                                 k = 4))
                

warnings()

endTime2 <- Sys.time() 
endTime2
startTime2-endTime2

saveRDS(psi.sdr.mtp.county.unadjusted_updated.ref, "results/manuscript_updated/main_unadjusted/ref_sdr_unadjusted_20240530.rds")
                
                

