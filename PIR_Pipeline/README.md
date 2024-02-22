# PIR Pipeline

To set up the PIR Pipeline, follow these steps:

## Installation

1.  Download the repository from GitHub [LINK].

2.  Create a new virtual environment in which to install the package.

    -   Open up a command prompt.
    -   Navigate to where you would like to install the package.
    -   In the command prompt type `python -m venv <name-of-venv-directory>` (henceforth referred to as `venv`) and press `enter`.

    This will create a virtual environment named `venv` in the current directory. A virtual environment is a self-contained directory tree that contains a Python installation for a particular version of Python, plus a number of additional packages. It allows you to work on the PIR Pipeline project in isolation from other projects.

3.  Activate the virtual environment.

    -   In the directory where `venv` was created type `venv\Scripts\activate` into the command prompt and press `enter`

4.  Install the PIR Pipeline Package using the wheel. The `dist` folder contains the relevant `.whl` file.

    -   Type `pip install pir_pipeline-1.0.0-py3-none-any1.whl` in the command prompt and press `enter`.

    The package should now be installed.

### Configuration

1.  Open the command prompt.
2.  In the command prompt type `pir-setup` and press `enter`. A GUI should appear requesting the path at which to create the PIR directories and the path to *RScript.exe*. Click `finish` after providing these paths.
3.  A second window should appear requesting database credentials. After entering your credentials click `finish`.
4.  The configuration file will now be generated and the database will be populated with relevant schemas, views, and stored procedures.

### R Package Installation

1.  Open the command prompt.
2.  In the command prompt type `pir-r-packages` and press `enter`. This will install all of the necessary R packages.

## Data Ingestion

### Ingesting from the Command Line

-   pir-ingest

-   sql command for verifying the ingestion (pir-ingest) completed successfully select distinct year from pir_data.response

## Linking Questions

### Linking From the Command Line

-   pir-link
-   sql command for verifying the pir-link completed successfully select distinct year from pir_question_links.linked

### Creating Manual Links in the Dashboard

## Database Management

### Existing views, tables, stored procedures, and functions

### Creating views, stored procedures, and functions

## Dashboard

### Viewing the data

### Linking/Unlinking
