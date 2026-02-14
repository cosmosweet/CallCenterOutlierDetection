# Outlier Detection using SPC in Call Center Dataset

Statistical Process Control (SPC) 기법을 활용한 콜센터 데이터 이상치 탐지 프로젝트

## 📋 프로젝트 개요

본 프로젝트는 통신회사 콜센터 데이터를 대상으로 다양한 통계적 품질관리(SPC) 기법을 적용하여 이상치를 탐지하고 프로세스 안정성을 모니터링합니다.

### 주요 분석 기법
- **p-관리도 (p-chart)**: 미응대율과 미해결률 모니터링 (변량 표본)
- **CUSUM 관리도**: 작은 변화를 민감하게 탐지
- **EWMA 관리도**: 지수가중이동평균을 통한 트렌드 감지
- **Hotelling T² 관리도**: 다변량 품질특성 동시 모니터링

### 분석 대상 품질특성
1. **미응대율 (Unanswered Rate)**: 전체 문의 중 응답하지 못한 비율
2. **미해결률 (Unresolved Rate)**: 응대한 문의 중 해결하지 못한 비율

## 📁 프로젝트 구조

```
spc_project/
├── README.md                          # 프로젝트 설명서
├── main.R                             # 전체 분석 실행 스크립트
├── config.R                           # 설정 및 파라미터
├── data/                              # 원본 데이터
│   └── Telecom Company Call-Center-Dataset.xlsx
├── scripts/                           # 분석 스크립트
│   ├── 01_data_preprocessing.R        # 데이터 전처리
│   ├── 02_phase1_analysis.R           # Phase 1 기초 통계
│   ├── 03_control_charts.R            # p-관리도
│   ├── 04_cusum_ewma.R                # CUSUM/EWMA 관리도
│   └── 05_multivariate_analysis.R     # Hotelling T² 다변량 분석
├── utils/                             # 유틸리티 함수
│   └── helper_functions.R
└── outputs/                           # 분석 결과물
    ├── figures/                       # 그래프 (PNG)
    ├── tables/                        # 요약 테이블 (CSV)
    └── *.rds                          # 중간 결과 (R 객체)
```

## 🚀 시작하기

### 필수 패키지 설치

```r
install.packages(c(
  "readxl", "dplyr", "lubridate", "qcc", "zoo",
  "ggplot2", "knitr", "tibble", "spc", "MSQC"
))
```

### 실행 방법

#### 방법 1: 전체 분석 한 번에 실행
```r
source("main.R")
```

#### 방법 2: 단계별 실행
```r
# 설정 파일 로드
source("config.R")
source("utils/helper_functions.R")

# 각 스크립트 순차 실행
source("scripts/01_data_preprocessing.R")
source("scripts/02_phase1_analysis.R")
source("scripts/03_control_charts.R")
source("scripts/04_cusum_ewma.R")
source("scripts/05_multivariate_analysis.R")
```

## 📊 분석 단계

### 1. 데이터 전처리 (`01_data_preprocessing.R`)
- 원본 데이터 로드 및 변수명 정리
- 일별 집계: 총 문의, 미응대, 미해결 건수 계산
- Phase 1 (2021-01-01 ~ 2021-01-25), Phase 2 (2021-01-26 ~ 2021-03-31) 분할

### 2. Phase 1 분석 (`02_phase1_analysis.R`)
- 미응대율, 미해결률 기초 통계량 계산
- p-bar (평균 불량률) 계산
- 관리한계선 (LCL, UCL) 계산
- 요약 테이블 생성 및 저장

### 3. p-관리도 (`03_control_charts.R`)
- **변량 표본 p-관리도** 작성 (표본 크기가 일정하지 않음)
- Phase 1: 기준선 설정
- Phase 2: Phase 1 기준으로 모니터링
- 관리이탈 포인트 식별

### 4. CUSUM 및 EWMA 관리도 (`04_cusum_ewma.R`)
- **표준화**: Phase 1 기준으로 z-score 변환
- **CUSUM 관리도**:
  - 파라미터: k = 0.25, h = 5
  - 작은 공정 평균 변화 탐지
  - Run length 분석
- **EWMA 관리도**:
  - 다양한 λ 값 테스트 (0.8, 0.5, 0.2)
  - ARL = 370 기준 관리한계 계산
  - 트렌드 탐지

### 5. 다변량 분석 (`05_multivariate_analysis.R`)
- **Hotelling T² 관리도**:
  - 두 품질특성 동시 모니터링 (미응대율 + 미해결률)
  - Phase 1 이상치 제거 (1회 vs 반복)
  - Phase 2 이상 패턴 탐지
