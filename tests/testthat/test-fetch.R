library(testthat)
library(tradeio)

test_that("fetch_prices validates inputs correctly", {
        expect_error(
                fetch_prices(character(0)),
                "At least one ticker symbol must be provided"
        )
        
        expect_error(
                fetch_prices("AAPL", from = "2024-12-31", to = "2024-01-01"),
                "'from' date must be before 'to' date"
        )
        
        expect_error(
                fetch_prices("AAPL", source = "invalid_source"),
                "Unknown source"
        )
})

test_that("normalize_tickers works correctly", {
        tickers <- c("AAPL", "MSFT", "GOOGL")
        expect_equal(normalize_tickers(tickers, "yahoo"), tickers)
        
        expect_equal(normalize_tickers("BTC-USD", "alpha_vantage"), "BTC")
})

test_that("is_market_tbl identifies market_tbl objects", {
        # Create a valid market_tbl
        data <- structure(
                tibble::tibble(
                        symbol = "TEST",
                        datetime = as.POSIXct("2024-01-01"),
                        open = 100,
                        high = 105,
                        low = 99,
                        close = 102,
                        volume = 1000000,
                        adjusted = 102
                ),
                class = c("market_tbl", "tbl_df", "tbl", "data.frame")
        )
        
        expect_true(is_market_tbl(data))
        
        # Test with invalid data
        expect_false(is_market_tbl(data.frame(x = 1)))
        expect_false(is_market_tbl("not a data frame"))
})
