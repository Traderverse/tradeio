#' Fetch Market Prices from Multiple Sources
#'
#' Universal function to fetch OHLCV market data from various sources.
#' Automatically detects the best source and returns normalized `market_tbl` data.
#'
#' @param tickers Character vector: one or more ticker symbols (e.g., "AAPL", "BTC-USD")
#' @param from Date or character: start date (default: 1 year ago)
#' @param to Date or character: end date (default: today)
#' @param source Character: data source - "yahoo" (default), "alpha_vantage", or custom
#' @param interval Character: time interval - "daily", "1hour", "1min", etc. (default: "daily")
#' @param auto_adjust Logical: automatically adjust for splits/dividends (default: TRUE)
#' @param api_key Character: API key for sources that require it (e.g., Alpha Vantage)
#' @param ... Additional arguments passed to source-specific functions
#'
#' @return A `market_tbl` object with columns: symbol, datetime, open, high, low, close, volume, adjusted
#' @export
#'
#' @examples
#' \dontrun{
#' # Fetch single stock
#' aapl <- fetch_prices("AAPL", from = "2024-01-01")
#' 
#' # Multiple stocks
#' tech <- fetch_prices(c("AAPL", "MSFT", "GOOGL"), from = "2023-01-01")
#' 
#' # Cryptocurrency
#' btc <- fetch_prices("BTC-USD", from = "2024-01-01")
#' 
#' # Using Alpha Vantage
#' prices <- fetch_prices(
#'   "AAPL",
#'   source = "alpha_vantage",
#'   api_key = Sys.getenv("ALPHA_VANTAGE_KEY")
#' )
#' }
fetch_prices <- function(tickers,
                        from = Sys.Date() - 365,
                        to = Sys.Date(),
                        source = "yahoo",
                        interval = "daily",
                        auto_adjust = TRUE,
                        api_key = NULL,
                        ...) {
        
        # Validate inputs
        if (length(tickers) == 0) {
                stop("At least one ticker symbol must be provided")
        }
        
        # Convert dates
        from <- as.Date(from)
        to <- as.Date(to)
        
        if (from >= to) {
                stop("'from' date must be before 'to' date")
        }
        
        # Route to appropriate source
        data <- switch(
                tolower(source),
                "yahoo" = fetch_yahoo(tickers, from, to, auto_adjust, ...),
                "alpha_vantage" = fetch_alpha_vantage(tickers, api_key, interval, ...),
                "alphavantage" = fetch_alpha_vantage(tickers, api_key, interval, ...),
                stop("Unknown source: ", source, ". Supported: 'yahoo', 'alpha_vantage'")
        )
        
        # Validate output
        data <- validate_market_data(data)
        
        return(data)
}


