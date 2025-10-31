# =============================================================================
# tradeio Examples: Data Acquisition for TradingVerse
# =============================================================================

library(tradeio)
library(dplyr)

# =============================================================================
# Example 1: Fetch Single Stock from Yahoo Finance
# =============================================================================

cat("\n=== Example 1: Fetch Single Stock ===\n")

# Fetch Apple stock data for 2024
aapl <- fetch_prices("AAPL", from = "2024-01-01", to = "2024-12-31")

print(head(aapl))
print(paste("Total rows:", nrow(aapl)))
print(paste("Date range:", min(aapl$datetime), "to", max(aapl$datetime)))

# =============================================================================
# Example 2: Fetch Multiple Stocks
# =============================================================================

cat("\n=== Example 2: Fetch Multiple Stocks ===\n")

# Fetch FAANG stocks
tech_stocks <- fetch_prices(
        c("AAPL", "MSFT", "GOOGL", "AMZN", "META"),
        from = "2024-01-01"
)

# Summary by symbol
tech_stocks |>
        group_by(symbol) |>
        summarise(
                n_days = n(),
                avg_volume = mean(volume),
                price_change = (last(close) / first(close) - 1) * 100
        ) |>
        print()

# =============================================================================
# Example 3: Fetch Cryptocurrency Data
# =============================================================================

cat("\n=== Example 3: Fetch Cryptocurrency ===\n")

# Bitcoin and Ethereum
crypto <- fetch_prices(
        c("BTC-USD", "ETH-USD"),
        from = "2024-01-01"
)

print(head(crypto))

# Calculate daily returns
crypto_returns <- crypto |>
        group_by(symbol) |>
        mutate(
                daily_return = (close / lag(close) - 1) * 100
        ) |>
        ungroup()

# Average returns by crypto
crypto_returns |>
        group_by(symbol) |>
        summarise(
                avg_return = mean(daily_return, na.rm = TRUE),
                volatility = sd(daily_return, na.rm = TRUE)
        ) |>
        print()

# =============================================================================
# Example 4: Handle Missing Data
# =============================================================================

cat("\n=== Example 4: Handle Missing Data ===\n")

# Fetch data (may have gaps)
data <- fetch_prices("AAPL", from = "2024-01-01", to = "2024-03-31")

# Check for missing values
cat("Missing values before filling:\n")
print(colSums(is.na(data)))

# Fill using different methods
data_ffill <- fill_missing_data(data, method = "forward")
data_linear <- fill_missing_data(data, method = "linear")

cat("\nMissing values after forward fill:\n")
print(colSums(is.na(data_ffill)))

# =============================================================================
# Example 5: Timezone Conversion
# =============================================================================

cat("\n=== Example 5: Timezone Conversion ===\n")

# Fetch data (default timezone)
data <- fetch_prices("AAPL", from = "2024-01-01", to = "2024-01-05")

cat("Original timezone:", attr(data, "timezone"), "\n")
print(head(data$datetime))

# Convert to different timezones
data_utc <- set_timezone(data, "UTC")
data_tokyo <- set_timezone(data, "Asia/Tokyo")
data_london <- set_timezone(data, "Europe/London")

cat("\nUTC:\n")
print(head(data_utc$datetime))

cat("\nTokyo:\n")
print(head(data_tokyo$datetime))

# =============================================================================
# Example 6: Integration with tradeengine
# =============================================================================

cat("\n=== Example 6: Integration with tradeengine ===\n")

if (requireNamespace("tradeengine", quietly = TRUE)) {
        library(tradeengine)
        
        # Fetch data
        data <- fetch_prices("AAPL", from = "2023-01-01", to = "2024-01-01")
        
        # Add simple moving average
        data <- data |>
                mutate(sma_20 = tradeengine::sma(close, 20))
        
        # Define strategy
        strategy_data <- data |>
                add_strategy(
                        entry = close > sma_20,
                        exit = close < sma_20
                )
        
        # Backtest
        results <- backtest(strategy_data, initial_capital = 10000)
        
        cat("\nBacktest Results:\n")
        print(results$summary)
        
} else {
        cat("Install tradeengine to run this example:\n")
        cat("devtools::install_github('tradingverse/tradeengine')\n")
}

