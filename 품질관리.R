library(ggplot2)
library(readxl)
library(dplyr)
library(lubridate)
library(qcc)
library(zoo)
setwd('/Users/choiinjoon/25-2/25-통계적품질관리/품질관리 프로젝트')
df <- read_excel('Telecom Company Call-Center-Dataset.xlsx')
dim(df)
head(df)
# 변수명 변경
colnames(df) <- c(
  "CallID", "Agent", "Date", "Time", "Topic",
  "Answered", "Resolved", "SpeedAnswer", "TalkDur", "Satisfaction"
)

################# 데이터를 하루 단위로 집계 ###################
df <- df %>%
  mutate(Date = as.Date(Date)) %>%
  group_by(Date) %>%
  summarise(
    n_all   = n(),                                   # 하루 총 문의
    d_unans = sum(Answered == "N", na.rm=TRUE),      # 미응대 건수
    n_ans   = sum(Answered == "Y", na.rm=TRUE),      # 응대한 건수
    d_unres = sum(Answered=="Y" & Resolved=="N", na.rm=TRUE) # 미해결 건수
  ) %>%
  mutate(
    p_unans = d_unans / n_all,                       # 미응대율 (p)
    p_unres = ifelse(n_ans>0, d_unres / n_ans, NA)   # 미해결률 (p)
  ) %>%
  arrange(Date)
head(df)
################## 데이터를 전공서와 같은 방식으로 요약 ################
library(dplyr)
library(knitr)
library(tibble)

# ---- Phase 1 필터 ----
df_p1 <- df %>%
  filter(Date >= as.Date("2021-01-01"),
         Date <= as.Date("2021-01-25")) %>%
  arrange(Date)

k <- 3  # 3σ

## 1) 미응대율 ---------------------------
pbar_unans <- with(df_p1, sum(d_unans, na.rm=TRUE) / sum(n_all, na.rm=TRUE))

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
  mutate(Date = as.character(Date))  # ★ Date를 문자로 통일

# 합계/가중평균
n_sum_unans <- sum(df_p1$n_all, na.rm=TRUE)
d_sum_unans <- sum(df_p1$d_unans, na.rm=TRUE)

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

cat("📘 Table P1-1. 미응대율 (Unanswered Rate) – Phase 1 (2021-01-01 ~ 2021-01-25)\n")
kable(table_unans_p1, digits = 3, align = "ccccccc")

## 2) 미해결률 ---------------------------
pbar_unres <- with(df_p1, sum(d_unres, na.rm=TRUE) / sum(n_ans, na.rm=TRUE))

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
  mutate(Date = as.character(Date))  # ★ 문자로 통일


# 합계/가중평균
n_sum_unres <- sum(df_p1$n_ans, na.rm=TRUE)
d_sum_unres <- sum(df_p1$d_unres, na.rm=TRUE)

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

cat("\n📘 Table P1-2. 미해결률 (Unresolved Rate) – Phase 1 (2021-01-01 ~ 2021-01-25)\n")
kable(table_unres_p1, digits = 3, align = "ccccccc")

#################### 관리도 적합 ######################
# ==========================================================
# 📦 패키지 로드
# ==========================================================
library(dplyr)
library(qcc)

# ==========================================================
# 📅 Phase 1 데이터 필터 (2021-01-01 ~ 2021-01-25)
# ==========================================================
df_p1 <- df %>%
  filter(Date >= as.Date("2021-01-01"),
         Date <= as.Date("2021-01-25")) %>%
  arrange(Date)
# phase 2 데이터
df_p2 <- df %>%
  filter(Date >= as.Date("2021-01-26"),
         Date <= as.Date("2021-03-31")) %>%
  arrange(Date)
# ==========================================================
# ⚙️ 그래프 환경 설정 (Mac 전용 한글 폰트 적용)
# ==========================================================
par(family = "AppleGothic")       # ✅ 그래프 폰트: AppleGothic
qcc.options(
  title.font = 2,                 # 제목 Bold
  cex.title  = 1.1,               # 제목 크기
  digits     = 3                  # 출력 소수점 자리
)
# ==========================================================
# 📘 1️⃣ 미응대율 (Unanswered Rate) 변량 p-관리도
# ==========================================================
library(dplyr)
library(qcc)

## 0) 구간 정의 (예: Phase2는 2021-01-26 ~ 2021-01-31)
df_p1 <- df %>%
  filter(Date >= as.Date("2021-01-01"), Date <= as.Date("2021-01-25")) %>%
  arrange(Date)

