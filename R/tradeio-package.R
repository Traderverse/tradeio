#' tradeio: Data Acquisition for TradingVerse
#'
#' @description
#' `tradeio` provides a unified interface for fetching financial market data
#' from multiple sources. All data is automatically normalized into the 
#' TradingVerse `market_tbl` format for seamless integration with other
#' packages in the ecosystem.
#'
#' @section Main Functions:
#' * [fetch_prices()] - Universal data fetching function
#' * [fetch_yahoo()] - Fetch from Yahoo Finance
#' * [fetch_alpha_vantage()] - Fetch from Alpha Vantage API
#' * [fetch_csv()] - Load from CSV files
#' * [fill_missing_data()] - Handle missing data
#' * [validate_market_data()] - Validate data quality
#'
#' @section Data Sources:
#' * Yahoo Finance (default, free, no API key)
#' * Alpha Vantage (API key required)
#' * CSV files (custom data)
#' * Extensible for custom sources
#'
#' @section Output Format:
#' All functions return a `market_tbl` object with standardized columns:
#' * symbol: Asset identifier
#' * datetime: Timestamp (timezone-aware)
#' * open, high, low, close: OHLC prices
#' * volume: Trading volume
#' * adjusted: Adjusted close price
#'
#' @docType package
#' @name tradeio-package
#' @aliases tradeio
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
