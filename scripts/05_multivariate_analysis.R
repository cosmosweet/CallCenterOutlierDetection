# ==========================================================
# Script 05: Multivariate Analysis (Hotelling T²)
# Multivariate control chart for simultaneous monitoring
# ==========================================================

# Load required libraries
library(dplyr)
library(ggplot2)
library(MSQC)

# Load configuration and helper functions
source("config.R")
source("utils/helper_functions.R")

# Set graphics parameters
set_graphics_params()

# Load preprocessed data
df <- readRDS(paste0(OUTPUT_PATH, "df_standardized.rds"))

cat("==========================================================\n")
cat("05. MULTIVARIATE ANALYSIS (Hotelling T²)\n")
cat("==========================================================\n\n")

# ==========================================================
# Prepare Data Matrices
# ==========================================================
cat("📊 Preparing data matrices\n\n")

# Phase 1: days 1-25
Z_p1 <- df %>%
  slice(1:25) %>%
  select(z_unans, z_unres) %>%
  as.matrix()

# Phase 2: days 26-90
Z_p2 <- df %>% 
  slice(26:90) %>%
  select(z_unans, z_unres) %>%
  as.matrix()

p <- ncol(Z_p1)  # Number of variables (=2)
m <- nrow(Z_p1)  # Phase 1 sample size (=25)

cat("Number of quality characteristics (p):", p, "\n")
cat("Phase 1 sample size (m):", m, "\n")
cat("Phase 2 sample size:", nrow(Z_p2), "\n\n")

# ==========================================================
# 1. Initial Hotelling T² (with all Phase 1 data)
# ==========================================================
cat("📊 Computing initial Hotelling T² chart\n\n")

# Phase 1 statistics
Z_bar <- colMeans(Z_p1)
S     <- cov(Z_p1)
S_inv <- solve(S)

# Calculate T² for Phase 1 and Phase 2
T2_1 <- compute_T2(Z_p1, Z_bar, S_inv)
T2_2 <- compute_T2(Z_p2, Z_bar, S_inv)

# Control limits
UCL1 <- qchisq(1 - ALPHA, df = p)  # Phase 1 UCL (chi-square)
UCL2 <- ((m + 1) * (m - 1) * p) / (m * (m - p)) * 
        qf(1 - ALPHA, df1 = p, df2 = m - p)  # Phase 2 UCL (F-distribution)

cat("Phase 1 UCL (χ²):", round(UCL1, 4), "\n")
cat("Phase 2 UCL (F):", round(UCL2, 4), "\n\n")

# Create combined data frame
df_T2 <- df %>%
  mutate(
    day   = row_number(),
    phase = if_else(day <= m, "Phase1", "Phase2"),
    T2    = c(T2_1, T2_2),
    UCL   = if_else(phase == "Phase1", UCL1, UCL2),
    out   = T2 > UCL
  )

