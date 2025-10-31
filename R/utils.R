#' Validate Market Data
#'
#' Validates that market data conforms to expected structure and quality standards.
#' Checks for proper column names, data types, OHLC consistency, and missing values.
#'
#' @param data A data frame or tibble with market data
#' @param strict Logical: if TRUE, throw errors on validation failures; if FALSE, issue warnings
#'
#' @return The validated data (invisibly), or throws an error if validation fails
#' @export
#'
#' @examples
#' \dontrun{
#' data <- fetch_prices("AAPL", from = "2024-01-01")
#' validate_market_data(data)
#' }
validate_market_data <- function(data, strict = TRUE) {
        
        issues <- character()
        
        # Check if data frame
        if (!is.data.frame(data)) {
                stop("Data must be a data frame or tibble")
        }
        
        # Check required columns
        required_cols <- c("symbol", "datetime", "open", "high", "low", "close", "volume")
        missing_cols <- setdiff(required_cols, names(data))
        
        if (length(missing_cols) > 0) {
                issues <- c(issues, paste("Missing columns:", paste(missing_cols, collapse = ", ")))
        }
        
        # Check data types
        if ("datetime" %in% names(data) && !inherits(data$datetime, "POSIXct")) {
                issues <- c(issues, "Column 'datetime' must be POSIXct type")
        }
        
        numeric_cols <- c("open", "high", "low", "close", "volume")
        for (col in intersect(numeric_cols, names(data))) {
                if (!is.numeric(data[[col]])) {
                        issues <- c(issues, paste("Column", col, "must be numeric"))
                }
        }
        
        # Check for empty data
        if (nrow(data) == 0) {
                issues <- c(issues, "Data contains zero rows")
        }
        
        # Check OHLC consistency
        if (all(c("open", "high", "low", "close") %in% names(data))) {
                # High should be >= Open, Close, Low
                high_violations <- which(
                        data$high < data$open | 
                        data$high < data$close | 
                        data$high < data$low
                )
                
                if (length(high_violations) > 0) {
                        issues <- c(issues, paste(
                                "High price violations at",
                                length(high_violations),
                                "rows"
                        ))
                }
                
                # Low should be <= Open, Close, High
                low_violations <- which(
                        data$low > data$open | 
                        data$low > data$close | 
                        data$low > data$high
                )
                
                if (length(low_violations) > 0) {
                        issues <- c(issues, paste(
                                "Low price violations at",
                                length(low_violations),
                                "rows"
                        ))
                }
        }
        
        # Check for missing values
        for (col in required_cols) {
                if (col %in% names(data)) {
                        n_missing <- sum(is.na(data[[col]]))
                        if (n_missing > 0) {
                                issues <- c(issues, paste(
                                        col, "has", n_missing, "missing values"
                                ))
                        }
                }
        }
        
        # Report issues
        if (length(issues) > 0) {
                msg <- paste("Data validation issues:\n", paste("  -", issues, collapse = "\n"))
                if (strict) {
                        stop(msg)
                } else {
                        warning(msg)
                }
        }
        
        invisible(data)
}


#' Fill Missing Data
#'
#' Fill missing values in market data using various methods.
#'
#' @param data A `market_tbl` object
#' @param method Character: "forward" (last observation carried forward),
#'   "backward" (next observation carried backward), "linear" (linear interpolation),
#'   or "spline" (spline interpolation)
#' @param columns Character vector: columns to fill (default: all numeric columns)
#'
#' @return A `market_tbl` with filled values
#' @export
#'
#' @examples
#' \dontrun{
#' data <- fetch_prices("AAPL", from = "2024-01-01")
#' 
#' # Forward fill
#' filled <- fill_missing_data(data, method = "forward")
#' 
#' # Linear interpolation
#' filled <- fill_missing_data(data, method = "linear")
#' }
fill_missing_data <- function(data,
                             method = c("forward", "backward", "linear", "spline"),
                             columns = NULL) {
        
        method <- match.arg(method)
        
        if (!requireNamespace("zoo", quietly = TRUE)) {
                stop("Package 'zoo' is required. Install with: install.packages('zoo')")
        }
        
        # Default to all numeric columns except datetime
        if (is.null(columns)) {
                columns <- names(data)[sapply(data, is.numeric)]
        }
        
        # Group by symbol if multiple symbols
        if ("symbol" %in% names(data)) {
                data <- dplyr::group_by(data, symbol)
        }
        
        # Apply filling method
        for (col in columns) {
                if (col %in% names(data)) {
                        data[[col]] <- switch(
                                method,
                                forward = zoo::na.locf(data[[col]], na.rm = FALSE),
                                backward = zoo::na.locf(data[[col]], na.rm = FALSE, fromLast = TRUE),
                                linear = zoo::na.approx(data[[col]], na.rm = FALSE),
                                spline = zoo::na.spline(data[[col]], na.rm = FALSE)
                        )
                }
        }
        
        if ("symbol" %in% names(data)) {
                data <- dplyr::ungroup(data)
        }
        
        return(data)
}


