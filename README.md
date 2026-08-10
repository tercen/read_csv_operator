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
`*`                 | All columns from the imported CSV file(s)

##### Properties

Property|Description
---|---
`Headers`               | whether the file starts with a header line (default: `true`)
`Separator`             | value separator, `Comma` or `Tab` (default: `Comma`)
`NA String`             | strings to interpret as NA values (default: empty)
`Force`                 | merge files even if their column names differ (default: `false`)
`Add namespace`         | prefix factor names with the step namespace (default: `false`)
`Column types`          | comma-separated `name=type` pairs forcing column types, e.g. `WellId=string,Barcode=string`. Supported types: `string`, `double`. Empty means automatic type detection. Use this when a column contains number-like values (well IDs, barcodes...) that must be imported as a string factor: types are forced at read time, so leading zeros and long IDs are preserved.
`All columns as string` | import every column as string, disabling automatic type detection (default: `false`)

##### Details

The operator transforms a csv file into a Tercen table. If the document is a ZIP file containing a set of csv files, the operator extracts the csv files and transforms them into Tercen table.

Without `Column types`, column types are inferred from the data: a column containing only numbers is imported as `double` (integers and 64-bit integers are converted to double).
