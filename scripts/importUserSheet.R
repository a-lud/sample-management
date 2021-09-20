# Add samples to database ---

# Returns a 'tibble' if everything is OK
checkImport <- function(input, col_spec) {
  # Load user data - catch any errors or warnings
  tryCatch(
    {
      # Import user data file
      df_user <- readr::read_csv(
        file = input,
        col_names = TRUE,
        col_types = col_spec
      )
    },
    error = function(e) {
      return(w)
    },
    warning = function(w) {
      return(w)
    }
  )
  
  # Check input for duplicate sample IDs
  vec_duplicated <- df_user %>%
    group_by(sample_id) %>%
    summarise(n = n()) %>%
    filter(n > 1) %>%
    pull(sample_id)
  
  if (length(vec_duplicated) != 0) {
    return(vec_duplicated)
  } else {
    return(df_user)
  }
}

# Returns 'TRUE' if everything is OK
checkNA <- function(tib) {
  na_lgl <- any(unlist(map(tib, ~{is.na(.x)})))
  
  cols_NA <- c()
  if (na_lgl) {
    if (nrow(tib) == 1) {
      imap(tib, ~{
        if(is.na(.x)) {
          cols_NA <<- c(cols_NA, .y)
        }
      })
    } else {
      imap(tib, ~{
        if(any(is.na(.x))) {
          cols_NA <<- c(cols_NA, .y)
        }
      })
    }
  }
  cols_NA <- paste(cols_NA, collapse = ', ')
  
  if(isFALSE(na_lgl)) {
    return(TRUE)
  } else {
    return(cols_NA)
  }
}

# Returns 'TRUE' if everything is OK
checkDateFormat <- function(tib) {
  date_outcome <- tryCatch(
    {
      tib %>%
        dplyr::mutate(
          collection_date = readr::parse_date(
            x = collection_date,
            format = '%d/%m/%Y'
          )
        )
      
      return(TRUE)
    },
    error = function(e) {
      return(e)
    },
    warning = function(w) {
      return(w)
    }
  )
}

checkDuplicateRows <- function(tib, con) {
  df_db <- tbl(con, 'mandatory_information') %>%
    dplyr::collect()
  
  # Intersect the data-frames - get identical rows
  df_intersect <- dplyr::intersect(tib, df_db)
  
  if (nrow(df_intersect) == 0) {
    return(TRUE)
  } else {
    return(paste(df_intersect$sample_id, collapse = ', '))
  }
}

checkDuplicateSampleIds <- function(tib, con) {
  df_db <- tbl(con, 'mandatory_information') %>%
    dplyr::collect()
  
  vec_sample_id_intersect <- intersect(df_db$sample_id, tib$sample_id)
  
  if (length(vec_sample_id_intersect) == 0) {
    return(TRUE)
  } else {
    return(paste(vec_sample_id_intersect, collapse = ', '))
  }
}

ingestFile <- function(tib, con) {
  df_db <- tbl(con, 'mandatory_information') %>%
    dplyr::collect()
  
  dplyr::copy_to(
    dest = con,
    df = bind_rows(df_db, tib),
    'mandatory_information',
    temporary = FALSE,
    overwrite = TRUE
  )
}