df_p2 <- df %>%
  filter(Date >= as.Date("2021-01-26"), Date <= as.Date("2021-03-31")) %>%
  arrange(Date)

## 1) 미응대율: D_i = d_unans, n_i = n_all  (n=0 제거)
p1_unans <- df_p1 %>% filter(n_all > 0)
p2_unans <- df_p2 %>% filter(n_all > 0)

## (A) Phase 1만 먼저 그리기
qcc_unans_p1 <- qcc(
  data   = p1_unans$d_unans,
  sizes  = p1_unans$n_all,
  type   = "p",
  plot   = FALSE
)
plot(qcc_unans_p1,
     title  = "Phase 1 p-관리도 (미응대율, 변량 표본)",
     xlab   = "Date", ylab = "불량률 (미응대율)",
     labels = format(p1_unans$Date, "%m/%d"))

cat("📊 [미응대율 Phase 1]\n",
    "p-bar =", round(qcc_unans_p1$center, 3), "\n")

## (B) Phase 1 기준으로 Phase 2까지 한 번에 합쳐서 그리기 (가장 견고함)
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
plot(qcc_unans_all,
     title = "p-관리도 (미응대율): Phase1 기준으로 Phase2 모니터링",
     xlab  = "Date", ylab = "불량률 (미응대율)")

# ==========================================================
# 📘 2️⃣ 미해결률 (Unresolved Rate) 변량 p-관리도
# ==========================================================

## 2) 미해결률: D_i = d_unres, n_i = n_ans  (n=0 제거)
p1_unres <- df_p1 %>% filter(n_ans > 0)
p2_unres <- df_p2 %>% filter(n_ans > 0)

## (A) Phase 1만
qcc_unres_p1 <- qcc(
  data   = p1_unres$d_unres,
  sizes  = p1_unres$n_ans,
  type   = "p",
  plot   = FALSE
)
plot(qcc_unres_p1,
     title  = "Phase 1 p-관리도 (미해결률, 변량 표본)",
     xlab   = "Date", ylab = "불량률 (미해결률)",
     labels = format(p1_unres$Date, "%m/%d"))

cat("📊 [미해결률 Phase 1]\n",
    "p-bar =", round(qcc_unres_p1$center, 3), "\n")

## (B) Phase 1 기준으로 Phase 2 합쳐서
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
plot(qcc_unres_all,
     title = "p-관리도 (미해결률): Phase1 기준 + Phase2 모니터링",
     xlab  = "Date", ylab = "불량률 (미해결률)")

######################## 미응대율 CUSUM ###############################
library(qcc)
head(df)

# 표준화 진행
pbar_unans_p1 <- sum(df_p1$d_unans) / sum(df_p1$n_all)
df <- df %>%
  mutate(
    z_unans = (p_unans - pbar_unans_p1) /
      sqrt(pbar_unans_p1 * (1 - pbar_unans_p1) / n_all)
  )
cusum_unans <- cusum(data=df$z_unans[1:25], newdata = df$z_unans[26:90],
                     decision.interval = 5, se.shift = 0.5, plot = TRUE,
                     center=0, std.dev = 1)
plot(
  cusum_unans,
  title       = ""
)
title("CUSUM 관리도 (미응대율): k= 0.25, h = 5")
######################## 미응대율 EWMA ###############################
# 폰트 한글 깨지면 이거 먼저 (선택)
par(family = "AppleGothic")

lambda <- 0.8   # EWMA 가중치 (최근값 반영 정도)

ewma_unans_all <- ewma(
  data      = df$z_unans[1:25],          # Phase1
  newdata   = df$z_unans[26:90],         # Phase2
  center    = 0,
  std.dev   = 1,
  lambda    = 0.8,
  nsigmas   = nsigmas1,
  labels    = format(df_p1$Date, "%m/%d"),
  newlabels = format(df$Date[26:90], "%m/%d"),
  plot      = FALSE
)
plot(
  ewma_unans_all,
  title = "",         # 자동 제목 제거
  add.stats = FALSE,  # 하단 통계 정보 제거 (선택)
  restore.par = FALSE
)
title("EWMA 관리도 (미응대율): lambda: 0.8")
######################## EWMA ###############################
library(spc)
nsigmas1<-xewma.crit(l=0.8,L0=370, mu0=0, sided = "two"); nsigmas1
nsigmas2<-xewma.crit(l=0.5,L0=370, mu0=0, sided = "two"); nsigmas2
nsigmas3<-xewma.crit(l=0.2,L0=370, mu0=0, sided = "two"); nsigmas3
xewma.crit(l=0.2,L0=370, mu0=0)

