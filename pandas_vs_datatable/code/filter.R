##
##                           FILTER
##

library(data.table)
library(microbenchmark)
library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)

# Functions
source("code/functions.R")

scenarios <- jsonlite::read_json("output/filter.JSON")

n_cols <- names(scenarios)
n_rows <- gsub(".*_(.*).csv$", "\\1", list.files("data")) %>% unique()

filter_cols <- list(1, 2, 3, 4, 1:2, 1:3, 1:4)
filter_funs <- list(filter_1o2, filter_1o2, filter_3o4, filter_3o4,
										filter_1a2, filter_1a2a3, filter_1a2a3a4)

res_list <- list()
i_glob   <- 1

# Colums of data
for (n_col in n_cols) {

  # Rows of data
  for (n_row in n_rows) {

    cat("=== Data with ", n_col, " columns and ", n_row, " rows ===\n")

    cat("File load ... \n")
    filep <- sprintf("data/sim_data_%s_%s.csv", n_col, n_row)
    dt    <- fread(filep)

    # Scenarios
    for (i in seq(filter_cols)) {

      cat("Scenario: ", i, "\n")

      filter     <- scenarios[[n_col]][filter_cols[[i]]] %>% unlist()
      filter_fun <- filter_funs[[i]]

      # Get system time in milliseconds
      mb <- microbenchmark(filter_fun(), times = 100L)
      median_time <- median(mb$time / 1e6) # milliseconds
      mean_time   <- mean(mb$time / 1e6)
      min_time    <- min(mb$time / 1e6)
      max_time    <- max(mb$time / 1e6)

      # Save result
      res_list[[i_glob]] <- list(
        n_col = n_col,
        n_row = n_row,
        scenario = i,
        min_time = min_time,
        mean_time_ms = mean_time,
        median_time_ms = median_time,
        max_time = max_time
      )
      i_glob <- i_glob + 1
    }
  }
}

result <- res_list %>% dplyr::bind_rows()
saveRDS(result, "output/filter_results.RDS")
fwrite(result, file = "output/filter_results.csv")

# Plot results
# library(ggplot2)
# result %>%
#   ggplot(aes(x = as.factor(as.numeric(n_row)), y = as.factor(as.numeric(n_col)), fill = median_time_ms)) +
#     geom_tile() +
#     geom_text(aes(label = round(median_time_ms, 1)), col = "white") +
#     labs(x = "# Rows", y = "# Columns") +
#     facet_wrap( ~ scenario) +
#     scale_fill_continuous("Median\nfiltertime\n(milliseconds)") +
#     ggtitle("Data.table median filter time", subtitle = "For 7 scenarios (100 runs each")
#
# # Save
# ggsave("output/filter_results_datatable.pdf")
