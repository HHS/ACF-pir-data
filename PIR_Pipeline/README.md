# PIR Pipeline

## Requirements

- [Python](https://www.python.org/) 3.10 or greater
- [R](https://www.r-project.org/)
    - [Rtools](https://cran.r-project.org/bin/windows/Rtools/)
- [MySQL](https://dev.mysql.com/downloads/mysql/)

## Pre Installation

These installation instructions assume that the installation is happening on a system with Python (and/or Anaconda) on the PATH. If this is not true, follow the directions [here](https://realpython.com/add-python-to-path/).

It will be helpful to have a few pieces of information on hand:
1. Path to RScript.exe
    - Setup will try to find this, but in the event that it cannot the user will need to provide it.
2. Database credentials
    - Setup will specifically request the username, password, host, and port for the target server. Use credentials for an account with administrator level privileges.

## Package Installation

1.  Clone the repository from [GitHub](https://github.com/HHS/ACF-pir-data).

2.  Create a new virtual environment in which to install the package.

    -   Open up a command prompt.
    -   Navigate to where you would like to install the package.
    -   In the command prompt type `python -m venv <name-of-venv-directory>` (henceforth referred to as `venv`) and press `enter`.
        - If working with Anaconda `conda create --name <name-of-venv-directory>` should work. 

    This will create a virtual environment named `venv` in the current directory. A virtual environment is a self-contained directory tree that contains a Python installation for a particular version of Python, plus a number of additional packages. It allows you to work on the PIR Pipeline project in isolation from other projects.

3.  Activate the virtual environment.

    - In the directory where `venv` was created, type `venv\Scripts\activate` into the command prompt and press `enter`
        - With Anaconda `conda activate venv`

4.  Install the PIR Pipeline Package using the Python wheel file. The `dist` folder contains the relevant `.whl` file. Enter the following commands:

    - `cd PIR_pipeline\dist`
    - `pip install pir_pipeline-1.0.0-py3-none-any1.whl`

Package installation should now be complete.

### Configuration

1. Open the command prompt.
2. Activate the virtual environment `venv`.
3. In the command prompt type `pir-setup` and press `enter`. A GUI should appear requesting the path at which to create the PIR directories and the path to *RScript.exe*. 
4. Click `finish` after providing these paths.
5. A second window should appear requesting database credentials. 
6. Click `finish` after entering your credentials.
7. The configuration file will now be generated, the database populated with relevant schemas, views, and stored procedures, and R packages installed.

### R Package Installation

R packages should be installed during setup. If this did not happen, or you do not want to run the full setup, R packages can be installed by following these steps:

1. Open the command prompt.
2. Activate the virtual environment `venv`.
3. Type `pir-r-packages` and press `enter`.

## Data Ingestion

This section will refer to the directory chosen for the PIR directory structure as `PIR`. 

Raw data should be stored in `PIR\PIR_data_repository\Raw`. This is the only folder in `PIR\PIR_data_repository` that you need to manage. `PIR\PIR_data_repository\Unprocessed` will contain any files that were not processed due to incorrect file types. After a successful ingestion files will be copied from `PIR\PIR_data_repository\Raw`, given a timestamp, and moved to `PIR\PIR_data_repository\Processed`.

The command `pir-ingest` can be used to ingest data. This command has a few options:

- `--now`: Immediately trigger ingestion.
- `--files`: Combine with `--now` to trigger immediate ingestion only for specific files.

An example workflow might look like this:

1. Place data in the `PIR\PIR_data_repository\Raw` folder.
2. Open the command prompt.
3. Activate the virtual environment `venv`.
4. Type:
    - `pir-ingest` to schedule all files in the `PIR\PIR_data_repository\Raw` folder for ingestion. 
    - `pir-ingest --now` to immediately ingest all files in the `PIR\PIR_data_repository\Raw` folder.
    - `pir-ingest --now --files <path-to-file-1>...<path-to-file-n>` to immediately ingest only the files listed.
5. To verify that ingestion succeeded:
    - `pir-status --ingestion`
    - Query pir_logs schema directly e.g.:
        ```
        SELECT * 
        FROM pir_logs.pir_ingestion_logs 
        WHERE run = (
            SELECT max(run)
            FROM pir_logs.pir_ingestion_logs
        )
        ```

## Linking Questions

A great feature of PIR data is that it is available longitudinally. A challenge is that there are not always clear connections between each yearly iteration of the survey. A set of links can be created between questions using the `pir-link` command.

1. Open the command prompt.
2. Activate the virtual environment `venv`.
3. Type `pir-link`.
4. To verify that questions successfully linked:
    - `pir-status --link`
    - Query pir_logs schema directly e.g.:
        ```
        SELECT * 
        FROM pir_logs.pir_question_linkage_logs 
        WHERE run = (
            SELECT max(run)
            FROM pir_logs.pir_question_linkage_logs
        )
        ```

## PIR Monitoring Dashboard

The PIR package includes an R Shiny dashboard for reviewing logs, viewing data, and managing question links. To start the dashboard:

1. Open the command prompt.
2. Activate the virtual environment `venv`.
3. Type `pir-dashboard` and press `enter`.
4. A series of messages will print, culminating with a message that says *Listening on \<url>*. Navigate to this url in a browser to view the dashboard.

To close the dashboard:
1. Close the browser tab.
2. In the command prompt, press `CTRL+C`.

### Viewing the data

### Creating Manual Links in the Dashboard

The algorithm does a good job of linking questions, but there are some cases a user might want to review manually. Specifically:

1. Questions are linked within some sub-period of the full period available. For example if data were ingested for 2008-2023, but a specific question is only linked in 2008-2010.
2. Questions are linked, but the question IDs vary over time.
3. Questions are unlinked.

The dashboard provides options for reviewing and rectifying these three scenarios. To manually create and delete links

## Database Management

### Existing views, tables, stored procedures, and functions

### Creating views, stored procedures, and functions
