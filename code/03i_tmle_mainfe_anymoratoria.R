library(haven)
library(future)
library(lmtp)
library(progressr)
library(tidyverse)
library(SuperLearner)
library(foreach)
library(doParallel)
library(fastDummies)


setwd("~/EvictionMoratoria_OD")

# This code runs analysis for ATE + State FE, intervention redefined for "any moratoria"
model_type <- "anymoratoria_fe"

# Read dataset
data <-
  read_dta("data/3_analytic/analysis_county_march2020_dec2021.dta")


data <- data %>% rename(
  StringencyIndex = StringencyIndex_Average,
  GovernmentResponseIndex = GovernmentResponseIndex_Average,
  ContainmentHealthIndex = ContainmentHealthIndex_Average
)

# Subset variables needed
myvars <- c("geofips", "StateFIPS", "Year", "YearMonth", "MonthNum", 
            "LiftMoratoriaObin", "LiftMoratoriaAny", "LiftMoratoria",
            "CDC_moratoria", "popdensity_state",
            "mhhinc_state", "pct_pop18_34_state", "pct_pop35to64_state",
            "pct_pop65plus_state", "pct_popNHWhite_state", 
            "pct_poprenterhu_state", "pct_rent30to49_state",
            "pct_rent50plus_state", "pct_overcrowding_state",
            "pct_repvotes_state2016", "covidratenew_state", 
            "coviddeathratenew_state", "ContainmentHealthIndex", 
            "econimpactindex_median", "administered_dose1_pop_pct_state",
            "popdensity", "mhhinc", "gini", "pct_pop18_34", "pct_pop35to64", 
            "pct_pop65plus", "pct_popfemale", "pct_popNHWhite", 
            "pct_hhssinc", "pct_hhpai", "pct_poprenterhu", "pct_poppoverty", 
            "pct_rent30to49", "pct_rent50plus", "pct_pophealthins", 
            "pctfentintopdrug", "rxrate", "anymentaldx18plus_p",
            "needtrx18plus_p", "sud18plus_p", "pct_overcrowding", 
            "pct_repvotes2016","pct_demvotes2016", "metro", "covidratenew", 
            "coviddeathratenew", "medcomtranscat", 
            "lau_unemprate", "administered_dose1_pop_pct", "odrate_state", 
            "odrate", "cumodrate", "cumodratemon", "CaresAct", "elrating_tertile") 


data2 <- data[myvars]
data2 <- data2[order(data2$geofips, data2$YearMonth),]

# Reshape dataset from long to wide format
df <- data2 %>%
  pivot_wider(
    id_cols = c(
      geofips,
      StateFIPS,
      pct_repvotes_state2016,
      pct_repvotes2016,
      pct_demvotes2016,
      metro
    ),
    names_from = MonthNum,
    names_sep = "",
    values_from = c(
      "LiftMoratoriaObin", "LiftMoratoriaAny", "LiftMoratoria", "CDC_moratoria",
      "popdensity_state", "mhhinc_state", "pct_pop18_34_state",
      "pct_pop35to64_state", "pct_pop65plus_state", "pct_popNHWhite_state",
      "pct_poprenterhu_state", "pct_rent30to49_state", "pct_rent50plus_state",
      "pct_overcrowding_state", "covidratenew_state", "coviddeathratenew_state",
      "ContainmentHealthIndex", "econimpactindex_median",
      "administered_dose1_pop_pct_state",
      "popdensity", "mhhinc", "gini", "pct_pop18_34", "pct_pop35to64",
      "pct_pop65plus", "pct_popfemale", "pct_popNHWhite", "pct_hhssinc",
      "pct_hhpai", "pct_poprenterhu", "pct_poppoverty", "pct_rent30to49",
      "pct_rent50plus", "pct_pophealthins", "pctfentintopdrug", "rxrate",
      "anymentaldx18plus_p", "needtrx18plus_p", "sud18plus_p",
      "pct_overcrowding", "covidratenew", "coviddeathratenew",
      "medcomtranscat", "lau_unemprate", "administered_dose1_pop_pct",
      "odrate_state", "odrate", "cumodrate", "cumodratemon", "CaresAct"
    )
  )

#Check if there are counties with missing data
complete_rows <- complete.cases(df)

sum(complete_rows)

which(is.na(df))

# Identify the exposure
a <- names(df[, paste0("LiftMoratoriaAny", 2:20)])

#Create dummies for state
df <- dummy_cols(df,
                 select_columns = "StateFIPS")

#State dummies
statedummies <- names(df)[grep("^StateFIPS_", names(df))]

