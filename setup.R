# Setup script for tradeio package development
# Run this script to set up your development environment

# Install required packages
required_packages <- c(
        "devtools",
        "roxygen2",
        "testthat",
        "tibble",
        "dplyr",
        "lubridate",
        "httr",
        "jsonlite",
        "readr",
        "quantmod",
        "zoo",
        "rlang"
)

cat("Installing required packages...\n")

for (pkg in required_packages) {
        if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
                cat("Installing", pkg, "...\n")
                install.packages(pkg)
        }
}

cat("\n✓ All required packages installed\n")

# Load development tools
library(devtools)
library(roxygen2)

# Document the package
cat("\nGenerating documentation...\n")
document()

# Run tests
cat("\nRunning tests...\n")
test()

# Check package
cat("\nChecking package...\n")
check()

cat("\n✓ tradeio development environment ready!\n")
cat("\nNext steps:\n")
cat("  1. Load package: devtools::load_all()\n")
cat("  2. Run examples: source('examples/basic_usage.R')\n")
cat("  3. Run tests: devtools::test()\n")
cat("  4. Build package: devtools::build()\n")