#' Adjust Prices for Stock Splits
#'
#' Adjust historical prices for stock splits to ensure continuity.
#'
#' @param data A `market_tbl` object
#' @param split_ratio Numeric: split ratio (e.g., 2 for 2-for-1 split)
#' @param split_date Date: date of the split
#'
#' @return A `market_tbl` with adjusted prices
#' @export
#'
#' @examples
#' \dontrun{
#' # Adjust for 2-for-1 split on 2024-06-01
#' adjusted <- adjust_for_splits(data, split_ratio = 2, split_date = "2024-06-01")
#' }
adjust_for_splits <- function(data, split_ratio, split_date) {
        
        split_date <- as.POSIXct(as.Date(split_date))
        
        # Adjust prices before split date
        data <- data |>
                dplyr::mutate(
                        open = ifelse(datetime < split_date, open / split_ratio, open),
                        high = ifelse(datetime < split_date, high / split_ratio, high),
                        low = ifelse(datetime < split_date, low / split_ratio, low),
                        close = ifelse(datetime < split_date, close / split_ratio, close),
                        adjusted = ifelse(datetime < split_date, adjusted / split_ratio, adjusted),
                        volume = ifelse(datetime < split_date, volume * split_ratio, volume)
                )
        
        return(data)
}


#' Set Timezone for Market Data
#'
#' Convert datetime column to specified timezone.
#'
#' @param data A `market_tbl` object
#' @param tz Character: target timezone (e.g., "America/New_York", "UTC", "Asia/Tokyo")
#'
#' @return A `market_tbl` with converted timezone
#' @export
#'
#' @examples
#' \dontrun{
#' # Convert to UTC
#' data_utc <- set_timezone(data, "UTC")
#' 
#' # Convert to Tokyo time
#' data_tokyo <- set_timezone(data, "Asia/Tokyo")
#' }
set_timezone <- function(data, tz = "UTC") {
        
        if (!"datetime" %in% names(data)) {
                stop("Data must have 'datetime' column")
        }
        
        data$datetime <- lubridate::with_tz(data$datetime, tzone = tz)
        
        # Update timezone attribute
        attr(data, "timezone") <- tz
        
        return(data)
}


#' Normalize Ticker Symbols
#'
#' Standardize ticker symbols across different data sources.
#'
#' @param tickers Character vector: ticker symbols to normalize
#' @param source Character: source format to convert to (default: "yahoo")
#'
#' @return Character vector of normalized ticker symbols
#' @export
#'
#' @examples
#' normalize_tickers(c("AAPL", "BTC-USD", "^GSPC"))
normalize_tickers <- function(tickers, source = "yahoo") {
        
        # Common conversions
        if (source == "yahoo") {
                # Yahoo format is already standard
                return(tickers)
        } else if (source == "alpha_vantage") {
                # Alpha Vantage doesn't use suffixes like -USD
                tickers <- gsub("-USD$", "", tickers)
                tickers <- gsub("^BTC-USD$", "BTC", tickers)
        }
        
        return(tickers)
}


#' Check if Market Data is Valid
#'
#' Quick check if data is a valid market_tbl object.
#'
#' @param data Object to check
#'
#' @return Logical: TRUE if valid market data
#' @export
is_market_tbl <- function(data) {
        inherits(data, "market_tbl") &&
                is.data.frame(data) &&
                all(c("symbol", "datetime", "open", "high", "low", "close", "volume") %in% names(data))
}


# Global variable bindings for R CMD check
utils::globalVariables(c(
        "symbol", "datetime", "open", "high", "low", "close", "volume", "adjusted"
))
