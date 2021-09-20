# Create template sample sheet ---
#
# Generate a default template sample sheet for use with the app.
# Users can change the columns to whatever they please. The 'col_spec'
# object is equally important for generating the database as it specifies
# the column types. This will be especially important for dates.

exportEmptySampleSheet <- function(path, filename = 'template-sample-sheet') {
  template <- tibble::tibble(
    # 'sample_id' --> user defined
    'sample_id' = character(),
    
    # 'speciment_id*' --> Formal identifier + what institution
    'specimen_id' = character(),
    'specimen_id_description' = character(),
    
    # Sample information
    'family' = character(),
    'genus' = character(),
    'species' = character(),
    'common_name' = character(),
    
    # General information
    'collection_date' = character(),
    'collector' = character(),
    'life_stage' = character(),
    'sex' = character(),
    
    # Locational information
    'country' = character(),
    'state_region' = character(),
    'location_text' = character(),
    'decimal_latitude' = double(),
    'decimal_longitude' = double(),
  )
  
  # Column specification
  col_spec <- readr::cols(
    'sample_id' = readr::col_character(),
    'specimen_id' = readr::col_character(),
    'specimen_id_description' = readr::col_character(),
    'family' = readr::col_character(),
    'genus' = readr::col_character(),
    'species' = readr::col_character(),
    'common_name' = readr::col_character(),
    'collection_date' = readr::col_character(),
    'collector' = readr::col_character(),
    'life_stage' = readr::col_character(),
    'sex' = readr::col_character(),
    'country' = readr::col_character(),
    'state_region' = readr::col_character(),
    'location_text' = readr::col_character(),
    'decimal_latitude' = readr::col_double(),
    'decimal_longitude' = readr::col_double(),
  )
  
  # Column descriptions
  template_descriptions <- tibble::tibble(
    Column = c(
      'sample_id', 'specimen_id', 'specimen_id_description',
      'family', 'genus', 'species', 'common_name', 'collection_date',
      'collector', 'life_stage', 'sex', 'country', 'state_region',
      'location_text', 'decimal_latitude', 'decimal_longitude'
    ),
    Description = c(
      'User defined alpha-numeric string (character)', 
      'Formal voucher identifier from a recognised collection e.g. museum (character)',
      "Name of the institution responsible for the 'speciment_id'",
      'Full scientific name of the family which the taxon is classified (character)',
      'Full scientific name of the genus which the taxon is classified (character)',
      'Full scientific name of the species which the taxon is classified (character)',
      'Common name of the species', "Collection date in the format 'dd/mm/yyyy' (date)",
      'Names of people/organisations who collected the sample separated by commas (character)',
      'Age or life-stage of the sample (character)', 'Sex of the sample (character)',
      'Country the sample was collected in (character)',
      'State or region within the country the sample was collected in (character)',
      'Specific description of the sampling location e.g. address, property etc. (character)',
      'The geographic latitude in decimal degrees of the sampling location (double)',
      'The geographic longitude in decimal degrees of the sampling location (double)'
    ),
    Example = c(
      'SMPL0001', 'WAM123456', 'Madeup Museum',
      'FamilyName', 'GenusName', 'SpeciesName', "CommonName",
      '01/01/1901', 'Irving Washington, Washington Irving', 'juvinile', 'Female',
      'Australia', 'Alice Springs', 'Uluru',
      as.double(23.700552), as.double(133.882675)
    )
  )
  
  # Export xlsx file with two worksheets
  readr::write_excel_csv(
    x = template,
    file = here::here(path, paste0(filename, '.csv')), 
    col_names = TRUE
  )
  
  readr::write_excel_csv(
    x = template_descriptions,
    file = here::here(path, paste0(filename, '-descriptions.csv')),
    col_names = TRUE
  )
  
  readr::write_rds(
    x = col_spec,
    file = here::here(path, paste0(filename, '-column-specification.rds'))
  )
}