# =============================================================================
# Example 7: Load from CSV
# =============================================================================

cat("\n=== Example 7: Load from CSV ===\n")

# Create sample CSV file
sample_data <- tibble::tibble(
        symbol = "DEMO",
        date = seq.Date(as.Date("2024-01-01"), by = "day", length.out = 10),
        open = 100 + rnorm(10, 0, 2),
        high = 100 + rnorm(10, 2, 2),
        low = 100 + rnorm(10, -2, 2),
        close = 100 + rnorm(10, 0, 2),
        volume = rpois(10, 1000000)
)

# Save to CSV
temp_file <- tempfile(fileext = ".csv")
readr::write_csv(sample_data, temp_file)

# Load from CSV
data_from_csv <- fetch_csv(
        temp_file,
        symbol_column = "symbol",
        date_column = "date"
)

print(head(data_from_csv))

# Clean up
unlink(temp_file)

# =============================================================================
# Example 8: Data Validation
# =============================================================================

cat("\n=== Example 8: Data Validation ===\n")

# Create valid data
valid_data <- tibble::tibble(
        symbol = "TEST",
        datetime = as.POSIXct(seq.Date(as.Date("2024-01-01"), by = "day", length.out = 5)),
        open = c(100, 101, 102, 103, 104),
        high = c(105, 106, 107, 108, 109),
        low = c(99, 100, 101, 102, 103),
        close = c(102, 103, 104, 105, 106),
        volume = c(1e6, 1.1e6, 1.2e6, 1.3e6, 1.4e6)
)

# Validate
tryCatch({
        validate_market_data(valid_data, strict = TRUE)
        cat("✓ Data validation passed\n")
}, error = function(e) {
        cat("✗ Validation failed:", e$message, "\n")
})

# Create invalid data (high < open)
invalid_data <- valid_data
invalid_data$high[1] <- 90  # High lower than open

tryCatch({
        validate_market_data(invalid_data, strict = TRUE)
        cat("✓ Data validation passed\n")
}, error = function(e) {
        cat("✗ Validation failed:", e$message, "\n")
})

# =============================================================================
# Example 9: Calculate Price Statistics
# =============================================================================

cat("\n=== Example 9: Price Statistics ===\n")

# Fetch data
data <- fetch_prices("AAPL", from = "2024-01-01")

# Calculate various statistics
stats <- data |>
        summarise(
                n_days = n(),
                start_price = first(close),
                end_price = last(close),
                min_price = min(low),
                max_price = max(high),
                avg_price = mean(close),
                total_volume = sum(volume),
                avg_daily_volume = mean(volume),
                price_return = (last(close) / first(close) - 1) * 100,
                volatility = sd(close) / mean(close) * 100
        )

print(stats)

# =============================================================================
# Example 10: Compare Multiple Assets
# =============================================================================

cat("\n=== Example 10: Compare Multiple Assets ===\n")

# Fetch diverse assets
assets <- fetch_prices(
        c("AAPL", "GLD", "TLT", "BTC-USD"),  # Stock, Gold, Bonds, Crypto
        from = "2024-01-01"
)

# Normalize prices to start at 100
normalized <- assets |>
        group_by(symbol) |>
        mutate(
                normalized_price = (close / first(close)) * 100
        ) |>
        ungroup()

# Compare performance
performance <- normalized |>
        group_by(symbol) |>
        summarise(
                start_date = min(datetime),
                end_date = max(datetime),
                return_pct = last(normalized_price) - 100,
                volatility = sd(normalized_price)
        ) |>
        arrange(desc(return_pct))

print(performance)

cat("\n=== All examples completed! ===\n")