######################## 미해결률 EWMA ###############################
library(qcc)
library(dplyr)

head(df)

## -----------------------------
## 1. 미해결률 표준화 (Phase1 기준)
## -----------------------------
pbar_unres_p1 <- sum(df_p1$d_unres) / sum(df_p1$n_ans)

# 표준화 z_unres 계산 (정확한 버전!)
df <- df %>%
  mutate(
    z_unres = (p_unres - pbar_unres_p1) /
      sqrt(pbar_unres_p1 * (1 - pbar_unres_p1) / n_ans)
  )

## -----------------------------
## 2. 표준화 CUSUM (미해결률)
## -----------------------------
cusum_unres <- cusum(
  data    = df$z_unres[1:25],    # Phase 1
  newdata = df$z_unres[26:90],   # Phase 2
  decision.interval = 5,
  se.shift          = 0.5,
  plot      = TRUE,
  center    = 0,
  std.dev   = 1
)
plot(
  cusum_unres,
  title       = ""
)
title("CUSUM 관리도 (미해결률): k= 0.25, h = 5")
## -----------------------------
## 3. EWMA (미해결률, λ = 0.8)
## -----------------------------
# 한글 폰트 (이미 위에서 했으면 생략 가능)
par(family = "AppleGothic")

lambda <- 0.2

ewma_unres_all <- ewma(
  data      = df$z_unres[1:25],
  newdata   = df$z_unres[26:90],
  center    = 0,
  std.dev   = 1,
  lambda    = lambda,
  nsigmas   = nsigmas1,
  labels    = format(df_p1$Date, "%m/%d"),
  newlabels = format(df$Date[26:90], "%m/%d"),
  plot      = FALSE
)

plot(
  ewma_unres_all,
  title       = "",
  add.stats   = FALSE,
  restore.par = FALSE
)
title("EWMA 관리도 (미해결률): lambda = 0.8")
################## CUSUM 관련 #################
library(dplyr)

z <- df$z_unres   # 표준화된 미해결률
k <- 0.25
h <- 4

n <- length(z)
Cp <- numeric(n)   # 양의 CUSUM

Cm <- numeric(n)   # 음의 CUSUM

