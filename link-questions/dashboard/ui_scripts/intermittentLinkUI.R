dash_meta$intermittent_uqid_choices <- dbGetQuery(
  link_conn,
  "
  SELECT distinct uqid
  FROM imperfect_link_v
  WHERE intermittent_link = 1
  "
)

intermittent_id <- tabPanel(
  "Review Intermittent Links",
  sidebarPanel(
    selectInput(
      inputId = "intermittent_uqid", label = "Unique Question ID", 
      choices = dash_meta$intermittent_uqid_choices
    ),
    selectInput(
      inputId = "intermittent_proposed_link", label = "Proposed Link", choices = "None"
    ),
    actionButton(
      inputId = "intermittent_create_link", label = "Link"
    )
  ),
  mainPanel(
    tableOutput("intermittent_link")
  )
)