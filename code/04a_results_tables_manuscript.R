library(tidyverse)
library(lmtp)
library(haven)

setwd("~/EvictionMoratoria_OD/")

# Helper function to generate file paths based on model name and date suffix
generate_file_paths <- function(model_type) {
  base_path <- paste0("results/")
  list(
    tmle_shift = paste0(base_path, "shift_", model_type,".rds"),
    tmle_ref = paste0(base_path, "ref_", model_type,".rds")
  )
}

# Function to load results and contrast two counterfactuals
load_results <- function(shift_path, ref_path, model_name, estimator_name = "tmle") {
  shift <- readRDS(shift_path)
  ref <- readRDS(ref_path)
  results <- lmtp_contrast(shift, ref = ref)
  
  # Create results dataframe with additional columns for model and estimator
  results.df <- results$vals %>%
    mutate(
      model = model_name,
      estimator = estimator_name
    )
  
  return(results.df)
}

# Function to round and format columns
format_results <- function(results) {
  results %>%
    select(model, theta, std.error, conf.low, conf.high) %>%
    mutate(
      `Causal Contrast` = model,
      Difference = round(theta, 4),
      SE = round(std.error, 3),
      conf.low = round(conf.low, 3),
      conf.high = round(conf.high, 3),
      `95% CI` = paste0("(", conf.low, ", ", conf.high, ")")
    ) %>%
    select(`Causal Contrast`, Difference, SE, `95% CI`)
}


# Table 1: Estimated effects on the average monthly drug overdose death rate 
# per 100,000 people between May 2020 to December 2021, models include state FE

t1.results <- c("main_fe",
                "main_unadjusted")

t1.names <- c(
  "All Treated vs. All Untreated (Adjusted)",
  "All Treated vs. All Untreated (Unadjusted)"
)

# Create model information
t1.info <- lapply(seq_along(t1.results), function(i) {
  paths <- generate_file_paths(t1.results[i])
  list(
    tmle_shift = paths$tmle_shift,
    tmle_ref = paths$tmle_ref,
    name = t1.names[i]
  )
})

# Load and combine results
t1.results.list <- lapply(t1.info, function(model) {
  load_results(model$tmle_shift, model$tmle_ref, model$name)
})

# Combine all results into a single data frame
combined_t1.results <- do.call(rbind, t1.results.list)

# Format and display the table
t1.table <- format_results(combined_t1.results)
print(t1.table)

# Table 2: Estimated effects on the average monthly drug overdose death rate 
# per 100,000 people between May 2020 to December 2021 under alternative scenarios
# models include state FE

t2.results <- c("caresact_outcome_fe",
                "anymoratoria_fe",
                "tert1_fe",
                "tert2_fe",
                "tert3_fe")

t2.names <- c(
  "All Treated vs. All Untreated (Adjusted + Cares Act)",
  "All Treated vs. All Untreated (Adjusted + Any Moratoria)",
  "All Treated vs. All Untreated (Adjusted, Tertile 1)",
  "All Treated vs. All Untreated (Adjusted, Tertile 2)",
  "All Treated vs. All Untreated (Adjusted, Tertile 3)"
)

# Create model information
t2.info <- lapply(seq_along(t2.results), function(i) {
  paths <- generate_file_paths(t2.results[i])
  list(
    tmle_shift = paths$tmle_shift,
    tmle_ref = paths$tmle_ref,
    name = t2.names[i]
  )
})

# Load and combine results
t2.results.list <- lapply(t2.info, function(model) {
  load_results(model$tmle_shift, model$tmle_ref, model$name)
})

# Combine all results into a single data frame
combined_t2.results <- do.call(rbind, t2.results.list)

# Format and display the table
t2.table <- format_results(combined_t2.results)
print(t2.table)



#################################
ts5.results <- c("main",
                 "caresact_outcome",
                 "anymoratoria",
                 "tert1",
                 "tert2",
                 "tert3")

ts5.names <- c(
  "All Treated vs. All Untreated (Adjusted)",
  "All Treated vs. All Untreated (Adjusted + Cares Act)",
  "All Treated vs. All Untreated (Adjusted + Any Moratoria)",
  "All Treated vs. All Untreated (Adjusted, Tertile 1)",
  "All Treated vs. All Untreated (Adjusted, Tertile 2)",
  "All Treated vs. All Untreated (Adjusted, Tertile 3)")


# Create model information
ts5.info <- lapply(seq_along(ts5.results), function(i) {
  paths <- generate_file_paths(ts5.results[i])
  list(
    tmle_shift = paths$tmle_shift,
    tmle_ref = paths$tmle_ref,
    name = ts5.names[i]
  )
})

# Load and combine results
ts5.results.list <- lapply(ts5.info, function(model) {
  load_results(model$tmle_shift, model$tmle_ref, model$name)
})

# Combine all results into a single data frame
combined_ts5.results <- do.call(rbind, ts5.results.list)

# Format and display the table
ts5.table <- format_results(combined_ts5.results)
print(ts5.table)



# Save files
out.path <- "results/"

write_excel_csv(t1.table, file = paste0(out.path, "t1_table", ".csv"))
write_excel_csv(t2.table, file = paste0(out.path, "t2_table", ".csv"))
write_excel_csv(ts5.table, file = paste0(out.path, "ts5_table", ".csv"))
