# Shiny Sample Management

This is a work in progress Shiny application for managing samples. The goal is
to store sample data in a `SQL` database that can be built, queried and added
to with ease. A big focus of mine will be on data-consistency. What I mean by
this is:

* Mandatory meta-data fields that must be populated
* Meta-data entries conforming to pre-defined specifications (field specific)

Whilst the main focus of this repository is the `Shiny` application,
I have provided some scripts to help build a starting database.

What I hope to build is a Shiny application that enables users to:

* View their sample records
* Filter samples on specific fields
* Ingest samples into the database from the application
* Validate incoming data to prevent contaminating the database
* Export sample information from the database
* Visualise sample locations on a dynamic world-map

## Application preface

This project isn't going to be optimal. I've not written many Shiny applications
and wanted to build this for my lab-group. I've also not had much experience
with building, interacting with or maintaining databases, so I have no expectation
that how I've implemented *anything* is going to be best-practices.

The code in this server has been written with best intentions. I know I
could make a more modular application with Shiny modules, but the truth is that
whilst I got many of the sidebar filters working, it was taking more time than
I'd like to admit to get the application doing what I wanted. Consequently I
settled for the approach I've taken.

Similarly, the database implementation code is very simple. I've essentially
just looked at a few examples on the net and got something working that does
what I want. My code is not perfect, but it's stable enough and does what I need
it to do. I'm sure there are edge-cases (or not so edge-cases) that would bring
everything crashing down, but so far I've been in the clear.

### Other Users Adapting This Code

I have no issue with anyone taking this code and adding to it, updating it or
totally re-writing it. The biggest limitations to adapting this code for your
own sample management include:

- Hard-coded columns
- Sidebar filters written specifically for the hard-coded columns
- Non-modular design - a modular application may help with the points above
- Database management - `dbplyr` is a package I use heavily, but it is designed
for database querying, not managing. As such, my code 'collects' the data from
the DB, appends new samples then **overwrites** the existing database with the
new file. Not great, but does the trick.

There are others, but these are the things that will need to be considered when
adjusting this code. If you have experience with `R` and `Shiny` then you'll
probably be able to navigate these issues pretty easily, it'll just be more
time consuming than anything else.

## Getting started

With that out of the way, I'll demonstrate below how to set up a basic database
using the column specifications from this repository and then start up the
application. The script used to build the example dataset can be found
[here][exampleData] for reference.

### Step 1: Download a template file

If you do not already have a "database"" of samples (e.g. in a Excel spreadsheet
or something...) ready to go, you can run the `exportEmptySampleSheet()` command
to download a *CSV* template file that you can edit.

```r
exportEmptySampleSheet(
  path = '/path/to/outdir',
  filename = 'template-sample-sheet'       # Optional argument
)
```

If the `filename` argument is left as default, this will create the following
files at the `path` location:

- **template-sample-sheet.csv**: File to edit with your own sample information
- **template-sample-sheet-descriptions.csv**: Descriptions of the columns in the
above file
- **template-sample-sheet-column-specifications.rds**: Column specification i.e.
data types expected in each column (integer, character, date)

Fill out the `template-sample-sheet.csv` file with your own information. Best
practices would be to require each field to have information. Currently I have
not implemented hard-requirements on these columns. For right now, use your
own judgement on what fields are necessary and should have information.

### Step 2: Build a database

Once you have populated the `template-sample-sheet.csv` file, it's time to create
a *SQLite* database using the sample sheet. In the scripts directory is the
`buildDatabase.R` script which can be used to convert the sample *CSV* file into
a *SQLite* database. It can be called like so

```r
buildDatabase(
  path_samplesheet = 'edited-samplesheet.csv',
  path_col_spec_rds = 'template-sample-sheet-column-specification.rds',
  path_db_location = 'path/to/database/output/location',
  str_db_name = 'lab-group-DB',
  force_overwrite = TRUE
)
```

The call above takes your edited sample sheet along with the column specification
*RDS* file and builds the *SQLite* database. It will store the sample sheet in a
table called **mandatory_information** - this is the ID that can be used when
querying the database to pull out this information.

If a database by the same name exists at the output location, the command will
stop. It's possible to overwrite the database with the same name at the output
location by specifying `force_overwrite = TRUE`, which will delete the existing
database and create a new one with the new sample information.

### Step 3: Moving on to running the Shiny Application

Now that the database has been created, it's time to configure the Shiny app.
to work with your custom data.

## Configuring the Shiny Application

If you're using the application in its default form, there is minimal set-up
required. You'll need to set two paths in the `server.R` script to get
everything running.

### Database path

You'll need to set the path to your own databse file in the following code

```r
con <- pool::dbPool(
  drv = RSQLite::SQLite(),
  dbname = '/path/to/your-db.sqlite'
)
```

### Column specification path

The path to the column-specification file is also needed. The application uses
this object for validating incoming data. Simply change the path in the code
below, also found in the `server.R` script:

```r
col_spec <- readr::read_rds('/path/to/your-column-specification.rds')
```

## Running the Application

Now that we've configured the necessary files with our database information, we
can run the application using the following command (assuming we're in the
`sample-management` directory):

```r
> shiny::runApp('../sample-management')
```

## The Application

Below are a couple of screen shots of the application running. 

![Application home screen][figure_home]

![Plotting the samples using their latitude and logitude][figure_map]

[exampleData]: https://github.com/a-lud/sample-management/blob/main/example-data/example-set-up.R
[figure_home]: https://github.com/a-lud/sample-management/blob/main/docs/figures/app-home.png
[figure_map]: https://github.com/a-lud/sample-management/blob/main/docs/figures/app-plot-samples.png
