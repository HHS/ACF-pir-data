# Performing the QA Process on the PIR

The [PIR database](https://github.com/HHS/ACF-pir-data) aims to make the data from the Program Information Report (PIR) easier to analyze by linking questions from different years. Prior to the creation of the PIR database, users had to manually link questions across years by comparing question information across data files and cross-referencing with the survey form question descriptions. To address this, we implemented a fuzzy matching approach that compares the similarity of three components of a question: the question name, question number, and question text. The PIR QA dashboard is the tool for validating the results of this method. 

# The Method

The algorithm for matching questions across years looks at the three components of a question in the PIR data, question name, question number, and question text, and assigns the question a unique ID value (which we call a *question id*) by generating an [MD5 hash](https://www.md5hashgenerator.com/) on the sombined values of those three components. This happens for all questions in the data as it is loaded into the database. 

Once the data has been loaded and the questions have had their unique ID values assigned, the algorithm checks each question against each question from previous years in the database. If two questions have the same question id they are considered matched. Matched questions are then assigned a *unique question id*, which is a separate value from the question's *question id*. 

If a question finds no matches, then the algorithm performs the same search and checks whether or not a question shares the same of any two of its values with another question. For example, let's compare the following two questions (NOTE: These are hypothetical questions, and don't reflect the actual question data.):

| Year            | 2021 | 2022 |
| :-------------- | :--: | :--: |
| Question name   |  Cumulatively Enrolled Children  |  Cumulatively Enrolled Children  |
| Question number | A.10  | A.9  |
| Question text   | Total number of children enrolled in the program throughout the year. | Total number of children enrolled in the program throughout the year. |

These questions, from 2021 and 2022, would be linked because they share the same values for their question name and question text, despite them not having the same question number. 

If, however, these questions only shared one value (NOTE: The value of question text now differs.):

| Year            | 2021 | 2022 |
| :-------------- | :--: | :--: |
| Question name   |  Cumulatively Enrolled Children  |  Cumulatively Enrolled Children  |
| Question number | A.10  | A.9  |
| Question text   | Total children enrolled in the program throughout the year. | Total number of children enrolled in the program throughout the year. |

The algorithm would not link these questions, even though they are likely to reference the same thing. There are four types of links that result from this algorithm:

* **Complete questions** are questions that have a single *unique question id* across the entire range of years contained in the database. All of these questions have both the same *unique question id* and the same *question id*. It is highly likely that these questions are correctly linked. 
* **Unlinked questions** are questions that have no *unique question id*, meaning they have no matching *question id* with any other question in the database and don't share at least two values with any other question. These questions may be unique to a given year in the dataset or there may have a link but have significant differences in question values with their matching question from another year.
* **Partial question links** are questions that have been linked across a range of years in the data, but not across the entirety of the available data. For example, a question may have been linked from 2008 to 2011, but the *unique question id* for that question ends there. There are many cases where question values have changed for a question series during specific periods in the history of the PIR, but the quesiton is still referencing the same concept. Many of these question links have matching links with other questions in the data. 
* **Inconsistent question links** are questions that, despite having the same *unique question id*, they have different *question id* values. These are questions that were matched not by the *question id* but by similar values in the data. These questions should all be verified by manual review. 

Reviewing and fixing bad links or linking questions that were missed in the linking process is accomplished by the PIR QA dashboard, a tool developed for analysts to address linking issues in the database. 

