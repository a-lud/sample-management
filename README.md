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

More to come...