#' Fetch Data from Yahoo Finance
#'
#' Fetch OHLCV data directly from Yahoo Finance. This is a free data source
#' that doesn't require an API key and supports stocks, ETFs, indices, crypto,
#' and futures.
#'
#' @param tickers Character vector: ticker symbols
#' @param from Date or character: start date
#' @param to Date or character: end date
#' @param auto_adjust Logical: adjust for splits/dividends (default: TRUE)
#' @param periodicity Character: "daily", "weekly", "monthly" (default: "daily")
#'
#' @return A `market_tbl` object
#' @export
#'
#' @examples
#' \dontrun{
#' # Fetch Apple stock
#' aapl <- fetch_yahoo("AAPL", from = "2024-01-01")
#' 
#' # Multiple stocks
#' tech <- fetch_yahoo(c("AAPL", "MSFT"), from = "2023-01-01")
#' 
#' # Bitcoin
#' btc <- fetch_yahoo("BTC-USD", from = "2024-01-01")
#' }
fetch_yahoo <- function(tickers,
                       from = Sys.Date() - 365,
                       to = Sys.Date(),
                       auto_adjust = TRUE,
                       periodicity = "daily") {
        
        # Check for quantmod package
        if (!requireNamespace("quantmod", quietly = TRUE)) {
                stop("Package 'quantmod' is required. Install with: install.packages('quantmod')")
        }
        
        # Convert dates
        from <- as.character(as.Date(from))
        to <- as.character(as.Date(to))
        
        # Fetch data for each ticker
        all_data <- list()
        
        for (ticker in tickers) {
                message("Fetching ", ticker, " from Yahoo Finance...")
                
                tryCatch({
                        # Fetch using quantmod
                        data_xts <- quantmod::getSymbols(
                                ticker,
                                src = "yahoo",
                                from = from,
                                to = to,
                                auto.assign = FALSE,
                                periodicity = periodicity
                        )
                        
                        # Convert to tibble
                        data_df <- tibble::tibble(
                                symbol = ticker,
                                datetime = as.POSIXct(zoo::index(data_xts)),
                                open = as.numeric(data_xts[, 1]),
                                high = as.numeric(data_xts[, 2]),
                                low = as.numeric(data_xts[, 3]),
                                close = as.numeric(data_xts[, 4]),
                                volume = as.numeric(data_xts[, 5]),
                                adjusted = if (ncol(data_xts) >= 6) as.numeric(data_xts[, 6]) else as.numeric(data_xts[, 4])
                        )
                        
                        # If not auto-adjusting, use close price
                        if (!auto_adjust) {
                                data_df$adjusted <- data_df$close
                        }
                        
                        all_data[[ticker]] <- data_df
                        
                }, error = function(e) {
                        warning("Failed to fetch ", ticker, ": ", e$message)
                })
        }
        
        if (length(all_data) == 0) {
                stop("Failed to fetch any data")
        }
        
        # Combine all data
        result <- dplyr::bind_rows(all_data)
        
        # Convert to market_tbl
        result <- structure(
                result,
                class = c("market_tbl", class(result)),
                frequency = periodicity,
                timezone = "America/New_York",
                asset_class = "equity",
                source = "yahoo"
        )
        
        return(result)
}


#' Fetch Data from Alpha Vantage API
#'
#' Fetch market data from Alpha Vantage. Requires a free API key from
#' https://www.alphavantage.co/support/#api-key
#'
#' @param tickers Character vector: ticker symbols
#' @param api_key Character: Alpha Vantage API key (or set ALPHA_VANTAGE_KEY env var)
#' @param interval Character: "daily", "weekly", "monthly", "1min", "5min", "15min", "30min", "60min"
#' @param outputsize Character: "compact" (100 data points) or "full" (20+ years)
#'
#' @return A `market_tbl` object
#' @export
#'
#' @examples
#' \dontrun{
#' # Set API key as environment variable
#' Sys.setenv(ALPHA_VANTAGE_KEY = "your_api_key_here")
#' 
#' # Fetch data
#' aapl <- fetch_alpha_vantage("AAPL")
#' 
#' # Intraday data
#' aapl_1min <- fetch_alpha_vantage("AAPL", interval = "1min")
#' }
fetch_alpha_vantage <- function(tickers,
                               api_key = Sys.getenv("ALPHA_VANTAGE_KEY"),
                               interval = "daily",
                               outputsize = "compact") {
        
        if (api_key == "") {
                stop("Alpha Vantage API key required. Set ALPHA_VANTAGE_KEY environment variable or pass api_key argument.")
        }
        
        # Check for required packages
        if (!requireNamespace("httr", quietly = TRUE)) {
                stop("Package 'httr' is required. Install with: install.packages('httr')")
        }
        if (!requireNamespace("jsonlite", quietly = TRUE)) {
                stop("Package 'jsonlite' is required. Install with: install.packages('jsonlite')")
        }
        
        # Determine function based on interval
        func <- if (interval == "daily") {
                "TIME_SERIES_DAILY"
        } else if (interval %in% c("weekly", "monthly")) {
                paste0("TIME_SERIES_", toupper(interval))
        } else {
                "TIME_SERIES_INTRADAY"
        }
        
        all_data <- list()
        
        for (ticker in tickers) {
                message("Fetching ", ticker, " from Alpha Vantage...")
                
                # Rate limiting (5 calls per minute on free tier)
                Sys.sleep(12)  # Wait 12 seconds between calls
                
                tryCatch({
                        # Build URL
                        url <- paste0(
                                "https://www.alphavantage.co/query?",
                                "function=", func,
                                "&symbol=", ticker,
                                "&apikey=", api_key,
                                "&outputsize=", outputsize
                        )
                        
                        if (func == "TIME_SERIES_INTRADAY") {
                                url <- paste0(url, "&interval=", interval)
                        }
                        
                        # Fetch data
                        response <- httr::GET(url)
                        content <- jsonlite::fromJSON(httr::content(response, "text"))
                        
                        # Extract time series data
                        ts_key <- names(content)[grep("Time Series", names(content))][1]
                        ts_data <- content[[ts_key]]
                        
                        if (is.null(ts_data)) {
                                stop("No data returned. Check ticker symbol and API key.")
                        }
                        
                        # Convert to tibble
                        data_df <- tibble::tibble(
                                symbol = ticker,
                                datetime = as.POSIXct(names(ts_data)),
                                open = as.numeric(sapply(ts_data, `[[`, "1. open")),
                                high = as.numeric(sapply(ts_data, `[[`, "2. high")),
                                low = as.numeric(sapply(ts_data, `[[`, "3. low")),
                                close = as.numeric(sapply(ts_data, `[[`, "4. close")),
                                volume = as.numeric(sapply(ts_data, `[[`, "5. volume")),
                                adjusted = as.numeric(sapply(ts_data, `[[`, "4. close"))
                        )
                        
                        # Sort by date
                        data_df <- dplyr::arrange(data_df, datetime)
                        
                        all_data[[ticker]] <- data_df
                        
                }, error = function(e) {
                        warning("Failed to fetch ", ticker, ": ", e$message)
                })
        }
        
        if (length(all_data) == 0) {
                stop("Failed to fetch any data")
        }
        
        # Combine all data
        result <- dplyr::bind_rows(all_data)
        
        # Convert to market_tbl
        result <- structure(
                result,
                class = c("market_tbl", class(result)),
                frequency = interval,
                timezone = "America/New_York",
                asset_class = "equity",
                source = "alpha_vantage"
        )
        
        return(result)
}


