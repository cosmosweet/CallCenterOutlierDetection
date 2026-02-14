# ==========================================================
# Script 04: CUSUM and EWMA Control Charts
# Advanced control charts for detecting small shifts
# ==========================================================

# Load required libraries
library(dplyr)
library(qcc)
library(spc)

# Load configuration and helper functions
source("config.R")
source("utils/helper_functions.R")

# Set graphics parameters
set_graphics_params()

# Load preprocessed data
df <- readRDS(paste0(OUTPUT_PATH, "df_daily.rds"))
df_p1 <- readRDS(paste0(OUTPUT_PATH, "df_p1.rds"))
phase1_params <- readRDS(paste0(OUTPUT_PATH, "phase1_params.rds"))

cat("==========================================================\n")
cat("04. CUSUM AND EWMA CONTROL CHARTS\n")
cat("==========================================================\n\n")

# ==========================================================
# Standardization
# ==========================================================
cat("📊 Standardizing data based on Phase 1 parameters\n\n")

pbar_unans_p1 <- phase1_params$pbar_unans
pbar_unres_p1 <- phase1_params$pbar_unres

df <- df %>%
  mutate(
    z_unans = (p_unans - pbar_unans_p1) / 
              sqrt(pbar_unans_p1 * (1 - pbar_unans_p1) / n_all),
    z_unres = (p_unres - pbar_unres_p1) / 
              sqrt(pbar_unres_p1 * (1 - pbar_unres_p1) / n_ans)
  )

cat("Standardization completed.\n\n")

# ==========================================================
# Calculate EWMA Critical Values
# ==========================================================
cat("📊 Calculating EWMA critical values\n\n")

nsigmas_08 <- calc_ewma_crit(lambda = 0.8, L0 = 370, mu0 = 0)
nsigmas_05 <- calc_ewma_crit(lambda = 0.5, L0 = 370, mu0 = 0)
nsigmas_02 <- calc_ewma_crit(lambda = 0.2, L0 = 370, mu0 = 0)

cat("EWMA critical values (for ARL = 370):\n")
cat("  λ = 0.8: nsigmas =", round(nsigmas_08, 4), "\n")
cat("  λ = 0.5: nsigmas =", round(nsigmas_05, 4), "\n")
cat("  λ = 0.2: nsigmas =", round(nsigmas_02, 4), "\n\n")

# ==========================================================
# 1. CUSUM - Unanswered Rate
# ==========================================================
cat("📊 Creating CUSUM chart for Unanswered Rate\n\n")

cusum_unans <- cusum(
  data              = df$z_unans[1:25],
  newdata           = df$z_unans[26:90],
  decision.interval = CUSUM_H,
  se.shift          = CUSUM_SE_SHIFT,
  plot              = FALSE,
  center            = 0,
  std.dev           = 1
)

# Save plot
png(paste0(FIGURE_PATH, "cusum_unanswered.png"), 
    width = 10, height = 6, units = "in", res = 300)
plot(cusum_unans, title = "")
title(paste0("CUSUM Chart (Unanswered Rate): k = ", CUSUM_K, ", h = ", CUSUM_H))
dev.off()

cat("Plot saved: cusum_unanswered.png\n\n")

# ==========================================================
# 2. EWMA - Unanswered Rate
# ==========================================================
cat("📊 Creating EWMA chart for Unanswered Rate (λ = 0.8)\n\n")

ewma_unans <- ewma(
  data      = df$z_unans[1:25],
  newdata   = df$z_unans[26:90],
  center    = 0,
  std.dev   = 1,
  lambda    = LAMBDA_DEFAULT,
  nsigmas   = nsigmas_08,
  labels    = format(df_p1$Date, "%m/%d"),
  newlabels = format(df$Date[26:90], "%m/%d"),
  plot      = FALSE
)

# Save plot
png(paste0(FIGURE_PATH, "ewma_unanswered_lambda08.png"), 
    width = 10, height = 6, units = "in", res = 300)
plot(ewma_unans, title = "", add.stats = FALSE, restore.par = FALSE)
title(paste0("EWMA Chart (Unanswered Rate): lambda = ", LAMBDA_DEFAULT))
dev.off()

cat("Plot saved: ewma_unanswered_lambda08.png\n\n")

# ==========================================================
# 3. CUSUM - Unresolved Rate
# ==========================================================
cat("📊 Creating CUSUM chart for Unresolved Rate\n\n")

cusum_unres <- cusum(
  data              = df$z_unres[1:25],
  newdata           = df$z_unres[26:90],
  decision.interval = CUSUM_H,
  se.shift          = CUSUM_SE_SHIFT,
  plot              = FALSE,
  center            = 0,
  std.dev           = 1
)

# Save plot
png(paste0(FIGURE_PATH, "cusum_unresolved.png"), 
    width = 10, height = 6, units = "in", res = 300)
plot(cusum_unres, title = "")
title(paste0("CUSUM Chart (Unresolved Rate): k = ", CUSUM_K, ", h = ", CUSUM_H))
dev.off()

cat("Plot saved: cusum_unresolved.png\n\n")

# ==========================================================
# 4. EWMA - Unresolved Rate (Multiple λ values)
# ==========================================================
cat("📊 Creating EWMA charts for Unresolved Rate\n\n")

