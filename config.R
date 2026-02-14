# ==========================================================
# Configuration File
# Outlier Detection using SPC in Call Center Dataset
# ==========================================================

# ----- Paths -----
DATA_PATH <- 'data/Telecom Company Call-Center-Dataset.xlsx'
OUTPUT_PATH <- 'outputs/'
FIGURE_PATH <- 'outputs/figures/'
TABLE_PATH <- 'outputs/tables/'

# ----- Date Ranges -----
PHASE1_START <- as.Date("2021-01-01")
PHASE1_END   <- as.Date("2021-01-25")
PHASE2_START <- as.Date("2021-01-26")
PHASE2_END   <- as.Date("2021-03-31")

# ----- Control Chart Parameters -----
K_SIGMA <- 3  # Control limit multiplier (3σ)
ALPHA <- 0.05 # Significance level

# ----- CUSUM Parameters -----
CUSUM_K <- 0.25  # Reference value (k)
CUSUM_H <- 5     # Decision interval (h)
CUSUM_SE_SHIFT <- 0.5  # Standard error shift

# ----- EWMA Parameters -----
LAMBDA_VALUES <- c(0.8, 0.5, 0.2)  # Different lambda values to test
LAMBDA_DEFAULT <- 0.8  # Default lambda for main analysis

# ----- Multivariate Parameters -----
MULTIVARIATE_P <- 2  # Number of quality characteristics (z_unans, z_unres)

# ----- Graphics Settings -----
# Mac users: use "AppleGothic" for Korean support
# Windows users: use "Malgun Gothic" or "NanumGothic"
FONT_FAMILY <- "AppleGothic"

# Set global graphics parameters
set_graphics_params <- function() {
  par(family = FONT_FAMILY)
  qcc::qcc.options(
    title.font = 2,
    cex.title  = 1.1,
    digits     = 3
  )
}

# ----- Directory Setup -----
create_output_dirs <- function() {
  if (!dir.exists(OUTPUT_PATH)) dir.create(OUTPUT_PATH, recursive = TRUE)
  if (!dir.exists(FIGURE_PATH)) dir.create(FIGURE_PATH, recursive = TRUE)
  if (!dir.exists(TABLE_PATH)) dir.create(TABLE_PATH, recursive = TRUE)
}
