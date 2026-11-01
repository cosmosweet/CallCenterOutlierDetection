# ==========================================================
# Outlier Detection using SPC in Call Center Dataset
# 전체 파이프라인 실행: 레포 루트에서 `Rscript main.R`
# ==========================================================

required_packages <- c(
  "readxl", "dplyr", "lubridate", "qcc", "zoo",
  "ggplot2", "knitr", "tibble", "spc", "MSQC"
)
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing packages: ", paste(missing_packages, collapse = ", "))
}

source("scripts/01_data_preprocessing.R")    # 일별 집계, Phase 1/2 분할
source("scripts/02_phase1_analysis.R")       # Phase 1 기준선
source("scripts/03_control_charts.R")        # p-관리도
source("scripts/04_cusum_ewma.R")            # CUSUM / EWMA
source("scripts/05_multivariate_analysis.R") # Hotelling T²

cat("\nDone. Figures: outputs/figures/, Tables: outputs/tables/\n")
