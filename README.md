# Read CSV file operator

##### Description

`read_csv` operator transforms a csv file in to Tercen datasets. Tercen itself has a 'Delimited text' file import but you can't use that one in a workflow step.

##### Usage

Input projection|.
---|---
`documentId`        | is the documentId (document can be a single csv file, or a zipped set of csv files)


Output relations|.
---|---
`filename`          | character, the name of the csv file

##### Details

The operator transforms a csv file into a Tercen table. If the document is a ZIP file containing a set of csv files, the operator extracts the csv files and transforms them into Tercen table.