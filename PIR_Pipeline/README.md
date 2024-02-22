# PIR Pipeline

## Installation

1. Download the package from GitHub. The dist\ folder contains the relevant .whl file.
2. Create a new virtual environment in which to install the package.
    - Open up a command prompt.
    - Navigate to where you would like to install the package.
    - In the command prompt type `python -m venv <name-of-venv-directory>` (henceforth refered to as venv) and press `enter`.
3. Activate the virtual environment.
    - In the directory where venv was created type `venv\Scripts\activate` into the command prompt and press `enter`
4. Install the package
    - Type `pip install <path-to-.whl>` in the command prompt and press `enter`.
5. The package should now be installed.

### Configuration

1. Open the command prompt.
2. Navigate to venv and activate the virtual environment.
3. In the command prompt type `pir-setup` and press `enter`. A GUI should appear requesting the path at which to create the PIR directories and the path to RScript.exe. Click `finish` after providing these paths.
4. A second window should appear requesting database credentials. After entering your credentials click `finish`.
5. The configuration file will now be generated and the database will be populated with relevant schemas, views, and stored procedures.

### R Package Installation

- pir-r-packages (currently not working)

## Data Ingestion

### Ingesting from the Command Line

- pir-ingest

## Linking Questions

### Linking From the Command Line

- pir-link

### Creating Manual Links in the Dashboard

## Database Management

### Existing views, tables, stored procedures, and functions

### Creating views, stored procedures, and functions

## Dashboard

### Viewing the data

### Linking/Unlinking