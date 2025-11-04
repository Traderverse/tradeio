# S3 Methods for market_tbl class to preserve through dplyr operations

#' Subset market_tbl
#' @param x A market_tbl object
#' @param i Row indices
#' @param j Column indices  
#' @param drop Logical, drop dimensions
#' @export
`[.market_tbl` <- function(x, i, j, drop = FALSE) {
        result <- NextMethod()
        class(result) <- class(x)
        result
}

#' Extract column from market_tbl
#' @param x A market_tbl object
#' @param i Column index or name
#' @param exact Logical, exact matching
#' @export
`[[.market_tbl` <- function(x, i, exact = TRUE) {
        NextMethod()
}

#' Extract column from market_tbl using $
#' @param x A market_tbl object
#' @param name Column name
#' @export
`$.market_tbl` <- function(x, name) {
        NextMethod()
}

#' Reconstruct market_tbl after dplyr operations
#' @param data Result of dplyr operation
#' @param template Original market_tbl template
#' @export
dplyr_reconstruct.market_tbl <- function(data, template) {
        # Ensure market_tbl class is preserved
        if (!"market_tbl" %in% class(data)) {
                class(data) <- c("market_tbl", class(data))
        }
        # Preserve key attributes
        attr(data, "frequency") <- attr(template, "frequency")
        attr(data, "timezone") <- attr(template, "timezone")
        attr(data, "asset_class") <- attr(template, "asset_class")
        attr(data, "source") <- attr(template, "source")
        data
}