##Annual state-level demographic data
statedemographic <- c(
  "popdensity_state",
  "mhhinc_state",
  "pct_pop18_34_state",
  "pct_pop35to64_state",
  "pct_pop65plus_state",
  "pct_popNHWhite_state",
  "pct_poprenterhu_state",
  "pct_rent30to49_state",
  "pct_rent50plus_state",
  "pct_overcrowding_state"
)

# State-level monthly time-varying covariates
statetimevarying <- c(
  "covidratenew_state",
  "coviddeathratenew_state",
  "ContainmentHealthIndex",
  "econimpactindex_median"
)

statevaccines <- c("administered_dose1_pop_pct_state")

ctydemographic <- c(
  "popdensity",
  "mhhinc",
  "gini",
  "pct_pop18_34",
  "pct_pop35to64",
  "pct_pop65plus",
  "pct_popfemale",
  "pct_popNHWhite",
  "pct_hhssinc",
  "pct_hhpai",
  "pct_poprenterhu",
  "pct_poppoverty",
  "pct_rent30to49",
  "pct_rent50plus",
  "rxrate",
  "anymentaldx18plus_p",
  "needtrx18plus_p",
  "sud18plus_p",
  "pctfentintopdrug",
  "pct_overcrowding"
)

#County-level covariates time-varying (demographic data are annual, _Index variables are state-level)

ctytimevarying <- c(
  "covidratenew",
  "coviddeathratenew",
  "ContainmentHealthIndex",
  "medcomtranscat",
  "lau_unemprate"
)

ctyvaccines <- c("administered_dose1_pop_pct")

#Outcome at the state
outcomestate <- c("odrate_state")

#Outcome at the county
outcomecty <- c("odrate")