#' Load Market Data from CSV File
#'
#' Load OHLCV data from a CSV file and convert to `market_tbl` format.
#'
#' @param file_path Character: path to CSV file
#' @param symbol_column Character: name of symbol column (default: "symbol")
#' @param date_column Character: name of date/datetime column (default: "date")
#' @param symbol Character: if CSV doesn't have symbol column, specify symbol here
#' @param ... Additional arguments passed to readr::read_csv()
#'
#' @return A `market_tbl` object
#' @export
#'
#' @examples
#' \dontrun{
#' # Load from CSV
#' data <- fetch_csv("my_data.csv")
#' 
#' # Specify column names
#' data <- fetch_csv(
#'   "my_data.csv",
#'   symbol_column = "ticker",
#'   date_column = "datetime"
#' )
#' 
#' # Single symbol file without symbol column
#' data <- fetch_csv("aapl.csv", symbol = "AAPL")
#' }
fetch_csv <- function(file_path,
                     symbol_column = "symbol",
                     date_column = "date",
                     symbol = NULL,
                     ...) {
        
        if (!requireNamespace("readr", quietly = TRUE)) {
                stop("Package 'readr' is required. Install with: install.packages('readr')")
        }
        
        # Read CSV
        data <- readr::read_csv(file_path, ...)
        
        # Check required columns
        required_cols <- c("open", "high", "low", "close", "volume")
        missing_cols <- setdiff(required_cols, tolower(names(data)))
        
        if (length(missing_cols) > 0) {
                stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
        }
        
        # Standardize column names
        names(data) <- tolower(names(data))
        
        # Handle symbol column
        if (symbol_column %in% names(data)) {
                data <- dplyr::rename(data, symbol = !!symbol_column)
        } else if (!is.null(symbol)) {
                data$symbol <- symbol
        } else {
                stop("No symbol column found and no symbol provided")
        }
        
        # Handle date column
        if (date_column %in% names(data)) {
                data <- dplyr::rename(data, datetime = !!date_column)
        } else {
                stop("Date column '", date_column, "' not found")
        }
        
        # Convert datetime
        data$datetime <- as.POSIXct(data$datetime)
        
        # Add adjusted column if missing
        if (!"adjusted" %in% names(data)) {
                data$adjusted <- data$close
        }
        
        # Select and order columns
        data <- dplyr::select(data, symbol, datetime, open, high, low, close, volume, adjusted)
        
        # Convert to market_tbl
        result <- structure(
                data,
                class = c("market_tbl", class(data)),
                frequency = "daily",
                timezone = "UTC",
                asset_class = "equity",
                source = "csv"
        )
        
        return(result)
}
