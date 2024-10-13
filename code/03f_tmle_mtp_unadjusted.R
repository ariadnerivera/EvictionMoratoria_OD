library(haven)
library(future)
library(lmtp)
library(progressr)
library(tidyverse)
library(SuperLearner)
library(foreach)
library(doParallel)
library(fastDummies)

# This code runs analysis for mtp, unadjusted
model_type <- "mtp_unadjusted"

# Setwd
setwd("~/EvictionMoratoria_OD")

#load dataset
data <-
  read_dta("data/3_analytic/analysis_county_march2020_dec2021.dta")

# Subset variables needed
myvars <- c("geofips", "StateFIPS", "Year", "YearMonth", "MonthNum", 
            "LiftMoratoriaObin", "cumodratemon") 

# Subset the data
data_subset <- data %>%
  select(all_of(myvars)) %>%
  arrange(geofips, YearMonth)


# Remove geographic ids and time from myvars list to create list of vars to reshape from long to wide format
idtime <- c("geofips", "StateFIPS", "Year", "YearMonth", "MonthNum") 

# Remove items by value
selected_vars <- myvars[!myvars %in% idtime]

df <- data_subset %>%
  pivot_wider(
    id_cols = c(geofips, StateFIPS),
    names_from = MonthNum,
    names_sep = "",
    values_from = all_of(selected_vars)
  )

a <- names(df[, paste0("LiftMoratoriaObin", 2:20)])

df$intercept <- 1

intercept <- "intercept"

# Define treatment and outcome variable lists
mytimevary <- list(trt = c(lapply(1:19, function(x) intercept)),
                   cens = c(lapply(1:19, function(x) NULL)),
                   outcome = c(lapply(1:19, function(x) intercept)))

# Repeat subset and transpose in the mtp dataset
datamtp <- read_dta("data/3_analytic/analysis_county_march2020_dec2021_mtp.dta")

# Subset the data
mtpdata_subset <- datamtp %>%
  select(all_of(myvars)) %>%
  arrange(geofips, YearMonth)

mtpdf <- mtpdata_subset %>%
  pivot_wider(
    id_cols = c(geofips, StateFIPS),
    names_from = MonthNum,
    names_sep = "",
    values_from = all_of(selected_vars)
  )

mtpdf$intercept <- 1

options(mc.cores=7)
getOption("mc.cores")
plan(multisession)
set.seed(29022024)

learner <- c("SL.glmnet", "SL.mean", "SL.xgboost", "SL.earth")

### TMLE models
# All treated
m_shift <- paste0("psi.tmle.", model_type, ".shift")

set.seed(29022024)
with_progress(
  m_shift <- lmtp_tmle(
    df,
    trt = a,
    outcome = "cumodratemon21",
    time_vary = mytimevary,
    cens = NULL,
    shift = NULL,
    shifted = mtpdf,
    id = "StateFIPS",
    outcome_type = "continuous",
    learners_outcome = learner,
    learners_trt = learner,
    folds = 1,
    k = 4,
    mtp = TRUE
  )
)

shift_output_path <- paste0("results/", 
                            "shift_", model_type, ".rds")

saveRDS(m_shift, shift_output_path)


# All untreated
m_ref <- paste0("psi.tmle.", model_type,".ref")

with_progress(
  m_ref <- lmtp_tmle(
    df,
    trt = a,
    outcome = "cumodratemon21",
    time_vary = mytimevary,
    cens = NULL,
    shift = NULL,
    #shifted = mtpdf,
    id = "StateFIPS",
    outcome_type = "continuous",
    learners_outcome = learner,
    learners_trt = learner,
    folds = 1,
    k = 4,
    mtp = TRUE
  )
)

ref_output_path <- paste0("results/",
                          "ref_", model_type, ".rds")

saveRDS(m_ref, ref_output_path)