# λ = 0.8
ewma_unres_08 <- ewma(
  data      = df$z_unres[1:25],
  newdata   = df$z_unres[26:90],
  center    = 0,
  std.dev   = 1,
  lambda    = 0.8,
  nsigmas   = nsigmas_08,
  labels    = format(df_p1$Date, "%m/%d"),
  newlabels = format(df$Date[26:90], "%m/%d"),
  plot      = FALSE
)

png(paste0(FIGURE_PATH, "ewma_unresolved_lambda08.png"), 
    width = 10, height = 6, units = "in", res = 300)
plot(ewma_unres_08, title = "", add.stats = FALSE, restore.par = FALSE)
title("EWMA Chart (Unresolved Rate): lambda = 0.8")
dev.off()

# λ = 0.5
ewma_unres_05 <- ewma(
  data      = df$z_unres[1:25],
  newdata   = df$z_unres[26:90],
  center    = 0,
  std.dev   = 1,
  lambda    = 0.5,
  nsigmas   = nsigmas_05,
  labels    = format(df_p1$Date, "%m/%d"),
  newlabels = format(df$Date[26:90], "%m/%d"),
  plot      = FALSE
)

png(paste0(FIGURE_PATH, "ewma_unresolved_lambda05.png"), 
    width = 10, height = 6, units = "in", res = 300)
plot(ewma_unres_05, title = "", add.stats = FALSE, restore.par = FALSE)
title("EWMA Chart (Unresolved Rate): lambda = 0.5")
dev.off()

# λ = 0.2
ewma_unres_02 <- ewma(
  data      = df$z_unres[1:25],
  newdata   = df$z_unres[26:90],
  center    = 0,
  std.dev   = 1,
  lambda    = 0.2,
  nsigmas   = nsigmas_02,
  labels    = format(df_p1$Date, "%m/%d"),
  newlabels = format(df$Date[26:90], "%m/%d"),
  plot      = FALSE
)

png(paste0(FIGURE_PATH, "ewma_unresolved_lambda02.png"), 
    width = 10, height = 6, units = "in", res = 300)
plot(ewma_unres_02, title = "", add.stats = FALSE, restore.par = FALSE)
title("EWMA Chart (Unresolved Rate): lambda = 0.2")
dev.off()

cat("EWMA plots saved for lambda = 0.8, 0.5, 0.2\n\n")

# ==========================================================
# 5. CUSUM Run Length Analysis (Unresolved Rate)
# ==========================================================
cat("📊 Analyzing CUSUM run lengths for Unresolved Rate\n\n")

# Calculate CUSUM statistics manually
z <- df$z_unres
k <- CUSUM_K
h <- CUSUM_H

n <- length(z)
Cp <- numeric(n)  # Positive CUSUM
Cm <- numeric(n)  # Negative CUSUM

for (i in 1:n) {
  if (i == 1) {
    Cp[i] <- max(0, z[i] - k)
    Cm[i] <- min(0, z[i] + k)
  } else {
    Cp[i] <- max(0, Cp[i-1] + z[i] - k)
    Cm[i] <- min(0, Cm[i-1] + z[i] + k)
  }
}

cusum_df <- df %>% 
  mutate(
    Cp = Cp,
    Cm = Cm,
    day = row_number()
  )

# Detect signals
signal_pos_idx <- which(cusum_df$Cp >= h)
signal_neg_idx <- which(cusum_df$Cm <= -h)

cat("Positive signals (C+ ≥ h) at days:", paste(signal_pos_idx, collapse = ", "), "\n")
cat("Negative signals (C- ≤ -h) at days:", paste(signal_neg_idx, collapse = ", "), "\n\n")

# Calculate run lengths
run_pos <- compute_run_info(cusum_df$Cp, signal_pos_idx, direction = "pos")
run_neg <- compute_run_info(cusum_df$Cm, signal_neg_idx, direction = "neg")

# Combine run info (handle NULL cases)
run_info <- bind_rows(run_pos, run_neg)
if (!is.null(run_info) && nrow(run_info) > 0) {
  run_info <- run_info %>% arrange(signal_at)
}

if (!is.null(run_info) && nrow(run_info) > 0) {
  cat("CUSUM Run Length Information:\n")
  print(run_info)
  write.csv(run_info, 
            file = paste0(TABLE_PATH, "cusum_run_length_unresolved.csv"),
            row.names = FALSE)
  cat("\nRun length table saved.\n\n")
} else {
  cat("No out-of-control signals detected.\n\n")
}

# ==========================================================
# Save Results
# ==========================================================

# Save standardized data FIRST (needed by script 05)
saveRDS(df, file = paste0(OUTPUT_PATH, "df_standardized.rds"))

cusum_ewma_results <- list(
  cusum_unans = cusum_unans,
  cusum_unres = cusum_unres,
  ewma_unans_08 = ewma_unans,
  ewma_unres_08 = ewma_unres_08,
  ewma_unres_05 = ewma_unres_05,
  ewma_unres_02 = ewma_unres_02,
  run_info = run_info,
  nsigmas = list(lambda_08 = nsigmas_08, 
                 lambda_05 = nsigmas_05, 
                 lambda_02 = nsigmas_02)
)

saveRDS(cusum_ewma_results, file = paste0(OUTPUT_PATH, "cusum_ewma_results.rds"))

cat("==========================================================\n")
cat("CUSUM and EWMA analysis completed!\n")
cat("Plots saved to:", FIGURE_PATH, "\n")
cat("==========================================================\n\n")