# Confounder sets
mytimevary <- list(trt =
                     list(c(paste0(statedemographic, rep("2")), paste0(statetimevarying, rep("1")), paste0(outcomestate, "1")),
                          c(paste0(statedemographic, rep("3")), paste0(statetimevarying, rep("2")), paste0(outcomestate, "2")),
                          c(paste0(statedemographic, rep("4")), paste0(statetimevarying, rep("3")), paste0(outcomestate, "3")),
                          c(paste0(statedemographic, rep("5")), paste0(statetimevarying, rep("4")), paste0(outcomestate, "4")),
                          c(paste0(statedemographic, rep("6")), paste0(statetimevarying, rep("5")), paste0(outcomestate, "5")),
                          c(paste0(statedemographic, rep("7")), paste0(statetimevarying, rep("6")), paste0(outcomestate, "6")),
                          c(paste0(statedemographic, rep("8")), paste0(statetimevarying, rep("7")), paste0(outcomestate, "7")),
                          c(paste0(statedemographic, rep("9")), paste0(statetimevarying, rep("8")), paste0(outcomestate, "8")),
                          c(paste0(statedemographic, rep("10")), paste0(statetimevarying, rep("9")), paste0(outcomestate, "9")),
                          c(paste0(statedemographic, rep("11")), paste0(statetimevarying, rep("10")), paste0(outcomestate, "10"), paste0(statevaccines, "10")),
                          c(paste0(statedemographic, rep("12")), paste0(statetimevarying, rep("11")), paste0(outcomestate, "11"), paste0(statevaccines, "11")),
                          c(paste0(statedemographic, rep("13")), paste0(statetimevarying, rep("12")), paste0(outcomestate, "12"), paste0(statevaccines, "12")),
                          c(paste0(statedemographic, rep("14")), paste0(statetimevarying, rep("13")), paste0(outcomestate, "13"), paste0(statevaccines, "13")),
                          c(paste0(statedemographic, rep("15")), paste0(statetimevarying, rep("14")), paste0(outcomestate, "14"), paste0(statevaccines, "14")),
                          c(paste0(statedemographic, rep("16")), paste0(statetimevarying, rep("15")), paste0(outcomestate, "15"), paste0(statevaccines, "15")),
                          c(paste0(statedemographic, rep("17")), paste0(statetimevarying, rep("16")), paste0(outcomestate, "16"), paste0(statevaccines, "16")),
                          c(paste0(statedemographic, rep("18")), paste0(statetimevarying, rep("17")), paste0(outcomestate, "17"), paste0(statevaccines, "17")),
                          c(paste0(statedemographic, rep("19")), paste0(statetimevarying, rep("18")), paste0(outcomestate, "18"), paste0(statevaccines, "18")),
                          c(paste0(statedemographic, rep("20")), paste0(statetimevarying, rep("19")), paste0(outcomestate, "19"), paste0(statevaccines, "19"))),
                   cens = c(lapply(1:19, function(x) NULL)),
                   outcome =
                     list(c(paste0(ctydemographic, rep("2")), paste0(ctytimevarying, rep("1")), paste0(outcomecty, "1")),
                          c(paste0(ctydemographic, rep("3")), paste0(ctytimevarying, rep("2")), paste0(outcomecty, "2")),
                          c(paste0(ctydemographic, rep("4")), paste0(ctytimevarying, rep("3")), paste0(outcomecty, "3")),
                          c(paste0(ctydemographic, rep("5")), paste0(ctytimevarying, rep("4")), paste0(outcomecty, "4")),
                          c(paste0(ctydemographic, rep("6")), paste0(ctytimevarying, rep("5")), paste0(outcomecty, "5")),
                          c(paste0(ctydemographic, rep("7")), paste0(ctytimevarying, rep("6")), paste0(outcomecty, "6")),
                          c(paste0(ctydemographic, rep("8")), paste0(ctytimevarying, rep("7")), paste0(outcomecty, "7")),
                          c(paste0(ctydemographic, rep("9")), paste0(ctytimevarying, rep("8")), paste0(outcomecty, "8")),
                          c(paste0(ctydemographic, rep("10")), paste0(ctytimevarying, rep("9")), paste0(outcomecty, "9")),
                          c(paste0(ctydemographic, rep("11")), paste0(ctytimevarying, rep("10")), paste0(outcomecty, "10"), paste0(ctyvaccines, "10")),
                          c(paste0(ctydemographic, rep("12")), paste0(ctytimevarying, rep("11")), paste0(outcomecty, "11"), paste0(ctyvaccines, "11")),
                          c(paste0(ctydemographic, rep("13")), paste0(ctytimevarying, rep("12")), paste0(outcomecty, "12"), paste0(ctyvaccines, "12")),
                          c(paste0(ctydemographic, rep("14")), paste0(ctytimevarying, rep("13")), paste0(outcomecty, "13"), paste0(ctyvaccines, "13")),
                          c(paste0(ctydemographic, rep("15")), paste0(ctytimevarying, rep("14")), paste0(outcomecty, "14"), paste0(ctyvaccines, "14")),
                          c(paste0(ctydemographic, rep("16")), paste0(ctytimevarying, rep("15")), paste0(outcomecty, "15"), paste0(ctyvaccines, "15")),
                          c(paste0(ctydemographic, rep("17")), paste0(ctytimevarying, rep("16")), paste0(outcomecty, "16"), paste0(ctyvaccines, "16")),
                          c(paste0(ctydemographic, rep("18")), paste0(ctytimevarying, rep("17")), paste0(outcomecty, "17"), paste0(ctyvaccines, "17")),
                          c(paste0(ctydemographic, rep("19")), paste0(ctytimevarying, rep("18")), paste0(outcomecty, "18"), paste0(ctyvaccines, "18")),
                          c(paste0(ctydemographic, rep("20")), paste0(ctytimevarying, rep("19")), paste0(outcomecty, "19"), paste0(ctyvaccines, "19"))))


mybaseline <- list(
  trt = c("pct_repvotes_state2016"),
  cens = NULL,
  outcome = c(statedummies, "pct_repvotes2016", "pct_demvotes2016", "metro")
)

options(mc.cores=7)
getOption("mc.cores")
plan(multisession)

learner <- c("SL.mean", "SL.glmnet", "SL.xgboost", "SL.earth")

set.seed(29022024)
m_shift <- lmtp_tmle(
  df,
  trt = a,
  outcome = "cumodratemon21",
  time_vary = mytimevary,
  baseline = mybaseline,
  cens = NULL,
  shift = static_binary_on,
  id = "StateFIPS",
  outcome_type = "continuous",
  learners_outcome = learner,
  learners_trt = learner,
  folds = 1,
  k = 4
)

shift_output_path <- paste0("results/", 
                            "shift_", model_type, ".rds")

saveRDS(m_shift, shift_output_path)


m_ref <- lmtp_tmle(
  df,
  trt = a,
  outcome = "cumodratemon21",
  time_vary = mytimevary,
  baseline = mybaseline,
  cens = NULL,
  shift = static_binary_off,
  id = "StateFIPS",
  outcome_type = "continuous",
  learners_outcome = learner,
  learners_trt = learner,
  folds = 1,
  k = 4
)

ref_output_path <- paste0("results/",
                          "ref_", model_type, ".rds")

saveRDS(m_ref, ref_output_path)





