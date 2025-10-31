library(testthat)
library(tradeio)

test_that("validate_market_data detects missing columns", {
        data <- tibble::tibble(symbol = "TEST", datetime = Sys.time())
        
        expect_error(
                validate_market_data(data, strict = TRUE),
                "Missing columns"
        )
})

test_that("validate_market_data detects OHLC violations", {
        data <- tibble::tibble(
                symbol = "TEST",
                datetime = as.POSIXct("2024-01-01"),
                open = 100,
                high = 95,  # High less than open - violation!
                low = 99,
                close = 102,
                volume = 1000
        )
        
        expect_error(
                validate_market_data(data, strict = TRUE),
                "High price violations"
        )
})

test_that("fill_missing_data works with forward fill", {
        data <- tibble::tibble(
                symbol = "TEST",
                datetime = as.POSIXct(c("2024-01-01", "2024-01-02", "2024-01-03")),
                open = c(100, NA, 102),
                high = c(105, NA, 107),
                low = c(99, NA, 101),
                close = c(103, NA, 105),
                volume = c(1e6, NA, 1.1e6),
                adjusted = c(103, NA, 105)
        )
        
        filled <- fill_missing_data(data, method = "forward")
        
        expect_false(any(is.na(filled$open)))
        expect_equal(filled$open[2], 100)  # Should be filled with previous value
})

test_that("set_timezone converts correctly", {
        data <- tibble::tibble(
                symbol = "TEST",
                datetime = as.POSIXct("2024-01-01 12:00:00", tz = "UTC"),
                open = 100, high = 105, low = 99, close = 102,
                volume = 1e6, adjusted = 102
        )
        
        data_ny <- set_timezone(data, "America/New_York")
        
        expect_equal(attr(data_ny$datetime, "tzone"), "America/New_York")
        expect_equal(attr(data_ny, "timezone"), "America/New_York")
})

test_that("adjust_for_splits adjusts prices correctly", {
        data <- tibble::tibble(
                symbol = "TEST",
                datetime = as.POSIXct(c("2024-01-01", "2024-06-01", "2024-12-01")),
                open = c(100, 100, 100),
                high = c(105, 105, 105),
                low = c(99, 99, 99),
                close = c(102, 102, 102),
                volume = c(1e6, 1e6, 1e6),
                adjusted = c(102, 102, 102)
        )
        
        # 2-for-1 split on 2024-06-01
        adjusted <- adjust_for_splits(data, split_ratio = 2, split_date = "2024-06-01")
        
        # Prices before split should be halved
        expect_equal(adjusted$close[1], 51)
        # Prices on/after split should be unchanged
        expect_equal(adjusted$close[2], 102)
        expect_equal(adjusted$close[3], 102)
})
