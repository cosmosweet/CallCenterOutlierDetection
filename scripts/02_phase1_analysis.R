# ==========================================================
# Script 02: Phase 1 Analysis
# Calculate summary statistics for Phase 1 data
# ==========================================================

# Load required libraries
library(dplyr)
library(knitr)
library(tibble)

# Load configuration and helper functions
source("config.R")
source("utils/helper_functions.R")

# Load preprocessed data
df <- readRDS(paste0(OUTPUT_PATH, "df_daily.rds"))
df_p1 <- readRDS(paste0(OUTPUT_PATH, "df_p1.rds"))

cat("==========================================================\n")
cat("02. PHASE 1 ANALYSIS\n")
cat("==========================================================\n\n")

k <- K_SIGMA  # 3σ control limits

# ==========================================================
# 1. Unanswered Rate Analysis
# ==========================================================
cat("📘 Analyzing Unanswered Rate (미응대율)\n\n")

# Calculate overall unanswered rate (p-bar)
pbar_unans <- with(df_p1, sum(d_unans, na.rm = TRUE) / sum(n_all, na.rm = TRUE))
cat("Overall unanswered rate (p-bar):", round(pbar_unans, 4), "\n\n")

# Create summary table for unanswered rate
table_unans_p1 <- df_p1 %>%
  transmute(
    Date,
    `Sample Size (nᵢ)` = n_all,
    `Number of Nonconforming (미응대 건수)` = d_unans,
    `Sample Fraction Nonconforming (미응대율)` = round(p_unans, 3),
    SD  = round(sqrt(pbar_unans * (1 - pbar_unans) / n_all), 3),
    LCL = round(pmax(0, pbar_unans - k * sqrt(pbar_unans * (1 - pbar_unans) / n_all)), 3),
    UCL = round(pmin(1, pbar_unans + k * sqrt(pbar_unans * (1 - pbar_unans) / n_all)), 3)
  ) %>%
  mutate(Date = as.character(Date))

# Add summary row
n_sum_unans <- sum(df_p1$n_all, na.rm = TRUE)
d_sum_unans <- sum(df_p1$d_unans, na.rm = TRUE)

table_unans_p1 <- bind_rows(
  table_unans_p1,
  tibble(
    Date = "Total / Mean",
    `Sample Size (nᵢ)` = n_sum_unans,
    `Number of Nonconforming (미응대 건수)` = d_sum_unans,
    `Sample Fraction Nonconforming (미응대율)` = round(d_sum_unans / n_sum_unans, 3),
    SD = NA_real_, LCL = NA_real_, UCL = NA_real_
  )
)

# Print table
cat("📊 Table P1-1. Unanswered Rate – Phase 1\n")
cat("   (", as.character(PHASE1_START), "~", as.character(PHASE1_END), ")\n\n")
print(kable(table_unans_p1, digits = 3, align = "ccccccc"))

# Save table
write.csv(table_unans_p1, 
          file = paste0(TABLE_PATH, "table_p1_unanswered_rate.csv"),
          row.names = FALSE)

# ==========================================================
# 2. Unresolved Rate Analysis
# ==========================================================
cat("\n\n📘 Analyzing Unresolved Rate (미해결률)\n\n")

# Calculate overall unresolved rate (p-bar)
pbar_unres <- with(df_p1, sum(d_unres, na.rm = TRUE) / sum(n_ans, na.rm = TRUE))
cat("Overall unresolved rate (p-bar):", round(pbar_unres, 4), "\n\n")

# Create summary table for unresolved rate
table_unres_p1 <- df_p1 %>%
  transmute(
    Date,
    `Sample Size (nᵢ)` = n_ans,
    `Number of Nonconforming (미해결 건수)` = d_unres,
    `Sample Fraction Nonconforming (미해결률)` = round(p_unres, 3),
    SD  = round(sqrt(pbar_unres * (1 - pbar_unres) / n_ans), 3),
    LCL = round(pmax(0, pbar_unres - k * sqrt(pbar_unres * (1 - pbar_unres) / n_ans)), 3),
    UCL = round(pmin(1, pbar_unres + k * sqrt(pbar_unres * (1 - pbar_unres) / n_ans)), 3)
  ) %>%
  mutate(Date = as.character(Date))

# Add summary row
n_sum_unres <- sum(df_p1$n_ans, na.rm = TRUE)
d_sum_unres <- sum(df_p1$d_unres, na.rm = TRUE)

table_unres_p1 <- bind_rows(
  table_unres_p1,
  tibble(
    Date = "Total / Mean",
    `Sample Size (nᵢ)` = n_sum_unres,
    `Number of Nonconforming (미해결 건수)` = d_sum_unres,
    `Sample Fraction Nonconforming (미해결률)` = round(d_sum_unres / n_sum_unres, 3),
    SD = NA_real_, LCL = NA_real_, UCL = NA_real_
  )
)

# Print table
cat("📊 Table P1-2. Unresolved Rate – Phase 1\n")
cat("   (", as.character(PHASE1_START), "~", as.character(PHASE1_END), ")\n\n")
print(kable(table_unres_p1, digits = 3, align = "ccccccc"))

# Save table
write.csv(table_unres_p1, 
          file = paste0(TABLE_PATH, "table_p1_unresolved_rate.csv"),
          row.names = FALSE)

# ==========================================================
# Save Phase 1 Parameters
# ==========================================================
phase1_params <- list(
  pbar_unans = pbar_unans,
  pbar_unres = pbar_unres,
  n_days = nrow(df_p1)
)

saveRDS(phase1_params, file = paste0(OUTPUT_PATH, "phase1_params.rds"))

cat("\n==========================================================\n")
cat("Phase 1 analysis completed!\n")
cat("Tables saved to:", TABLE_PATH, "\n")
cat("==========================================================\n\n")
