insertPirData <- function(conn, workbooks, schema, log_file) {
  walk(
    workbooks,
    function(workbook) {
      year <- attr(workbook, "year")
      genResponseSchema(conn, year)
      map(
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