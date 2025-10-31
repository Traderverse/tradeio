# tradeio 📥

> **Data Acquisition and Normalization for TradingVerse**

`tradeio` is the data ingestion layer of the TradingVerse ecosystem. It provides a unified, pipe-friendly interface for fetching financial market data from multiple sources and automatically converts it into the standardized `market_tbl` format.

## ✨ Features

- 🌐 **Multi-Source Support**: Yahoo Finance, Alpha Vantage, FRED, CSV files
- 🔄 **Automatic Normalization**: All data converted to consistent `market_tbl` format
- 🕐 **Timezone Management**: Proper handling of market timezones
- 📊 **Corporate Actions**: Automatic adjustment for splits and dividends
- 🔍 **Missing Data Handling**: Forward-fill, backward-fill, or interpolation
- ✅ **Data Validation**: Ensures OHLC consistency and data quality
- 🚀 **Tidy-Friendly**: Works seamlessly with dplyr pipes

## 📦 Installation

```r
# Install from GitHub
devtools::install_github("tradingverse/tradeio")

# Or install entire TradingVerse
devtools::install_github("tradingverse/tradingverse")
```

## 🚀 Quick Start

```r
library(tradeio)
library(dplyr)

# Fetch stock prices from Yahoo Finance
aapl <- fetch_prices("AAPL", from = "2024-01-01", to = "2024-12-31")

# Multiple stocks at once
tech_stocks <- fetch_prices(
  c("AAPL", "MSFT", "GOOGL", "NVDA"),
  from = "2024-01-01"
)

# Works with pipes
prices <- c("AAPL", "TSLA") |>
  fetch_prices(from = "2023-01-01") |>
  fill_missing_data(method = "forward") |>
  adjust_for_splits()
```

## 🎯 Core Functions

### Data Fetching

```r
# Universal fetch function (auto-detects source)
fetch_prices(tickers, from, to, source = "yahoo")

# Source-specific functions
fetch_yahoo(tickers, from, to, auto_adjust = TRUE)
fetch_alpha_vantage(tickers, api_key, interval = "daily")
fetch_csv(file_path, symbol_column = "symbol")
```

### Data Normalization

```r
# Handle missing data
fill_missing_data(data, method = "forward")  # or "backward", "linear", "spline"

# Adjust for corporate actions
adjust_for_splits(data)
adjust_for_dividends(data)

# Timezone conversion
set_timezone(data, tz = "America/New_York")

# Validate data quality
validate_market_data(data)
```

### Ticker Utilities

```r
# Standardize ticker symbols across sources
normalize_tickers(c("AAPL", "MSFT", "BTC-USD"))
```

## 📊 Output Format

All functions return data in the standardized `market_tbl` format:

```r
# A tibble: 252 × 8
   symbol datetime            open  high   low close  volume adjusted
   <chr>  <dttm>             <dbl> <dbl> <dbl> <dbl>   <dbl>    <dbl>
 1 AAPL   2024-01-02 09:30   184.  186.  183.  185.  7.01e7    185.
 2 AAPL   2024-01-03 09:30   185.  186.  183.  184.  5.82e7    184.
 3 AAPL   2024-01-04 09:30   183.  184.  181.  181.  6.45e7    181.
```

### Attributes

```r
attr(data, "frequency")    # "daily", "1hour", "1min", etc.
attr(data, "timezone")     # "America/New_York", "UTC", etc.
attr(data, "asset_class")  # "equity", "crypto", "futures", "fx"
attr(data, "source")       # "yahoo", "alpha_vantage", etc.
```

## 🔗 Integration with TradingVerse

`tradeio` is designed to work seamlessly with other TradingVerse packages:

```r
library(tradeio)
library(tradefeatures)
library(tradeengine)

# Complete workflow
strategy_results <- 
  # 1. Fetch data
  fetch_prices("AAPL", from = "2023-01-01") |>
  
  # 2. Add features (tradefeatures)
  add_sma(20) |>
  add_rsi(14) |>
  
  # 3. Backtest (tradeengine)
  add_strategy(
    entry = rsi < 30,
    exit = rsi > 70
  ) |>
  backtest(initial_capital = 10000)
```

## 🌐 Supported Data Sources

