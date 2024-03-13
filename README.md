# Read CSV file operator

##### Description

`read_csv` operator transforms csv files into Tercen datasets. It can upload an individual CSV file or multiple CSV files in a zipped folder.

CSV files (.csv) are text files which use a comma as the delimiter.

(Tercen also has a 'Delimited text' file importer with settings for both comma and other delimiter types. It has more advanced features for data maipulation but cannot be embedded as a file importer in a workflow.) 

##### Usage

Input projection|.
---|---
`documentId`        | is the documentId (document can be a single csv file, or a zipped set of csv files)


Output relations|.
---|---
`filename`          | character, the name of the csv file

##### Details

The operator transforms a csv file into a Tercen table. If the document is a ZIP file containing a set of csv files, the operator extracts the csv files and transforms them into Tercen table.
