# 🚀 Quick Start Guide: tradeio

This guide will get you up and running with `tradeio` in 5 minutes.

## Installation

```r
# Install from GitHub
devtools::install_github("tradingverse/tradeio")

# Load the package
library(tradeio)
```

## Basic Usage

### 1. Fetch Stock Prices

```r
# Fetch Apple stock data
aapl <- fetch_prices("AAPL", from = "2024-01-01")

# View the data
head(aapl)
```

Output:
```
# A tibble: 6 × 8
  symbol datetime              open  high   low close   volume adjusted
  <chr>  <dttm>               <dbl> <dbl> <dbl> <dbl>    <dbl>    <dbl>
1 AAPL   2024-01-02 09:30:00   184.  186.  183.  185. 70134200     185.
2 AAPL   2024-01-03 09:30:00   185.  186.  183.  184. 58216400     184.
3 AAPL   2024-01-04 09:30:00   183.  184.  181.  181. 64512300     181.
...
```

### 2. Multiple Stocks

```r
# Fetch multiple stocks at once
tech_stocks <- fetch_prices(
  c("AAPL", "MSFT", "GOOGL"),
  from = "2024-01-01"
)

# Group by symbol
library(dplyr)
tech_stocks |>
  group_by(symbol) |>
  summarise(avg_price = mean(close))
```

### 3. Cryptocurrency

```r
# Bitcoin and Ethereum
crypto <- fetch_prices(
  c("BTC-USD", "ETH-USD"),
  from = "2024-01-01"
)
```

### 4. Handle Missing Data

```r
# Fill missing values
data <- fetch_prices("AAPL", from = "2024-01-01")
data_filled <- fill_missing_data(data, method = "forward")
```

### 5. Integration with tradeengine

```r
library(tradeio)
library(tradeengine)

# Complete workflow
results <- fetch_prices("AAPL", from = "2023-01-01") |>
  mutate(sma_20 = sma(close, 20)) |>
  add_strategy(
    entry = close > sma_20,
    exit = close < sma_20
  ) |>
  backtest(initial_capital = 10000)

print(results$summary)
```

## Common Patterns

### Pattern 1: Daily Price Updates

```r
# Fetch latest prices
today_prices <- fetch_prices(
  c("AAPL", "MSFT", "TSLA"),
  from = Sys.Date() - 1
)
```

### Pattern 2: Historical Analysis

```r
# Get 5 years of data
historical <- fetch_prices(
  "AAPL",
  from = Sys.Date() - 365*5
)
```

### Pattern 3: Multi-Asset Portfolio

```r
# Diverse portfolio
portfolio <- fetch_prices(
  c("AAPL", "GLD", "TLT", "BTC-USD"),
  from = "2023-01-01"
)
```

## Data Sources

### Yahoo Finance (Default)
- Free, no API key required
- Coverage: Stocks, ETFs, indices, crypto, futures
- Most common choice

```r
prices <- fetch_yahoo("AAPL", from = "2024-01-01")
```

### Alpha Vantage
- Requires free API key: https://www.alphavantage.co/support/#api-key
- Real-time data, technical indicators

```r
# Set API key
Sys.setenv(ALPHA_VANTAGE_KEY = "your_key_here")

# Fetch data
prices <- fetch_alpha_vantage("AAPL")
```

### CSV Files
- Load custom data

```r
prices <- fetch_csv("my_data.csv")
```

## Next Steps

1. Read the full documentation: `?tradeio`
2. Run examples: `source(system.file("examples/basic_usage.R", package = "tradeio"))`
3. Check out vignettes: `vignette("getting-started", package = "tradeio")`
4. Explore tradeengine for backtesting: `library(tradeengine)`

## Getting Help

- GitHub Issues: https://github.com/Traderverse/tradeio/issues
- Documentation: https://tradingverse.github.io/tradeio
- Examples: See `examples/` directory

## Common Issues

### Issue: "quantmod package required"
**Solution**: `install.packages("quantmod")`

### Issue: "API rate limit exceeded"
**Solution**: Wait a few minutes or use a different data source

### Issue: "No data returned"
**Solution**: Check ticker symbol spelling and date range

---

Happy trading! 🚀