### Yahoo Finance (Default)
- **Free**: No API key required
- **Coverage**: Stocks, ETFs, indices, crypto, futures
- **History**: Up to 50+ years for major stocks
- **Limitations**: Rate limited, occasional data gaps

```r
prices <- fetch_yahoo("AAPL", from = "2020-01-01")
```

### Alpha Vantage
- **API Key**: Required (free tier available)
- **Coverage**: Stocks, forex, crypto, economic indicators
- **Features**: Real-time data, technical indicators
- **Limitations**: 5 calls/minute on free tier

```r
prices <- fetch_alpha_vantage(
  "AAPL",
  api_key = Sys.getenv("ALPHA_VANTAGE_KEY"),
  interval = "daily"
)
```

### CSV Files
- **Format**: Custom CSV or standard OHLCV format
- **Use Case**: Proprietary data, offline backtesting

```r
prices <- fetch_csv(
  "data/custom_prices.csv",
  symbol_column = "ticker",
  date_column = "date"
)
```

## 🛠️ Advanced Features

### Multi-Asset Fetching

```r
# Fetch multiple assets across different classes
portfolio <- fetch_prices(
  c("AAPL", "MSFT", "BTC-USD", "GC=F", "EURUSD=X"),
  from = "2024-01-01"
)
```

### Custom Data Sources

You can extend tradeio with custom data sources:

```r
# Register custom data source
register_data_source(
  name = "custom_api",
  fetch_fn = function(ticker, from, to) {
    # Your custom fetching logic
    # Must return market_tbl format
  }
)

# Use it
prices <- fetch_prices("TICKER", source = "custom_api")
```

### Caching

```r
# Enable caching to avoid repeated API calls
options(tradeio.cache = TRUE)
options(tradeio.cache_dir = "~/.tradeio_cache")

# Cached data will be reused
prices <- fetch_prices("AAPL", from = "2020-01-01")
```

## 📈 Examples

### Example 1: Compare Tech Stocks

```r
library(tradeio)
library(dplyr)
library(ggplot2)

tech_stocks <- fetch_prices(
  c("AAPL", "MSFT", "GOOGL", "AMZN", "META"),
  from = "2024-01-01"
)

# Calculate returns
tech_returns <- tech_stocks |>
  group_by(symbol) |>
  mutate(return = (close / first(close) - 1) * 100)

# Plot
ggplot(tech_returns, aes(x = datetime, y = return, color = symbol)) +
  geom_line() +
  labs(title = "Tech Stock Returns 2024", y = "Return (%)")
```

### Example 2: Crypto Data

```r
# Fetch Bitcoin and Ethereum
crypto <- fetch_prices(
  c("BTC-USD", "ETH-USD"),
  from = "2023-01-01"
)

# Calculate correlation
crypto |>
  select(symbol, datetime, close) |>
  pivot_wider(names_from = symbol, values_from = close) |>
  select(-datetime) |>
  cor(use = "complete.obs")
```

### Example 3: Handle Missing Data

```r
# Fetch data with potential gaps
prices <- fetch_prices("THINLY_TRADED_STOCK", from = "2024-01-01")

# Fill gaps using different methods
prices_ffill <- fill_missing_data(prices, method = "forward")
prices_linear <- fill_missing_data(prices, method = "linear")
prices_spline <- fill_missing_data(prices, method = "spline")
```

## 🧪 Testing

```r
# Run package tests
devtools::test()

# Run specific test
testthat::test_file("tests/testthat/test-fetch.R")
```

## 📚 Documentation

```r
# Package overview
?tradeio

# Function help
?fetch_prices
?fill_missing_data

# Vignettes
vignette("getting-started", package = "tradeio")
vignette("data-sources", package = "tradeio")
vignette("custom-sources", package = "tradeio")
```

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🔗 Links

- **GitHub**: https://github.com/Traderverse/tradeio
- **Documentation**: https://tradingverse.github.io/tradeio
- **TradingVerse**: https://github.com/Traderverse

## 🙏 Acknowledgments

- Built on top of `quantmod`, `tidyquant`, and other excellent R packages
- Inspired by Python's `yfinance` and `pandas_datareader`
- Part of the TradingVerse ecosystem

---

**Status**: 🚧 Active Development (v0.1.0)  
**Next Release**: Q1 2025
