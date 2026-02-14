# ==========================================================
# Script 03: Control Charts (p-charts)
# Variable sample size p-charts for unanswered and unresolved rates
# ==========================================================

# Load required libraries
library(dplyr)
library(qcc)

# Load configuration and helper functions
source("config.R")
source("utils/helper_functions.R")

# Set graphics parameters
set_graphics_params()

# Load preprocessed data
df <- readRDS(paste0(OUTPUT_PATH, "df_daily.rds"))
df_p1 <- readRDS(paste0(OUTPUT_PATH, "df_p1.rds"))
df_p2 <- readRDS(paste0(OUTPUT_PATH, "df_p2.rds"))

cat("==========================================================\n")
cat("03. CONTROL CHARTS (p-charts)\n")
cat("==========================================================\n\n")

# ==========================================================
# 1. Unanswered Rate p-chart
# ==========================================================
cat("📊 Creating p-chart for Unanswered Rate\n\n")

# Remove observations with zero sample size
p1_unans <- df_p1 %>% filter(n_all > 0)
p2_unans <- df_p2 %>% filter(n_all > 0)

cat("Phase 1 observations:", nrow(p1_unans), "\n")
cat("Phase 2 observations:", nrow(p2_unans), "\n\n")

## (A) Phase 1 Only
cat("--- Phase 1 p-chart (Unanswered Rate) ---\n")
qcc_unans_p1 <- qcc(
  data   = p1_unans$d_unans,
  sizes  = p1_unans$n_all,
  type   = "p",
  plot   = FALSE
)

# Save Phase 1 plot
png(paste0(FIGURE_PATH, "p_chart_unanswered_phase1.png"), 
    width = 10, height = 6, units = "in", res = 300)
plot(qcc_unans_p1,
     title  = "Phase 1 p-Chart (Unanswered Rate, Variable Sample Size)",
     xlab   = "Date", 
     ylab   = "Proportion Nonconforming (Unanswered Rate)",
     labels = format(p1_unans$Date, "%m/%d"))
dev.off()

cat("p-bar (Phase 1):", round(qcc_unans_p1$center, 4), "\n")
cat("Plot saved: p_chart_unanswered_phase1.png\n\n")

## (B) Phase 1 + Phase 2 Combined
cat("--- Combined p-chart (Phase 1 baseline + Phase 2 monitoring) ---\n")
qcc_unans_all <- qcc(
  data      = p1_unans$d_unans,
  sizes     = p1_unans$n_all,
  type      = "p",
  labels    = format(p1_unans$Date, "%m/%d"),
  newdata   = p2_unans$d_unans,
  newsizes  = p2_unans$n_all,
  newlabels = format(p2_unans$Date, "%m/%d"),
  plot      = FALSE
)

# Save combined plot
png(paste0(FIGURE_PATH, "p_chart_unanswered_combined.png"), 
    width = 12, height = 6, units = "in", res = 300)
plot(qcc_unans_all,
     title = "p-Chart (Unanswered Rate): Phase 1 Baseline with Phase 2 Monitoring",
     xlab  = "Date", 
     ylab  = "Proportion Nonconforming (Unanswered Rate)")
dev.off()

cat("Plot saved: p_chart_unanswered_combined.png\n\n")

# ==========================================================
# 2. Unresolved Rate p-chart
# ==========================================================
cat("📊 Creating p-chart for Unresolved Rate\n\n")

# Remove observations with zero sample size
p1_unres <- df_p1 %>% filter(n_ans > 0)
p2_unres <- df_p2 %>% filter(n_ans > 0)

cat("Phase 1 observations:", nrow(p1_unres), "\n")
cat("Phase 2 observations:", nrow(p2_unres), "\n\n")

## (A) Phase 1 Only
cat("--- Phase 1 p-chart (Unresolved Rate) ---\n")
qcc_unres_p1 <- qcc(
  data   = p1_unres$d_unres,
  sizes  = p1_unres$n_ans,
  type   = "p",
  plot   = FALSE
)

# Save Phase 1 plot
png(paste0(FIGURE_PATH, "p_chart_unresolved_phase1.png"), 
    width = 10, height = 6, units = "in", res = 300)
plot(qcc_unres_p1,
     title  = "Phase 1 p-Chart (Unresolved Rate, Variable Sample Size)",
     xlab   = "Date", 
     ylab   = "Proportion Nonconforming (Unresolved Rate)",
     labels = format(p1_unres$Date, "%m/%d"))
dev.off()

cat("p-bar (Phase 1):", round(qcc_unres_p1$center, 4), "\n")
cat("Plot saved: p_chart_unresolved_phase1.png\n\n")

## (B) Phase 1 + Phase 2 Combined
cat("--- Combined p-chart (Phase 1 baseline + Phase 2 monitoring) ---\n")
qcc_unres_all <- qcc(
  data      = p1_unres$d_unres,
  sizes     = p1_unres$n_ans,
  type      = "p",
  labels    = format(p1_unres$Date, "%m/%d"),
  newdata   = p2_unres$d_unres,
  newsizes  = p2_unres$n_ans,
  newlabels = format(p2_unres$Date, "%m/%d"),
  plot      = FALSE
)

# Save combined plot
png(paste0(FIGURE_PATH, "p_chart_unresolved_combined.png"), 
    width = 12, height = 6, units = "in", res = 300)
plot(qcc_unres_all,
     title = "p-Chart (Unresolved Rate): Phase 1 Baseline with Phase 2 Monitoring",
     xlab  = "Date", 
     ylab  = "Proportion Nonconforming (Unresolved Rate)")
dev.off()

cat("Plot saved: p_chart_unresolved_combined.png\n\n")

# ==========================================================
# Save QCC Objects
# ==========================================================
qcc_results <- list(
  unans_p1 = qcc_unans_p1,
  unans_all = qcc_unans_all,
  unres_p1 = qcc_unres_p1,
  unres_all = qcc_unres_all
)

saveRDS(qcc_results, file = paste0(OUTPUT_PATH, "qcc_results.rds"))

cat("==========================================================\n")
cat("Control charts completed!\n")
cat("Plots saved to:", FIGURE_PATH, "\n")
cat("==========================================================\n\n")
