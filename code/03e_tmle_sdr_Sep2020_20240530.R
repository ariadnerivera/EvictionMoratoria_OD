#This code stratifies states whether they lifted the moratoria prior the CDC Moratoria or not. 
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
myvars <- c("geofips", "StateFIPS", "StateAbbreviation", "Year", "YearMonth", "MonthNum", 
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
    id_cols = c(geofips, StateFIPS, StateAbbreviation ),
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

##

beforeSep <- c("CO", "KS", "ME", "IN", "AK", "DE", "LA", "MI", "NC", "NH", 
               "RI", "AL", "IA", "NE", "MS", "MT", "TN", "TX", "VA", "WI", 
               "WV", "ID", "ND", "SC", "UT", "CA",  "DC", "IL", "MN", "NJ", 
               "NM", "NY", "MA")



df_beforeSep <- df[df$StateAbbreviation %in% beforeSep, ]

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

#Treatment uses variables at the state-evel and the outcome at the state and county level
allvars <- list(trt = 
                  list(c(paste0(statebaseline, rep("2", 11)), paste0(statetimevarying, rep("1", 4)), paste0(outcomestate, "1")),
                       c(paste0(statebaseline, rep("3", 11)), paste0(statetimevarying, rep("2", 4)), paste0(outcomestate, "2")),
                       c(paste0(statebaseline, rep("4", 11)), paste0(statetimevarying, rep("3", 4)), paste0(outcomestate, "3")),
                       c(paste0(statebaseline, rep("5", 11)), paste0(statetimevarying, rep("4", 4)), paste0(outcomestate, "4")),
                       c(paste0(statebaseline, rep("6", 11)), paste0(statetimevarying, rep("5", 4)), paste0(outcomestate, "5")),
                       c(paste0(statebaseline, rep("7", 11)), paste0(statetimevarying, rep("6", 4)), paste0(outcomestate, "6")),
                       c(paste0(statebaseline, rep("8", 11)), paste0(statetimevarying, rep("7", 4)), paste0(outcomestate, "7")),
                       c(paste0(statebaseline, rep("9", 11)), paste0(statetimevarying, rep("8", 4)), paste0(outcomestate, "8")),
                       c(paste0(statebaseline, rep("10", 11)), paste0(statetimevarying, rep("9", 4)), paste0(outcomestate, "9")),
                       c(paste0(statebaseline, rep("11", 11)), paste0(statetimevarying, rep("10", 4)), paste0(outcomestate, "10"), paste0(statevaccines, "10")),
                       c(paste0(statebaseline, rep("12", 11)), paste0(statetimevarying, rep("11", 4)), paste0(outcomestate, "11"), paste0(statevaccines, "11")),
                       c(paste0(statebaseline, rep("13", 11)), paste0(statetimevarying, rep("12", 4)), paste0(outcomestate, "12"), paste0(statevaccines, "12")),
                       c(paste0(statebaseline, rep("14", 11)), paste0(statetimevarying, rep("13", 4)), paste0(outcomestate, "13"), paste0(statevaccines, "13")),
                       c(paste0(statebaseline, rep("15", 11)), paste0(statetimevarying, rep("14", 4)), paste0(outcomestate, "14"), paste0(statevaccines, "14")),
                       c(paste0(statebaseline, rep("16", 11)), paste0(statetimevarying, rep("15", 4)), paste0(outcomestate, "15"), paste0(statevaccines, "15")),
                       c(paste0(statebaseline, rep("17", 11)), paste0(statetimevarying, rep("16", 4)), paste0(outcomestate, "16"), paste0(statevaccines, "16")),
                       c(paste0(statebaseline, rep("18", 11)), paste0(statetimevarying, rep("17", 4)), paste0(outcomestate, "17"), paste0(statevaccines, "17")),
                       c(paste0(statebaseline, rep("19", 11)), paste0(statetimevarying, rep("18", 4)), paste0(outcomestate, "18"), paste0(statevaccines, "18")),
                       c(paste0(statebaseline, rep("20", 11)), paste0(statetimevarying, rep("19", 4)), paste0(outcomestate, "19"), paste0(statevaccines, "19"))),
                
                cens = c(lapply(1:19, function(x) NULL)),
                outcome =
                  list(c(paste0(ctybaseline, rep("2", 24)), paste0(ctytimevarying, rep("1", 5)), paste0(outcomecty, "1")),
                       c(paste0(ctybaseline, rep("3", 24)), paste0(ctytimevarying, rep("2", 5)), paste0(outcomecty, "2")),
                       c(paste0(ctybaseline, rep("4", 24)), paste0(ctytimevarying, rep("3", 5)), paste0(outcomecty, "3")),
                       c(paste0(ctybaseline, rep("5", 24)), paste0(ctytimevarying, rep("4", 5)), paste0(outcomecty, "4")),
                       c(paste0(ctybaseline, rep("6", 24)), paste0(ctytimevarying, rep("5", 5)), paste0(outcomecty, "5")),
                       c(paste0(ctybaseline, rep("7", 24)), paste0(ctytimevarying, rep("6", 5)), paste0(outcomecty, "6")),
                       c(paste0(ctybaseline, rep("8", 24)), paste0(ctytimevarying, rep("7", 5)), paste0(outcomecty, "7")),
                       c(paste0(ctybaseline, rep("9", 24)), paste0(ctytimevarying, rep("8", 5)), paste0(outcomecty, "8")),
                       c(paste0(ctybaseline, rep("10", 24)), paste0(ctytimevarying, rep("9", 5)), paste0(outcomecty, "9")),
                       c(paste0(ctybaseline, rep("11", 24)), paste0(ctytimevarying, rep("10", 5)), paste0(outcomecty, "10"), paste0(ctyvaccines, "10")),
                       c(paste0(ctybaseline, rep("12", 24)), paste0(ctytimevarying, rep("11", 5)), paste0(outcomecty, "11"), paste0(ctyvaccines, "11")),
                       c(paste0(ctybaseline, rep("13", 24)), paste0(ctytimevarying, rep("12", 5)), paste0(outcomecty, "12"), paste0(ctyvaccines, "12")),
                       c(paste0(ctybaseline, rep("14", 24)), paste0(ctytimevarying, rep("13", 5)), paste0(outcomecty, "13"), paste0(ctyvaccines, "13")),
                       c(paste0(ctybaseline, rep("15", 24)), paste0(ctytimevarying, rep("14", 5)), paste0(outcomecty, "14"), paste0(ctyvaccines, "14")),
                       c(paste0(ctybaseline, rep("16", 24)), paste0(ctytimevarying, rep("15", 5)), paste0(outcomecty, "15"), paste0(ctyvaccines, "15")),
                       c(paste0(ctybaseline, rep("17", 24)), paste0(ctytimevarying, rep("16", 5)), paste0(outcomecty, "16"), paste0(ctyvaccines, "16")),
                       c(paste0(ctybaseline, rep("18", 24)), paste0(ctytimevarying, rep("17", 5)), paste0(outcomecty, "17"), paste0(ctyvaccines, "17")),
                       c(paste0(ctybaseline, rep("19", 24)), paste0(ctytimevarying, rep("18", 5)), paste0(outcomecty, "18"), paste0(ctyvaccines, "18")),
                       c(paste0(ctybaseline, rep("20", 24)), paste0(ctytimevarying, rep("19", 5)), paste0(outcomecty, "19"), paste0(ctyvaccines, "19"))))



                
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
with_progress(psi.tmle.mtp.county.allvars_beforeSep.shift <- lmtp_tmle(df_beforeSep, trt = a,
                                                                      outcome="cumodratemon21",
                                                                     time_vary=allvars,
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

saveRDS(psi.tmle.mtp.county.allvars_beforeSep.shift, "results/manuscript_updated/sep2020/shift_tmle_beforeSep_20240530.rds")

startTime2 <- Sys.time() 

with_progress(psi.tmle.mtp.county.allvars_beforeSep_beforeSep.ref <- lmtp_tmle(df_beforeSep, trt = a,
                                                                   outcome="cumodratemon21",
                                                                   time_vary=allvars,
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

saveRDS(psi.tmle.mtp.county.allvars_beforeSep_beforeSep.ref, "results/manuscript_updated/sep2020/ref_tmle_beforeSep_20240530.rds")

##############################################
##############################################

### SDR models

startTime <- Sys.time() 
startTime
with_progress(psi.sdr.mtp.county.allvars_beforeSep.shift <- lmtp_sdr(df_beforeSep, trt = a,
                                                                   outcome="cumodratemon21",
                                                                   time_vary=allvars,
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

saveRDS(psi.sdr.mtp.county.allvars_beforeSep.shift, "results/manuscript_updated/sep2020/shift_sdr_beforeSep_20240530.rds")

startTime2 <- Sys.time() 

with_progress(psi.sdr.mtp.county.allvars_beforeSep.ref <- lmtp_sdr(df_beforeSep, trt = a,
                                                                 outcome="cumodratemon21",
                                                                 time_vary=allvars,
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

saveRDS(psi.sdr.mtp.county.allvars_beforeSep.ref, "results/manuscript_updated/sep2020/ref_sdr_beforeSep_20240530.rds")
                
######################################################################
######################################################################


data3 <- subset(data2, MonthNum >= 5)

# Reshape dataset from long to wide format
df3 <- data3 %>%
  pivot_wider(
    id_cols = c(geofips, StateFIPS, StateAbbreviation ),
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
complete_rows <- complete.cases(data3)

sum(complete_rows)

#which(is.na(df$L_coviddeathratenew_state1))

which(is.na(data3))

#Identify the exposure

afterSep <-  c("CA",  "DC", "IL", "MN", "NJ", "NM", "NY", "MA", "HI", "MD", 
               "CT", "OR", "VT", "WA", "AZ", "FL", "NV", "KY", "PA")


df_afterSep <- df3[df3$StateAbbreviation %in% afterSep, ]


a <- names(df3[, paste0("LiftMoratoriaObin", 6:20)])



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

#Treatment uses variables at the state-evel and the outcome at the state and county level
#Treatment uses variables at the state-evel and the outcome at the state and county level
allvars <- list(trt = 
                  list(c(paste0(statebaseline, rep("6", 11)), paste0(statetimevarying, rep("5", 4)), paste0(outcomestate, "5")),
                       c(paste0(statebaseline, rep("7", 11)), paste0(statetimevarying, rep("6", 4)), paste0(outcomestate, "6")),
                       c(paste0(statebaseline, rep("8", 11)), paste0(statetimevarying, rep("7", 4)), paste0(outcomestate, "7")),
                       c(paste0(statebaseline, rep("9", 11)), paste0(statetimevarying, rep("8", 4)), paste0(outcomestate, "8")),
                       c(paste0(statebaseline, rep("10", 11)), paste0(statetimevarying, rep("9", 4)), paste0(outcomestate, "9")),
                       c(paste0(statebaseline, rep("11", 11)), paste0(statetimevarying, rep("10", 4)), paste0(outcomestate, "10"), paste0(statevaccines, "10")),
                       c(paste0(statebaseline, rep("12", 11)), paste0(statetimevarying, rep("11", 4)), paste0(outcomestate, "11"), paste0(statevaccines, "11")),
                       c(paste0(statebaseline, rep("13", 11)), paste0(statetimevarying, rep("12", 4)), paste0(outcomestate, "12"), paste0(statevaccines, "12")),
                       c(paste0(statebaseline, rep("14", 11)), paste0(statetimevarying, rep("13", 4)), paste0(outcomestate, "13"), paste0(statevaccines, "13")),
                       c(paste0(statebaseline, rep("15", 11)), paste0(statetimevarying, rep("14", 4)), paste0(outcomestate, "14"), paste0(statevaccines, "14")),
                       c(paste0(statebaseline, rep("16", 11)), paste0(statetimevarying, rep("15", 4)), paste0(outcomestate, "15"), paste0(statevaccines, "15")),
                       c(paste0(statebaseline, rep("17", 11)), paste0(statetimevarying, rep("16", 4)), paste0(outcomestate, "16"), paste0(statevaccines, "16")),
                       c(paste0(statebaseline, rep("18", 11)), paste0(statetimevarying, rep("17", 4)), paste0(outcomestate, "17"), paste0(statevaccines, "17")),
                       c(paste0(statebaseline, rep("19", 11)), paste0(statetimevarying, rep("18", 4)), paste0(outcomestate, "18"), paste0(statevaccines, "18")),
                       c(paste0(statebaseline, rep("20", 11)), paste0(statetimevarying, rep("19", 4)), paste0(outcomestate, "19"), paste0(statevaccines, "19"))),
                
                cens = c(lapply(1:15, function(x) NULL)),
                outcome =
                  list(c(paste0(ctybaseline, rep("6", 24)), paste0(ctytimevarying, rep("5", 5)), paste0(outcomecty, "5")),
                       c(paste0(ctybaseline, rep("7", 24)), paste0(ctytimevarying, rep("6", 5)), paste0(outcomecty, "6")),
                       c(paste0(ctybaseline, rep("8", 24)), paste0(ctytimevarying, rep("7", 5)), paste0(outcomecty, "7")),
                       c(paste0(ctybaseline, rep("9", 24)), paste0(ctytimevarying, rep("8", 5)), paste0(outcomecty, "8")),
                       c(paste0(ctybaseline, rep("10", 24)), paste0(ctytimevarying, rep("9", 5)), paste0(outcomecty, "9")),
                       c(paste0(ctybaseline, rep("11", 24)), paste0(ctytimevarying, rep("10", 5)), paste0(outcomecty, "10"), paste0(ctyvaccines, "10")),
                       c(paste0(ctybaseline, rep("12", 24)), paste0(ctytimevarying, rep("11", 5)), paste0(outcomecty, "11"), paste0(ctyvaccines, "11")),
                       c(paste0(ctybaseline, rep("13", 24)), paste0(ctytimevarying, rep("12", 5)), paste0(outcomecty, "12"), paste0(ctyvaccines, "12")),
                       c(paste0(ctybaseline, rep("14", 24)), paste0(ctytimevarying, rep("13", 5)), paste0(outcomecty, "13"), paste0(ctyvaccines, "13")),
                       c(paste0(ctybaseline, rep("15", 24)), paste0(ctytimevarying, rep("14", 5)), paste0(outcomecty, "14"), paste0(ctyvaccines, "14")),
                       c(paste0(ctybaseline, rep("16", 24)), paste0(ctytimevarying, rep("15", 5)), paste0(outcomecty, "15"), paste0(ctyvaccines, "15")),
                       c(paste0(ctybaseline, rep("17", 24)), paste0(ctytimevarying, rep("16", 5)), paste0(outcomecty, "16"), paste0(ctyvaccines, "16")),
                       c(paste0(ctybaseline, rep("18", 24)), paste0(ctytimevarying, rep("17", 5)), paste0(outcomecty, "17"), paste0(ctyvaccines, "17")),
                       c(paste0(ctybaseline, rep("19", 24)), paste0(ctytimevarying, rep("18", 5)), paste0(outcomecty, "18"), paste0(ctyvaccines, "18")),
                       c(paste0(ctybaseline, rep("20", 24)), paste0(ctytimevarying, rep("19", 5)), paste0(outcomecty, "19"), paste0(ctyvaccines, "19"))))




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
with_progress(psi.tmle.mtp.county.allvars_afterSep.shift <- lmtp_tmle(df_afterSep, trt = a,
                                                                     outcome="cumodratemon21",
                                                                     time_vary=allvars,
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

saveRDS(psi.tmle.mtp.county.allvars_afterSep.shift, "results/manuscript_updated/sep2020/shift_tmle_afterSep_20240530.rds")

startTime2 <- Sys.time() 

with_progress(psi.tmle.mtp.county.allvars_afterSep_afterSep.ref <- lmtp_tmle(df_afterSep, trt = a,
                                                                             outcome="cumodratemon21",
                                                                             time_vary=allvars,
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

saveRDS(psi.tmle.mtp.county.allvars_afterSep_afterSep.ref, "results/manuscript_updated/sep2020/ref_tmle_afterSep_20240530.rds")

##############################################
##############################################

### SDR models

startTime <- Sys.time() 
startTime
with_progress(psi.sdr.mtp.county.allvars_afterSep.shift <- lmtp_sdr(df_afterSep, trt = a,
                                                                   outcome="cumodratemon21",
                                                                   time_vary=allvars,
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

saveRDS(psi.sdr.mtp.county.allvars_afterSep.shift, "results/manuscript_updated/sep2020/shift_sdr_afterSep_20240530.rds")

startTime2 <- Sys.time() 

with_progress(psi.sdr.mtp.county.allvars_afterSep.ref <- lmtp_sdr(df_afterSep, trt = a,
                                                                 outcome="cumodratemon21",
                                                                 time_vary=allvars,
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

saveRDS(psi.sdr.mtp.county.allvars_afterSep.ref, "results/manuscript_updated/sep2020/ref_sdr_afterSep_20240530.rds")