- 이상점 좌표 추출 및 저장

## ⚙️ 주요 파라미터

`config.R` 파일에서 다음 파라미터를 조정할 수 있습니다:

```r
# 날짜 범위
PHASE1_START <- as.Date("2021-01-01")
PHASE1_END   <- as.Date("2021-01-25")
PHASE2_START <- as.Date("2021-01-26")
PHASE2_END   <- as.Date("2021-03-31")

# 관리도 파라미터
K_SIGMA <- 3              # 관리한계 배수 (3σ)
ALPHA <- 0.05             # 유의수준

# CUSUM 파라미터
CUSUM_K <- 0.25           # 참조값
CUSUM_H <- 5              # 결정구간

# EWMA 파라미터
LAMBDA_VALUES <- c(0.8, 0.5, 0.2)
```

## 📈 주요 결과물

### 생성되는 그래프
1. `p_chart_unanswered_*.png`: 미응대율 p-관리도
2. `p_chart_unresolved_*.png`: 미해결률 p-관리도
3. `cusum_*.png`: CUSUM 관리도
4. `ewma_*_lambda*.png`: EWMA 관리도 (여러 λ)
5. `hotelling_t2_*.png`: Hotelling T² 관리도

### 생성되는 테이블
1. `table_p1_unanswered_rate.csv`: Phase 1 미응대율 요약
2. `table_p1_unresolved_rate.csv`: Phase 1 미해결률 요약
3. `cusum_run_length_unresolved.csv`: CUSUM run length 정보
4. `hotelling_phase2_outliers.csv`: Phase 2 이상점 좌표

## 🔍 방법론 배경

### Phase I vs Phase II
- **Phase I**: 과거 데이터로 프로세스 안정성 확인 및 기준선 설정
- **Phase II**: 신규 데이터를 Phase I 기준으로 모니터링

### p-관리도 (Variable Sample Size)
표본 크기가 일정하지 않을 때 사용:
```
p̄ = Σdᵢ / Σnᵢ
UCL = p̄ + 3√(p̄(1-p̄)/nᵢ)
LCL = p̄ - 3√(p̄(1-p̄)/nᵢ)
```

### CUSUM (Cumulative Sum)
누적합 통계량으로 작은 변화 탐지:
```
C⁺ᵢ = max(0, C⁺ᵢ₋₁ + zᵢ - k)
C⁻ᵢ = min(0, C⁻ᵢ₋₁ + zᵢ + k)
```

### EWMA (Exponentially Weighted Moving Average)
지수가중평균으로 트렌드 감지:
```
zᵢ = λxᵢ + (1-λ)zᵢ₋₁
```

### Hotelling T²
다변량 관리도:
```
T² = (x̄ - μ)ᵀS⁻¹(x̄ - μ)
```

## 📝 사용 예시

### 특정 기간만 분석
```r
# config.R에서 날짜 수정
PHASE1_START <- as.Date("2021-01-05")
PHASE1_END   <- as.Date("2021-01-20")

# 다시 실행
source("main.R")
```

### 다른 CUSUM 파라미터 테스트
```r
# config.R에서 수정
CUSUM_K <- 0.5
CUSUM_H <- 4

# CUSUM 부분만 재실행
source("scripts/04_cusum_ewma.R")
```

## 🛠️ 트러블슈팅

### 한글 폰트 깨짐
- **Mac**: `FONT_FAMILY <- "AppleGothic"`
- **Windows**: `FONT_FAMILY <- "Malgun Gothic"` 또는 `"NanumGothic"`

### 패키지 설치 오류
```r
# CRAN 미러 변경
options(repos = c(CRAN = "https://cran.rstudio.com/"))
install.packages("패키지명")
```

### 메모리 부족
대용량 데이터 처리 시:
```r
# 메모리 제한 증가 (Windows)
memory.limit(size = 8000)
```

## 📚 참고문헌

1. Montgomery, D. C. (2019). *Introduction to Statistical Quality Control* (8th ed.). Wiley.
2. Ryan, T. P. (2011). *Statistical Methods for Quality Improvement* (3rd ed.). Wiley.
3. Qiu, P. (2013). *Introduction to Statistical Process Control*. CRC Press.

## 👥 기여

프로젝트 개선 제안이나 버그 리포트는 이슈로 등록해주세요.

## 📄 라이선스

MIT License

## 📧 문의

프로젝트 관련 문의사항이 있으시면 이슈를 통해 연락주세요.

---

**Last Updated**: 2025-02-14
