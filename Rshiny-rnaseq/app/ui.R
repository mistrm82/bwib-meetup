shinyUI(pageWithSidebar(
  headerPanel("Plot Expression using DEGReport package output"),
  sidebarPanel(
    fileInput("files", "File data", accept = c("rda")),
    selectInput("srcgen","Select genotype:", NULL),
    selectInput("srccol","Select colours:", NULL),
    textInput("gene", "Gene ID:", "ENSG00000000419"),
    submitButton("do","Update View")
  ),
  mainPanel(
    plotOutput("distPlot")
  )
))