for (i in 1:n) {
  if (i == 1) {
    Cp[i] <- max(0, z[i] - k)
    Cm[i] <- min(0, z[i] + k)  # 보통 음의 CUSUM은 이렇게 잡음
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
# 양 방향 신호 지점
signal_pos_idx <- which(cusum_df$Cp >= h)
signal_neg_idx <- which(cusum_df$Cm <= -h)

signal_pos_idx
signal_neg_idx

# 양쪽 공용으로 쓰는 run length 계산 함수
compute_run_info <- function(cusum_vec, signal_idx, direction = "pos") {
  if (length(signal_idx) == 0) return(NULL)
  
  res <- lapply(signal_idx, function(idx) {
    # idx 이전까지 중 마지막으로 0이었던 위치
    if (idx == 1) {
      start <- 1
    } else {
      zero_before <- which(cusum_vec[1:(idx-1)] == 0)
      if (length(zero_before) == 0) {
        start <- 1
      } else {
        start <- max(zero_before) + 1
      }
    }
    data.frame(
      signal_at   = idx,
      start_at    = start,
      run_length  = idx - start + 1,
      direction   = direction
    )
  })
  
  do.call(rbind, res)
}

run_pos <- compute_run_info(cusum_df$Cp, signal_pos_idx, direction = "pos")
run_neg <- compute_run_info(cusum_df$Cm, signal_neg_idx, direction = "neg")


run_info <- bind_rows(run_pos, run_neg) %>%
  arrange(signal_at)

run_info

# 양의 CUSUM 신호 시점에서 C+
cusum_df$Cp[signal_pos_idx]

# 음의 CUSUM 신호 시점에서 C-
cusum_df$Cm[signal_neg_idx]

######################## 다변량 관리도 #########################
# Phase 1: 1일 ~ 25일
Z_p1 <- df %>%
  slice(1:25) %>%              # Phase 1 25일
  select(z_unans, z_unres) %>% # 표준화된 두 품질특성치
  as.matrix()

Z_p2 <- df %>% 
  slice(26:90) %>%
  select(z_unans, z_unres) %>%
  as.matrix()

# 평균벡터, 공분산행렬
Z_bar <- colMeans(Z_p1)
S     <- cov(Z_p1)
S_inv <- solve(S)              # 2x2라 solve 써도 됨

# 전체 90일에 대한 T² 계산 (Phase1+Phase2 같이 보고 싶을 때)
df$T2 <- apply(df[, c("z_unans", "z_unres")], 1, function(z){
  zc <- z - Z_bar
  as.numeric(t(zc) %*% S_inv %*% zc)
})

library(MSQC)
chart1 <- mult.chart(Z_p1,
                     type = 't2',
                     alpha = 0.05,
                     phase = 1)
vec <- chart1$Xmv
mat <- chart1$covariance
chart2 <- mult.chart(Z_p2,
           type = 't2',
           Xmv=vec,
           S=mat,
           alpha = 0.05)

# ==================== 직접 호텔링 계산 =======================#
# 항상 library()!
library(dplyr)
library(ggplot2)

# Phase 1: 1일 ~ 25일
Z_p1 <- df %>%
  slice(1:25) %>%              # Phase 1: 25일
  select(z_unans, z_unres) %>% # 표준화된 두 품질특성치
  as.matrix()

# Phase 2: 26일 ~ 90일
Z_p2 <- df %>%
  slice(26:90) %>%
  select(z_unans, z_unres) %>%
  as.matrix()

# 차원, 샘플 수, 유의수준
p     <- ncol(Z_p1)   # 변수 개수 (=2)
m     <- nrow(Z_p1)   # Phase1 샘플 개수 (=25)
alpha <- 0.05

# Phase1 기준: 평균벡터, 공분산행렬, 역행렬
Z_bar <- colMeans(Z_p1)
S     <- cov(Z_p1)
S_inv <- solve(S)

# Hotelling T² 계산 함수 (개별 관측치 n=1인 경우)
T2_fun <- function(Z, mean_vec, S_inv) {
  apply(Z, 1, function(z) {
    zc <- z - mean_vec          # 중심화
    as.numeric(t(zc) %*% S_inv %*% zc)
  })
}

# Phase1, Phase2 T² 계산
T2_1 <- T2_fun(Z_p1, Z_bar, S_inv)  # 1~25일
T2_2 <- T2_fun(Z_p2, Z_bar, S_inv)  # 26~90일

# Phase1 UCL (chi-square 근사)
UCL1 <- qchisq(1 - alpha, df = p)

# Phase2 UCL (Hotelling T² 정식 F분포 보정)
UCL2 <- ((m + 1) * (m - 1) * p) / (m * (m - p)) * 
  qf(1 - alpha, df1 = p, df2 = m - p)

UCL1; UCL2

df_T2 <- df %>%
  mutate(
    day   = row_number(),                      # 1~90일
    phase = if_else(day <= m, "Phase1", "Phase2"),
    T2    = c(T2_1, T2_2),                     # 직접 계산한 T²
    UCL   = if_else(phase == "Phase1", UCL1, UCL2),
    out   = T2 > UCL                           # 관리한계 초과 여부
  )

ggplot(df_T2, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  # Phase1 UCL (1~m일)
  geom_segment(aes(x = 1, xend = m,
                   y = UCL1, yend = UCL1),
               linetype = "dashed") +
  # Phase2 UCL (m+1~90일)
  geom_segment(aes(x = m + 1, xend = 90,
                   y = UCL2, yend = UCL2),
               linetype = "dashed") +
  scale_color_manual(values = c(`FALSE` = "black", `TRUE` = "red")) +
  labs(
    x = "일(day)",
    y = expression(T^2),
    color = "UCL 초과 여부",
    title = "Hotelling T² 다변량 관리도"
  ) +
  theme_bw(base_family = "AppleGothic")

# ======================== 호텔링 Phase 1 이상치 제거 ==========================#
# 원래 Phase1 인덱스 (1~25일)
idx <- 1:nrow(Z_p1)

# 현재 Phase1 데이터 (반복하면서 줄어들 예정)
Z_cur <- Z_p1

repeat {
  # 현재 Phase1 기준 평균, 공분산, 역행렬
  Z_bar_cur <- colMeans(Z_cur)
  S_cur     <- cov(Z_cur)
  S_inv_cur <- solve(S_cur)
  
  # 현재 Phase1의 T² 계산
  T2_cur <- T2_fun(Z_cur, Z_bar_cur, S_inv_cur)
  
  # Phase1 UCL (chi-square 근사, p 고정)
  UCL1 <- qchisq(1 - alpha, df = p)
  
  # 이상점 표시
  out_flag <- T2_cur > UCL1
  
  # 더 이상 이상점이 없으면 종료
  if (!any(out_flag)) break
  
  # 어떤 원래 day들이 제거되는지 출력
  cat("Removing out-of-control points (day):",
      paste(idx[out_flag], collapse = ", "), "\n")
  
  # 그 인덱스들 제거
  idx  <- idx[!out_flag]                # 남는 day
  Z_cur <- Z_cur[!out_flag, , drop=FALSE]  # 남는 관측치
}

# 반복이 끝난 시점에서:
# - idx       : 최종 in-control day (Phase1)
# - Z_cur     : 최종 깨끗한 Phase1 데이터
# - Z_bar_cur : 최종 평균벡터
# - S_cur     : 최종 공분산행렬
# - S_inv_cur : 최종 역행렬
# - T2_cur    : 최종 Phase1 T² (모두 UCL 아래)
# - UCL1      : Phase1 UCL
m_final <- length(idx)   # 최종 Phase1 샘플 수
m_final

df_p1_final <- data.frame(
  day = idx,       # 원래 일자(1~25 중 남은 것들)
  T2  = T2_cur
) %>%
  mutate(
    UCL = UCL1,
    out = T2 > UCL   # 이젠 전부 FALSE일 것
  )

ggplot(df_p1_final, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  geom_hline(yintercept = UCL1, linetype = "dashed") +
  scale_color_manual(
    values = c(`FALSE` = "black", `TRUE` = "red"),
    name   = "UCL 초과 여부"
  ) +
  labs(
    title = "Phase1 Hotelling T² 관리도 (반복 제거 후 최종)",
    x = "일(day)",
    y = expression(T^2)
  ) +
  theme_bw(base_family = "AppleGothic")

# 최종 Phase1 기준으로 Phase2 T² 계산
T2_2_final <- T2_fun(Z_p2, Z_bar_cur, S_inv_cur)

# Phase2 UCL (Hotelling T², 개별관측, 모수 미지, m = m_final)
UCL2 <- ((m_final + 1) * (m_final - 1) * p) /
  (m_final * (m_final - p)) *
  qf(1 - alpha, df1 = p, df2 = m_final - p)

# Phase2 day: 26~90일
day_p2 <- (nrow(Z_p1) + 1):(nrow(Z_p1) + nrow(Z_p2))

df_p2_final <- data.frame(
  day = day_p2,
  T2  = T2_2_final
) %>%
  mutate(
    UCL = UCL2,
    out = T2 > UCL
  )

ggplot(df_p2_final, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  geom_hline(yintercept = UCL2, linetype = "dashed") +
  scale_color_manual(
    values = c(`FALSE` = "black", `TRUE` = "red"),
    name   = "UCL 초과 여부"
  ) +
  labs(
    title = "Phase2 Hotelling T² 관리도 (최종 Phase1 기반)",
    x = "일(day)",
    y = expression(T^2)
  ) +
  theme_bw(base_family = "AppleGothic")




# ===================== 호텔링 이상치 한 번만 제거 ========================== #
############################################
# (1) Phase1만 출력 (원본, 이상점 포함)
############################################

# Phase1 day 인덱스 (1~m일)
day_p1 <- 1:m

# Phase1 UCL (chi-square 근사)
UCL1 <- qchisq(1 - alpha, df = p)

# Phase1 결과 데이터프레임
df_p1 <- data.frame(
  day = day_p1,
  T2  = T2_1
) %>%
  mutate(
    UCL = UCL1,
    out = T2 > UCL
  )

# Phase1 관리도 (원본)
ggplot(df_p1, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  geom_hline(yintercept = UCL1, linetype = "dashed") +
  scale_color_manual(
    values = c(`FALSE` = "black", `TRUE` = "red"),
    name   = "UCL 초과 여부"
  ) +
  labs(
    title = "Phase1 Hotelling T² 관리도 (원본)",
    x = "일(day)",
    y = expression(T^2)
  ) +
  theme_bw(base_family = "AppleGothic")

# 어떤 날이 이상점인지 확인
out_idx <- df_p1$day[df_p1$out]
out_idx

############################################
# (2) Phase1에서 이상점 제거
############################################

# 이상점 제거한 index (in-control인 날만 남김)
keep_idx <- setdiff(day_p1, out_idx)

# 깨끗한 Phase1 데이터 (Z_p1에서 이상점 행 제거)
Z_p1_clean <- Z_p1[keep_idx, , drop = FALSE]
m_clean    <- nrow(Z_p1_clean)   # 변경된 m

# 깨끗한 Phase1 기준 평균, 공분산, 역행렬
Z_bar_clean <- colMeans(Z_p1_clean)
S_clean     <- cov(Z_p1_clean)
S_inv_clean <- solve(S_clean)

# 깨끗한 Phase1의 T² 다시 계산
T2_1_clean <- T2_fun(Z_p1_clean, Z_bar_clean, S_inv_clean)

# UCL은 여전히 chi-square 근사 사용
UCL1_clean <- qchisq(1 - alpha, df = p)

# 깨끗한 Phase1 결과 데이터프레임
df_p1_clean <- data.frame(
  day = keep_idx,
  T2  = T2_1_clean
) %>%
  mutate(
    UCL = UCL1_clean,
    out = T2 > UCL
  )

############################################
# (3) 이상점 제거 후 Phase1 재출력
############################################

ggplot(df_p1_clean, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  geom_hline(yintercept = UCL1_clean, linetype = "dashed") +
  scale_color_manual(
    values = c(`FALSE` = "black", `TRUE` = "red"),
    name   = "UCL 초과 여부"
  ) +
  labs(
    title = "Phase1 Hotelling T² 관리도 (이상점 제거 후)",
    x = "일(day)",
    y = expression(T^2)
  ) +
  theme_bw(base_family = "AppleGothic")

m_clean  # 최종 Phase1에서 사용된 m 값 확인

############################################
# (4) 변경된 m, 새로운 평균/공분산으로 Phase2 출력
############################################

# Phase2 day 인덱스: 26~90일 (Z_p2의 행 개수 기준)
day_p2 <- (m + 1):(m + nrow(Z_p2))   # = 26:90

# Phase2 T² 다시 계산 (깨끗한 Phase1 기준)
T2_2_phase2 <- T2_fun(Z_p2, Z_bar_clean, S_inv_clean)

# Phase2 UCL (Hotelling T² 정식 F 보정, m = m_clean)
UCL2 <- ((m_clean + 1) * (m_clean - 1) * p) /
  (m_clean * (m_clean - p)) *
  qf(1 - alpha, df1 = p, df2 = m_clean - p)

df_p2 <- data.frame(
  day = day_p2,
  T2  = T2_2_phase2
) %>%
  mutate(
    UCL = UCL2,
    out = T2 > UCL
  )

# Phase2 관리도
ggplot(df_p2, aes(x = day, y = T2)) +
  geom_line() +
  geom_point(aes(color = out)) +
  geom_hline(yintercept = UCL2, linetype = "dashed") +
  scale_color_manual(
    values = c(`FALSE` = "black", `TRUE` = "red"),
    name   = "UCL 초과 여부"
  ) +
  labs(
    title = "Phase2 Hotelling T² 관리도",
    x = "일(day)",
    y = expression(T^2)
  ) +
  theme_bw(base_family = "AppleGothic")

############################################
# (5) Phase2 이상점 좌표 추출
############################################

# Phase2에서 이상점인 행 인덱스 (논리 → 위치)
out_idx_p2  <- which(df_p2$out)        # Phase2 내에서 몇 번째 행인지
out_days_p2 <- df_p2$day[out_idx_p2]   # 실제 day 번호 (예: 26, 27, ...)

# 해당 day의 다변량 좌표 (여기서는 Z_p2의 열이 품질특성치들)
# Z_p2에 colnames가 z_unans, z_unres 등으로 붙어 있다면 그대로 같이 가져옴
out_coords_p2 <- cbind(
  day = out_days_p2,
  as.data.frame(Z_p2[out_idx_p2, , drop = FALSE])
)

out_coords_p2

############################################
# (5) Phase2 이상점 원본 좌표 추출
############################################

# Phase2에서 이상점인 인덱스 (df_p2 기준)
out_idx_p2  <- which(df_p2$out)          
out_days_p2 <- df_p2$day[out_idx_p2]     # 실제 day 번호 (예: 26, 27, ...)

# Phase2의 원본 데이터 (df에서 Phase2 기간만 슬라이스)
orig_p2 <- df[day_p2, ]   # df는 원본 데이터프레임

# Phase2의 이상점 원본 값만 추출
orig_out_p2 <- orig_p2[out_idx_p2, , drop = FALSE]

orig_out_p2
