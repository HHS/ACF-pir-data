# PIR Data Processing

This repository hosts code for processing [Program Information Report](https://eclkc.ohs.acf.hhs.gov/data-ongoing-monitoring/article/program-information-report-pir) data. The raw input data can be downloaded by following the *Access to PIR Data* instructions on the PIR web page. This is part of a pilot effort to make the data more usable by various audiences. If you have any questions about this pilot, please contact Jesse.Escobar@acf.hhs.gov.

The [PIR database](https://github.com/HHS/ACF-pir-data) aims to make the data from the Program Information Report (PIR) easier to analyze by linking questions from different years. Prior to the creation of the PIR database, users had to manually link questions across years by comparing question information across data files and cross-referencing with the survey form question descriptions.

For detailed documentation see [PIR Documentation](https://hhs.github.io/ACF-pir-data/)

## Notice

This is an early version of the processed data and is still being tested by the OHS data team. Confirm numbers using the raw input data before using for any reporting. If you identify a problem with the data please submit an issue on this repository. 

## Downloading the Processed Data

You can access the processed data by navigating to [`/pir-metrics/clean/output`](https://github.com/HHS/ACF-pir-data/tree/main/pir-metrics/clean/output). Within that folder is a CSV file containing the latest version of the processed data. The data dictionary is hosted at [`/pir-metrics/clean/hand`](https://github.com/HHS/ACF-pir-data/tree/main/pir-metrics/clean/hand). 
