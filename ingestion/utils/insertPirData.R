#' A wrapper for replaceInto and genResponseSchema
#' 
#' `insertPirData` wraps genResponseSchema and replaceInto
#' to handle insertion of PIR data into the MySQL database.
#' @param workbooks A single workbook path, or list of workbook paths, returned
#' from `loadPirData` (i.e. one that has data frame attributes).
#' @param log_file A data frame containing the log data.
#' @param schema A list of character vectors defining the columns that should
#' be kept (or added) to the corresponding data frame. Included here 
#' strictly for extraction of table names.
#' @param conn An SQL connection (to the PIR database).
#' @returns NULL

insertPirData <- function(conn, workbooks, schema, log_file) {
  walk(
    workbooks,
    function(workbook) {
      # Generate response table for the present year
      year <- attr(workbook, "year")
      genResponseSchema(conn, year)
      map(
        # Insert data for all tables
        names(schema),
        function(table) {
          df <- attr(workbook, table)
          if (table == "response") {
            replaceInto(conn, df, paste0(table, year), log_file)
          } else {
            if(!is.null(df) && nrow(df) > 0) {
              replaceInto(conn, df, table, log_file)
            } else {
              logMessage(paste("Table", table, "has 0 rows."), log_file)
            }
          }
        }
      )
    }
  )
}