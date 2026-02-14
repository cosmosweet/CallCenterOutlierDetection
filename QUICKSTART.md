# Quick Start Guide
# SPC Project - Call Center Outlier Detection

## 🚀 빠른 시작

### 1단계: 프로젝트 클론 또는 다운로드
```bash
git clone <repository-url>
cd spc_project
```

### 2단계: 데이터 파일 준비
```
data/
└── Telecom Company Call-Center-Dataset.xlsx  # 이 파일을 여기에 배치하세요
```

### 3단계: R 실행 및 패키지 설치
```r
# R 또는 RStudio 실행 후

# 작업 디렉토리 설정
setwd("path/to/spc_project")

# 필수 패키지 설치
install.packages(c(
  "readxl", "dplyr", "lubridate", "qcc", "zoo",
  "ggplot2", "knitr", "tibble", "spc", "MSQC"
))
```

### 4단계: 전체 분석 실행
```r
source("main.R")
```

완료! 결과는 `outputs/` 폴더에서 확인하세요.

## 📂 출력 파일 위치

### 그래프 (PNG)
```
outputs/figures/
├── p_chart_unanswered_phase1.png
├── p_chart_unanswered_combined.png
├── p_chart_unresolved_phase1.png
├── p_chart_unresolved_combined.png
├── cusum_unanswered.png
├── cusum_unresolved.png
├── ewma_unanswered_lambda08.png
├── ewma_unresolved_lambda08.png
├── ewma_unresolved_lambda05.png
├── ewma_unresolved_lambda02.png
├── hotelling_t2_original.png
├── hotelling_t2_phase1_original.png
├── hotelling_t2_phase1_clean.png
├── hotelling_t2_phase2_clean.png
└── hotelling_t2_phase1_iterative.png
```

### 테이블 (CSV)
```
outputs/tables/
├── table_p1_unanswered_rate.csv
├── table_p1_unresolved_rate.csv
├── cusum_run_length_unresolved.csv
└── hotelling_phase2_outliers.csv
```

## 🔧 주요 설정 변경

### 분석 기간 변경
`config.R` 파일 수정:
```r
PHASE1_START <- as.Date("2021-01-01")
PHASE1_END   <- as.Date("2021-01-25")
PHASE2_START <- as.Date("2021-01-26")
PHASE2_END   <- as.Date("2021-03-31")
```

### CUSUM 파라미터 조정
```r
CUSUM_K <- 0.25  # 작을수록 민감
CUSUM_H <- 5     # 클수록 덜 민감
```

### EWMA lambda 값 변경
```r
LAMBDA_VALUES <- c(0.8, 0.5, 0.2)  # 원하는 값 추가/변경
LAMBDA_DEFAULT <- 0.8
```

## 🎯 스크립트별 실행

개별 분석만 실행하고 싶다면:

```r
source("config.R")
source("utils/helper_functions.R")

# 원하는 스크립트만 실행
source("scripts/01_data_preprocessing.R")  # 데이터 전처리
source("scripts/02_phase1_analysis.R")     # Phase 1 분석
source("scripts/03_control_charts.R")      # p-차트
source("scripts/04_cusum_ewma.R")          # CUSUM/EWMA
source("scripts/05_multivariate_analysis.R") # Hotelling T²
```

## 💡 팁

1. **첫 실행 시간**: 전체 분석은 약 1-2분 소요
2. **그래프 한글 깨짐**: `config.R`에서 `FONT_FAMILY` 변경
3. **메모리 절약**: 큰 데이터셋의 경우 스크립트 개별 실행 권장

## ❓ 문제 해결

### "cannot open file" 오류
→ 작업 디렉토리가 프로젝트 루트인지 확인: `getwd()`

### 패키지 로드 오류
→ 패키지 재설치: `install.packages("패키지명")`

### 그래프가 안 보임
→ RStudio Plots 창 확인 또는 `outputs/figures/` 폴더 확인

## 📧 도움이 필요하신가요?

자세한 내용은 `README.md`를 참조하세요!
