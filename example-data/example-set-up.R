# Example of building template files and database ---
suppressPackageStartupMessages({
  library(here)
})

# Source accessory scripts
source(here('scripts', 'exportEmptySampleSheet.R'))
source(here('scripts', 'buildDatabase.R'))

# Export template
exportEmptySampleSheet(
  path = here('example-data')
)

# Populate template with your own data
#   - Renamed to starting-samples.csv

# Build database
buildDatabase(
  path_samplesheet = here('example-data', 'starting-samples.csv'),
  path_col_spec_rds = here('example-data', 'template-sample-sheet-column-specification.rds'),
  path_db_location = here('example-data', 'DB-directory'), 
  str_db_name = 'DB-example',
  force_overwrite = TRUE
)
