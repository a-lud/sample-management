# Generate template for sample upload ---
#   - Get the column names from the col_types object
#   - When the user uploads some new data, check the types against the col_types

buildSampleTemplate <- function(file, rds_coltypes) {
  col_spec <- readr::read_rds(rds_coltypes)
  
  write(
    x = paste(names(col_spec$cols), collapse = ','),
    file = file
  )
}
