# PIR Pipeline
To set up the PIR Pipeline, follow these steps:
## Installation 
1. Create a Virtual Environment
    ```
    python -m venv venv 
    ```
    This will create a virtual environment named venv in the current directory. A virtual environment is a self-contained directory tree that contains a Python installation for a particular version of Python, plus a number of additional packages. It allows you to work on the PIR Pipeline project in isolation from other projects.

2. Install the PIR Pipeline Package using the wheel

    ```
    - pip install <path to .whl>
    ```
     Replace <path to .whl> with the actual path to your .whl file.

### Configuration
Next, run *pirSetup.py*. *pirSetup.py* is a Python script that provides a graphical user interface (GUI) for setting up file paths and configuring the database (DB) for the PIR Pipeline. It also creates an R Project and installs all necessary Python and R packages and creates three DB schemas.
    
```
python <path to pirSetup.py> 
```

Replace <path to pirSetup.py> with the actual path to your file.

#### R Package Installation
    - pir-install-r-packages (currently not working)

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