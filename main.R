# ==========================================================
# Main Script
# Outlier Detection using SPC in Call Center Dataset
# ==========================================================
# This script runs the complete analysis pipeline
# ==========================================================

cat("\n")
cat("##########################################################\n")
cat("##                                                      ##\n")
cat("##  Outlier Detection using SPC in Call Center Dataset ##\n")
cat("##                                                      ##\n")
cat("##########################################################\n")
cat("\n")

# ==========================================================
# Set Working Directory to Script Location
# ==========================================================
# Get the directory where this script is located
script_dir <- tryCatch({
  # For RStudio
  dirname(rstudioapi::getSourceEditorContext()$path)
}, error = function(e) {
  # For command line R
  if (exists("script.path")) {
    dirname(script.path)
  } else {
    # Fall back to current directory
    getwd()
  }
})

# If we couldn't detect the script directory, use current working directory
if (is.null(script_dir) || script_dir == "") {
  script_dir <- getwd()
}

# Set working directory to script location
setwd(script_dir)
cat("Working directory set to:", getwd(), "\n\n")

# Record start time
start_time <- Sys.time()

# ==========================================================
# Check Required Packages
# ==========================================================
cat("Checking required packages...\n")

required_packages <- c(
  "readxl", "dplyr", "lubridate", "qcc", "zoo", 
  "ggplot2", "knitr", "tibble", "spc", "MSQC"
)

missing_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]

if (length(missing_packages) > 0) {
  cat("\nThe following packages are missing:\n")
  cat(paste(missing_packages, collapse = ", "), "\n\n")
  cat("Install them using:\n")
  cat("install.packages(c(", paste0("'", missing_packages, "'", collapse = ", "), "))\n\n")
  stop("Please install missing packages before running the analysis.")
} else {
  cat("All required packages are installed.\n\n")
}

# ==========================================================
# Run Analysis Scripts
# ==========================================================

cat("==========================================================\n")
cat("RUNNING ANALYSIS PIPELINE\n")
cat("==========================================================\n\n")

# Script 1: Data Preprocessing
cat(">>> Running Script 01: Data Preprocessing\n")
source("scripts/01_data_preprocessing.R")

# Script 2: Phase 1 Analysis
cat("\n>>> Running Script 02: Phase 1 Analysis\n")
source("scripts/02_phase1_analysis.R")

# Script 3: Control Charts
cat("\n>>> Running Script 03: Control Charts (p-charts)\n")
source("scripts/03_control_charts.R")

# Script 4: CUSUM and EWMA
cat("\n>>> Running Script 04: CUSUM and EWMA\n")
source("scripts/04_cusum_ewma.R")

# Script 5: Multivariate Analysis
cat("\n>>> Running Script 05: Multivariate Analysis (Hotelling T²)\n")
source("scripts/05_multivariate_analysis.R")

# ==========================================================
# Summary
# ==========================================================
end_time <- Sys.time()
elapsed_time <- end_time - start_time

cat("\n")
cat("==========================================================\n")
cat("ANALYSIS COMPLETE!\n")
cat("==========================================================\n\n")

cat("Total execution time:", round(elapsed_time, 2), attr(elapsed_time, "units"), "\n\n")

cat("📁 Output locations:\n")
cat("  - Processed data:", OUTPUT_PATH, "\n")
cat("  - Figures:", FIGURE_PATH, "\n")
cat("  - Tables:", TABLE_PATH, "\n\n")

cat("📊 Generated outputs:\n")
cat("  - p-charts (unanswered & unresolved rates)\n")
cat("  - CUSUM charts\n")
cat("  - EWMA charts (multiple λ values)\n")
cat("  - Hotelling T² multivariate charts\n")
cat("  - Summary tables (CSV format)\n\n")

cat("==========================================================\n")
cat("Thank you for using this SPC analysis pipeline!\n")
cat("==========================================================\n\n")
