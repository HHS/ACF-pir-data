# PIR Database

The PIR database consolidates the PIR data from 2008 - Present (2024 at the time of writing) in a single database with the goals of improving accessibility and facilitating analysis. Information about the processing that raw data undergo before entering the PIR database can be found in [workflow.md](workflow.md).

## Tables

### Question

### Program

### Response

### UQID Changelog

## Views

The following views are included with the PIR database:
- Linked - Includes all questions with a non-null UQID
- Unlinked - Includes all questions with a null UQID
- Confirmed - Includes all questions ever marked as confirmed
- Unconfirmed - Includes all questions never marked as confirmed

All linking views are mirrors of the *question* table. Refer to the [Tables](#tables) and [Data Dictionary](#data-dictionary) sections pertaining to the question table for additional details on the fields in these views.

## Data dictionary