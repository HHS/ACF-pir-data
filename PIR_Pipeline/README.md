# PIR Pipeline

## Requirements

-   [Python](https://www.python.org/) 3.10 or greater
-   [R](https://www.r-project.org/)
    -   [Rtools](https://cran.r-project.org/bin/windows/Rtools/)
-   [MySQL](https://dev.mysql.com/downloads/mysql/)

## Pre Installation

These installation instructions assume that the installation is happening on a system with Python (and/or Anaconda) on the PATH. If this is not true, follow the directions [here](https://realpython.com/add-python-to-path/).

It will be helpful to have a few pieces of information on hand: 1. Path to RScript.exe - Setup will try to find this, but in the event that it cannot the user will need to provide it. 2. Database credentials - Setup will specifically request the username, password, host, and port for the target database. Use credentials for an account with administrator level privileges.

## Package Installation

1.  Clone the repository from GitHub [LINK]().

2.  Create a new virtual environment in which to install the package.

    -   Open up a command prompt.
    -   Navigate to where you would like to install the package.
    -   In the command prompt type `python -m venv <name-of-venv-directory>` (henceforth referred to as `venv`) and press `enter`.
        -   If working with Anaconda `conda create --name <name-of-venv-directory>` should work.

    This will create a virtual environment named `venv` in the current directory. A virtual environment is a self-contained directory tree that contains a Python installation for a particular version of Python, plus a number of additional packages. It allows you to work on the PIR Pipeline project in isolation from other projects.

3.  Activate the virtual environment.

    -   In the directory where `venv` was created, type `venv\Scripts\activate` into the command prompt and press `enter`
        -   With Anaconda `conda activate venv`

4.  Install the PIR Pipeline Package using the Python wheel file. The `dist` folder contains the relevant `.whl` file. Enter the following commands:

    -   `cd PIR_pipeline\dist`
    -   `pip install pir_pipeline-1.0.0-py3-none-any1.whl`

Package installation should now be complete.

### Configuration

1.  Open the command prompt.
2.  Activate the virtual environment `venv`.
3.  In the command prompt type `pir-setup` and press `enter`. A GUI should appear requesting the path at which to create the PIR directories and the path to *RScript.exe*.
4.  Click `finish` after providing these paths.
5.  A second window should appear requesting database credentials.
6.  Click `finish` after entering your credentials.
7.  The configuration file will now be generated, the database populated with relevant schemas, views, and stored procedures, and R packages installed.

### R Package Installation

R packages should be installed during setup. If this did not happen, or you do not want to run the full setup, R packages can be installed by following these steps:

1.  Open the command prompt.
2.  Activate the virtual environment `venv`.
3.  Type `pir-r-packages` and press `enter`.

## Data Ingestion

This section will refer to the directory chosen for the PIR directory structure as `PIR`.

Raw data should be stored in `PIR\PIR_data_repository\Raw`. This is the only folder in `PIR\PIR_data_repository` that you need to manage. `PIR\PIR_data_repository\Unprocessed` will contain any files that were not processed due to incorrect file types. After a successful ingestion files will be copied from `PIR\PIR_data_repository\Raw`, given a timestamp, and moved to `PIR\PIR_data_repository\Processed`.

The command `pir-ingest` can be used to ingest data. This command has a few options:

-   `--now`: Immediately trigger ingestion.
-   `--files`: Combine with `--now` to trigger immediate ingestion only for specific files.

An example workflow might look like this:

1.  Place data in the `PIR\PIR_data_repository\Raw` folder.
2.  Open the command prompt.
3.  Activate the virtual environment `venv`.
4.  Type:
    -   `pir-ingest` to schedule all files in the `PIR\PIR_data_repository\Raw` folder for ingestion.
    -   `pir-ingest --now` to immediately ingest all files in the `PIR\PIR_data_repository\Raw` folder.
    -   `pir-ingest --now --files <path-to-file-1>...<path-to-file-n>` to immediately ingest only the files listed.
5.  To verify that ingestion succeeded:
    -   Query pir_logs schema e.g.: `SELECT *       FROM pir_logs.pir_ingestion_logs       WHERE run = (          SELECT max(run)          FROM pir_logs.pir_ingestion_logs      )`

## Linking Questions

A great feature of PIR data is that it is available longitudinally. A challenge is that there are not always clear connections between each yearly iteration of the survey. A set of links can be created between questions using the `pir-link` command.

1.  Open the command prompt.
2.  Activate the virtual environment `venv`.
3.  Type `pir-link`.
4.  To verify that questions successfully linked:
    -   Query pir_logs schema e.g.: `SELECT *       FROM pir_logs.pir_question_linkage_logs       WHERE run = (          SELECT max(run)          FROM pir_logs.pir_question_linkage_logs      )`

### Creating Manual Links in the Dashboard

Due to the complexity and variability of questions, not all possible links can be accurately determined solely in the `pir-link` step. `pir-link` may occasionally leave certain questions unlinked. These unlinked questions require additional review to ensure accurate and appropriate linking. To address this and link unlinked questions, you can use the "Review Links" tab of the dashboard. The instructions on how to link/unlink questions using the dashboard are provided below under [Review Links](#review-links).

## Database Management

### Existing views, tables, stored procedures, and functions

### Creating views, stored procedures, and functions

## Dashboard

### Question Link Overview tab

The Question Link Overview tab provides a summary of three types of logs: Ingestion Logs, Listener Logs, and Question Linkage Logs. Additionally, it includes tables displaying counts of linked and unlinked questions, both for unique questions and all questions.

### Search for Question by Keyword tab

This tab facilitates the search for questions across multiple tables, including linked, unlinked, proposed, imperfect, and inconsistent question tables. Users can enter search criteria such as question name, text, number, category, or section to find specific questions. Upon performing a search, the system returns a table of questions matching the specified criteria, displaying relevant details such as the question's name, text, number, category, and section.

### Review Links {#review-links}

#### Review Unlinked Questions

Under the "Review Unlinked Questions" tab, you can review and link unlinked questions. This process involves selecting the unlinked question ID, choosing the algorithm for linkage (either Base or Jaccard), reviewing proposed links in the table, and ultimately linking the chosen proposed link using the "Link" button. Upon accessing the tab within the dashboard interface, you'll find a list of unlinked questions awaiting review. From this list, select the question ID of the unlinked question you wish to address. Before proceeding, decide whether to utilize the base algorithm, which suggests links based on predefined criteria, or the Jaccard algorithm, which assesses similarity in question text. After selecting the algorithm, review the proposed links generated in the table. Each proposed link represents a potential connection between the unlinked question and other questions in the system. Carefully assess the relevance and accuracy of each proposed link in establishing the desired connection. Once you've identified the most suitable link, select it within the dashboard interface. Finally, confirm your choice by clicking the "Link" button, effectively establishing the connection between the questions. This systematic approach ensures the accurate and relevant linkage of unlinked questions.

#### Review Intermittent Links

This section is dedicated to establishing question links that cover the full range of years sampled. Any question that is not linked for all years will appear here as a base question with a series of proposed linkages. Below are the definitions:

- Base: A question that is not matched for the full year range.
- Proposed: The proposed match to the base question.

Linking the two questions will distribute whichever 'uqid' exists in more cases across both of the 'question ids'. It's essential that the questions have different 'uqid' and different 'question id' for accurate linkage.

#### Review Inconsistent Links

Within the dashboard interface, the "Review Inconsistent Links" tab provides a straightforward method for addressing and managing inconsistent question links. This tab facilitates the process of unlinking previously connected questions. To begin, navigate to the dashboard interface and locate the "Review Inconsistent Links" tab. Upon accessing the tab, you'll find a list of unique question IDs. Identify the unique question ID of the question you wish to unlink from others, then review the associated question and its linked connections. Determine which specific question(s) you want to unlink from the selected question. Once you've made your selection, click on the "Unlink" button within the dashboard interface. This action will remove the specified link(s) between the selected question and the chosen question(s) to unlink. By following these steps, you can effectively manage inconsistent links within the database, maintaining the accuracy and integrity of question links.


