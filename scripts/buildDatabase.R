# Build database ---
#
# Before running the app., this step will be used to build a database file
# from the samplesheet.

buildDatabase <- function(
  path_samplesheet,
  path_col_spec_rds,
  path_db_location,
  str_db_name,
  force_overwrite = FALSE
) {
  
  # Where the sql databse will be created - add correct suffix
  path_db_file <- here::here(path_db_location, paste0(str_db_name, '.sqlite'))
  
  if(fs::file_exists(path = path_db_file)) {
    if(force_overwrite) {
      warning(
        glue::glue(
          'Over-writing {path_db_file}'
        )
      )
      fs::file_delete(path = path_db_file)
    } else {
      stop(
        glue::glue(
          'Database file exists: {path_db_file}',
          "Use 'force_overwrite=TRUE' to overwrite the existing database file",
          .sep = '\n'
        )
      )
    }
  }
  
  # Create the output directory
  fs::dir_create(
    path = path_db_location,
    recurse = TRUE
  )
  
  # Column specification
  col_spec <- readr::read_rds(path_col_spec_rds)
  
  # Read in database file - first sheet
  db_dataframe <- readr::read_csv(
    file = path_samplesheet, 
    col_names = TRUE,
    col_types = col_spec
  )
  
  # Create the database + add mandatory sample information
  db_con <- DBI::dbConnect(RSQLite::SQLite(), path_db_file)
  dplyr::copy_to(
    db_con,
    db_dataframe,
    'mandatory_information',
    temporary = FALSE
  )

  sample_information_db <- dplyr::tbl(
    db_con, 'mandatory_information'
  )

  DBI::dbDisconnect(conn = db_con)
}
