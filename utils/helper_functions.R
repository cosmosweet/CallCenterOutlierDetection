# ==========================================================
# Helper Functions
# Utility functions for SPC analysis
# ==========================================================

#' Compute Hotelling T² statistic
#'
#' @param Z Matrix of observations (n x p)
#' @param mean_vec Mean vector (p x 1)
#' @param S_inv Inverse covariance matrix (p x p)
#' @return Vector of T² values
compute_T2 <- function(Z, mean_vec, S_inv) {
  apply(Z, 1, function(z) {
    zc <- z - mean_vec
    as.numeric(t(zc) %*% S_inv %*% zc)
  })
}

#' Compute run length information for CUSUM
#'
#' @param cusum_vec CUSUM values (C+ or C-)
#' @param signal_idx Indices where signal occurred
#' @param direction Direction of signal ("pos" or "neg")
#' @return Data frame with signal information
compute_run_info <- function(cusum_vec, signal_idx, direction = "pos") {
  if (length(signal_idx) == 0) return(NULL)
  
  res <- lapply(signal_idx, function(idx) {
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

#' Remove outliers from Phase 1 iteratively
#'
#' @param Z_p1 Phase 1 data matrix
#' @param p Number of variables
#' @param alpha Significance level
#' @param verbose Print removal information
#' @return List containing cleaned data and parameters
remove_outliers_iterative <- function(Z_p1, p, alpha = 0.05, verbose = TRUE) {
  idx <- 1:nrow(Z_p1)
  Z_cur <- Z_p1
  
  repeat {
    Z_bar_cur <- colMeans(Z_cur)
    S_cur     <- cov(Z_cur)
    S_inv_cur <- solve(S_cur)
    
    T2_cur <- compute_T2(Z_cur, Z_bar_cur, S_inv_cur)
    UCL1 <- qchisq(1 - alpha, df = p)
    
    out_flag <- T2_cur > UCL1
    
    if (!any(out_flag)) break
    
    if (verbose) {
      cat("Removing out-of-control points (day):",
          paste(idx[out_flag], collapse = ", "), "\n")
    }
    
    idx   <- idx[!out_flag]
    Z_cur <- Z_cur[!out_flag, , drop = FALSE]
  }
  
  list(
    clean_data = Z_cur,
    clean_idx  = idx,
    mean_vec   = colMeans(Z_cur),
    cov_mat    = cov(Z_cur),
    inv_cov    = solve(cov(Z_cur)),
    T2         = compute_T2(Z_cur, colMeans(Z_cur), solve(cov(Z_cur))),
    UCL        = qchisq(1 - alpha, df = p),
    m_final    = nrow(Z_cur)
  )
}

#' Remove outliers from Phase 1 once
#'
#' @param Z_p1 Phase 1 data matrix
#' @param p Number of variables
#' @param alpha Significance level
#' @return List containing cleaned data and parameters
remove_outliers_once <- function(Z_p1, p, alpha = 0.05) {
  # Initial calculation
  Z_bar <- colMeans(Z_p1)
  S     <- cov(Z_p1)
  S_inv <- solve(S)
  
  T2_1 <- compute_T2(Z_p1, Z_bar, S_inv)
  UCL1 <- qchisq(1 - alpha, df = p)
  
  # Find outliers
  out_flag <- T2_1 > UCL1
  out_idx  <- which(out_flag)
  keep_idx <- which(!out_flag)
  
  # Remove outliers
  Z_clean <- Z_p1[keep_idx, , drop = FALSE]
  
  # Recalculate with clean data
  Z_bar_clean <- colMeans(Z_clean)
  S_clean     <- cov(Z_clean)
  S_inv_clean <- solve(S_clean)
  T2_clean    <- compute_T2(Z_clean, Z_bar_clean, S_inv_clean)
  
  list(
    original_data = Z_p1,
    original_idx  = 1:nrow(Z_p1),
    original_T2   = T2_1,
    outlier_idx   = out_idx,
    clean_data    = Z_clean,
    clean_idx     = keep_idx,
    mean_vec      = Z_bar_clean,
    cov_mat       = S_clean,
    inv_cov       = S_inv_clean,
    T2            = T2_clean,
    UCL           = UCL1,
    m_final       = nrow(Z_clean)
  )
}

#' Calculate EWMA critical value using spc package
#'
#' @param lambda EWMA smoothing parameter
#' @param L0 Target ARL
#' @param mu0 Process mean
#' @return Critical value (nsigmas)
calc_ewma_crit <- function(lambda, L0 = 370, mu0 = 0) {
  if (requireNamespace("spc", quietly = TRUE)) {
    spc::xewma.crit(l = lambda, L0 = L0, mu0 = mu0, sided = "two")
  } else {
    warning("Package 'spc' not available. Using default nsigmas = 3")
    return(3)
  }
}

#' Save plot to file
#'
#' @param filename Filename (without path)
#' @param plot_function Function that creates the plot
#' @param width Width in inches
#' @param height Height in inches
save_plot <- function(filename, plot_function, width = 10, height = 6) {
  filepath <- paste0(FIGURE_PATH, filename)
  png(filepath, width = width, height = height, units = "in", res = 300)
  plot_function()
  dev.off()
  cat("Plot saved:", filepath, "\n")
}

#' Print summary statistics table
#'
#' @param df Data frame
#' @param title Table title
print_summary_table <- function(df, title = "") {
  if (title != "") cat("\n", title, "\n", sep = "")
  print(knitr::kable(df, digits = 3, align = "c"))
}