# Plot combined chart
p_combined <- ggplot(df_T2, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  annotate("segment", x = 1, xend = m, y = UCL1, yend = UCL1,
           linetype = "dashed", color = "red") +
  annotate("segment", x = m + 1, xend = 90, y = UCL2, yend = UCL2,
           linetype = "dashed", color = "red") +
  scale_color_manual(values = c(`FALSE` = "black", `TRUE` = "red")) +
  labs(
    x = "Day",
    y = expression(T^2),
    color = "Out of Control",
    title = "Hotelling T-Squared Multivariate Control Chart (Original)"
  ) +
  theme_bw(base_family = FONT_FAMILY)

ggsave(paste0(FIGURE_PATH, "hotelling_t2_original.png"), 
       p_combined, width = 10, height = 6, dpi = 300)

cat("Plot saved: hotelling_t2_original.png\n\n")

# ==========================================================
# 2. Remove Phase 1 Outliers (Once)
# ==========================================================
cat("📊 Removing Phase 1 outliers (single iteration)\n\n")

result_once <- remove_outliers_once(Z_p1, p, ALPHA)

cat("Original Phase 1 days:", paste(result_once$original_idx, collapse = ", "), "\n")
cat("Outlier days:", paste(result_once$outlier_idx, collapse = ", "), "\n")
cat("Clean Phase 1 days:", paste(result_once$clean_idx, collapse = ", "), "\n")
cat("Final Phase 1 sample size:", result_once$m_final, "\n\n")

# Plot Phase 1 (original with outliers)
df_p1_orig <- data.frame(
  day = result_once$original_idx,
  T2  = result_once$original_T2
) %>%
  mutate(
    UCL = result_once$UCL,
    out = T2 > UCL
  )

p_p1_orig <- ggplot(df_p1_orig, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  geom_hline(yintercept = result_once$UCL, linetype = "dashed", color = "red") +
  scale_color_manual(values = c(`FALSE` = "black", `TRUE` = "red")) +
  labs(
    title = "Phase 1 Hotelling T-Squared Chart (Original)",
    x = "Day",
    y = expression(T^2),
    color = "Out of Control"
  ) +
  theme_bw(base_family = FONT_FAMILY)

ggsave(paste0(FIGURE_PATH, "hotelling_t2_phase1_original.png"), 
       p_p1_orig, width = 10, height = 6, dpi = 300)

# Plot Phase 1 (clean, after removing outliers)
df_p1_clean <- data.frame(
  day = result_once$clean_idx,
  T2  = result_once$T2
) %>%
  mutate(
    UCL = result_once$UCL,
    out = T2 > UCL
  )

p_p1_clean <- ggplot(df_p1_clean, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  geom_hline(yintercept = result_once$UCL, linetype = "dashed", color = "red") +
  scale_color_manual(values = c(`FALSE` = "black", `TRUE` = "red")) +
  labs(
    title = "Phase 1 Hotelling T-Squared Chart (After Outlier Removal)",
    x = "Day",
    y = expression(T^2),
    color = "Out of Control"
  ) +
  theme_bw(base_family = FONT_FAMILY)

ggsave(paste0(FIGURE_PATH, "hotelling_t2_phase1_clean.png"), 
       p_p1_clean, width = 10, height = 6, dpi = 300)

cat("Phase 1 plots saved.\n\n")

# ==========================================================
# 3. Phase 2 with Clean Phase 1 Baseline
# ==========================================================
cat("📊 Computing Phase 2 T² with clean Phase 1 baseline\n\n")

# Recalculate Phase 2 T² with clean Phase 1 parameters
T2_2_clean <- compute_T2(Z_p2, result_once$mean_vec, result_once$inv_cov)

# New UCL for Phase 2
m_clean <- result_once$m_final
UCL2_clean <- ((m_clean + 1) * (m_clean - 1) * p) /
              (m_clean * (m_clean - p)) *
              qf(1 - ALPHA, df1 = p, df2 = m_clean - p)

cat("Updated Phase 2 UCL:", round(UCL2_clean, 4), "\n\n")

# Phase 2 data frame
day_p2 <- (m + 1):(m + nrow(Z_p2))

df_p2 <- data.frame(
  day = day_p2,
  T2  = T2_2_clean
) %>%
  mutate(
    UCL = UCL2_clean,
    out = T2 > UCL
  )

# Plot Phase 2
p_p2 <- ggplot(df_p2, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  geom_hline(yintercept = UCL2_clean, linetype = "dashed", color = "red") +
  scale_color_manual(values = c(`FALSE` = "black", `TRUE` = "red")) +
  labs(
    title = "Phase 2 Hotelling T-Squared Chart",
    x = "Day",
    y = expression(T^2),
    color = "Out of Control"
  ) +
  theme_bw(base_family = FONT_FAMILY)

ggsave(paste0(FIGURE_PATH, "hotelling_t2_phase2_clean.png"), 
       p_p2, width = 10, height = 6, dpi = 300)

cat("Phase 2 plot saved: hotelling_t2_phase2_clean.png\n\n")

# ==========================================================
# 4. Extract Phase 2 Outlier Coordinates
# ==========================================================
cat("📊 Extracting Phase 2 outlier information\n\n")

out_idx_p2  <- which(df_p2$out)
out_days_p2 <- df_p2$day[out_idx_p2]

if (length(out_days_p2) > 0) {
  # Original data for Phase 2
  orig_p2 <- df[day_p2, ]
  orig_out_p2 <- orig_p2[out_idx_p2, , drop = FALSE]
  
  cat("Phase 2 outlier days:", paste(out_days_p2, collapse = ", "), "\n\n")
  cat("Outlier information (original values):\n")
  print(orig_out_p2)
  
  # Save outlier information
  write.csv(orig_out_p2, 
            file = paste0(TABLE_PATH, "hotelling_phase2_outliers.csv"),
            row.names = FALSE)
  
  cat("\nOutlier table saved: hotelling_phase2_outliers.csv\n\n")
} else {
  cat("No Phase 2 outliers detected.\n\n")
}

# ==========================================================
# 5. Alternative: Iterative Outlier Removal
# ==========================================================
cat("📊 Alternative: Iterative outlier removal from Phase 1\n\n")

result_iter <- remove_outliers_iterative(Z_p1, p, ALPHA, verbose = TRUE)

cat("\nFinal Phase 1 sample size (iterative):", result_iter$m_final, "\n")
cat("Clean days:", paste(result_iter$clean_idx, collapse = ", "), "\n\n")

# Plot iteratively cleaned Phase 1
df_p1_iter <- data.frame(
  day = result_iter$clean_idx,
  T2  = result_iter$T2
) %>%
  mutate(
    UCL = result_iter$UCL,
    out = T2 > UCL
  )

p_p1_iter <- ggplot(df_p1_iter, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  geom_hline(yintercept = result_iter$UCL, linetype = "dashed", color = "red") +
  scale_color_manual(values = c(`FALSE` = "black", `TRUE` = "red")) +
  labs(
    title = "Phase 1 Hotelling T-Squared Chart (After Iterative Removal)",
    x = "Day",
    y = expression(T^2),
    color = "Out of Control"
  ) +
  theme_bw(base_family = FONT_FAMILY)

ggsave(paste0(FIGURE_PATH, "hotelling_t2_phase1_iterative.png"), 
       p_p1_iter, width = 10, height = 6, dpi = 300)

cat("Iterative Phase 1 plot saved.\n\n")

# ==========================================================
# Save Results
# ==========================================================
hotelling_results <- list(
  original = list(
    Z_bar = Z_bar,
    S = S,
    S_inv = S_inv,
    T2_p1 = T2_1,
    T2_p2 = T2_2,
    UCL1 = UCL1,
    UCL2 = UCL2
  ),
  clean_once = result_once,
  clean_iter = result_iter,
  phase2_outliers = if (exists("orig_out_p2")) orig_out_p2 else NULL
)

saveRDS(hotelling_results, file = paste0(OUTPUT_PATH, "hotelling_results.rds"))

cat("==========================================================\n")
cat("Multivariate analysis completed!\n")
cat("Plots saved to:", FIGURE_PATH, "\n")
cat("Results saved to:", OUTPUT_PATH, "\n")
cat("==========================================================\n\n")
