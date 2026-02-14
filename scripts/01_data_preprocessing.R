# ==========================================================
# Script 01: Data Preprocessing
# Load and aggregate call center data by day
# ==========================================================

# Load required libraries
library(readxl)
library(dplyr)
library(lubridate)

# Load configuration
source("config.R")
source("utils/helper_functions.R")

# Create output directories
create_output_dirs()

cat("==========================================================\n")
cat("01. DATA PREPROCESSING\n")
cat("==========================================================\n\n")

# ----- Load Raw Data -----
cat("Loading data from:", DATA_PATH, "\n")
df_raw <- read_excel(DATA_PATH)

cat("Raw data dimensions:", dim(df_raw), "\n")
cat("First few rows:\n")
print(head(df_raw))

# ----- Rename Columns -----
colnames(df_raw) <- c(
  "CallID", "Agent", "Date", "Time", "Topic",
  "Answered", "Resolved", "SpeedAnswer", "TalkDur", "Satisfaction"
)

cat("\nColumn names updated.\n")

# ----- Aggregate Data by Day -----
cat("\nAggregating data by day...\n")

df <- df_raw %>%
  mutate(Date = as.Date(Date)) %>%
  group_by(Date) %>%
  summarise(
    n_all   = n(),                                        # Total calls per day
    d_unans = sum(Answered == "N", na.rm = TRUE),         # Unanswered calls
    n_ans   = sum(Answered == "Y", na.rm = TRUE),         # Answered calls
    d_unres = sum(Answered == "Y" & Resolved == "N", na.rm = TRUE), # Unresolved calls
    .groups = 'drop'
  ) %>%
  mutate(
    p_unans = d_unans / n_all,                            # Unanswered rate
    p_unres = ifelse(n_ans > 0, d_unres / n_ans, NA)      # Unresolved rate
  ) %>%
  arrange(Date)

cat("Daily aggregation completed.\n")
cat("Aggregated data dimensions:", dim(df), "\n\n")

cat("Summary of aggregated data:\n")
print(head(df, 10))

# ----- Split into Phase 1 and Phase 2 -----
cat("\n----- Splitting data into phases -----\n")

df_p1 <- df %>%
  filter(Date >= PHASE1_START, Date <= PHASE1_END) %>%
  arrange(Date)

df_p2 <- df %>%
  filter(Date >= PHASE2_START, Date <= PHASE2_END) %>%
  arrange(Date)

cat("Phase 1:", PHASE1_START, "to", PHASE1_END, "\n")
cat("  - Number of days:", nrow(df_p1), "\n")
cat("Phase 2:", PHASE2_START, "to", PHASE2_END, "\n")
cat("  - Number of days:", nrow(df_p2), "\n\n")

# ----- Save Processed Data -----
saveRDS(df, file = paste0(OUTPUT_PATH, "df_daily.rds"))
saveRDS(df_p1, file = paste0(OUTPUT_PATH, "df_p1.rds"))
saveRDS(df_p2, file = paste0(OUTPUT_PATH, "df_p2.rds"))

cat("Processed data saved to:", OUTPUT_PATH, "\n")
cat("\n==========================================================\n")
cat("Data preprocessing completed!\n")
cat("==========================================================\n\n")
