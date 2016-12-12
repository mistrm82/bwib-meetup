#https://gist.github.com/jcheng5/4050398
library(ggplot2)
options(shiny.maxRequestSize = -1)
shinyServer(function(input, output, session) {

    dat <- reactive({
        if (is.null(input$files)) {
            # User has not uploaded a file yet
            return(NULL)
        }
        load(input$files$datapath)
        updateSelectInput(session, "srcgen", choices = colnames(colData(se)))
        updateSelectInput(session, "srccol", choices = colnames(colData(se)))
        return(se)
    })

  datasetInput <- function(se, xs, c){
      if (!is.null(se) & xs!="" & c!=""){
          counts <- assays(se)[[1]]
          design <- colData(se)
          exp<-(unlist(counts[input$gene,]))
          if (sum(is.na(exp)) == 0){
              xaxis<-design[,xs]
              color<-design[,c]
              exp<-data.frame(exp=exp,xaxis=xaxis,color=color)
              return(exp)
          }
      }
    NULL
  }

  output$distPlot <- renderPlot({
      df<-datasetInput(dat(), input$srcgen, input$srccol)
      if (!is.null(df)){
          p <- ggplot(df, aes(factor(xaxis), exp, color=color)) +
              geom_jitter(aes(group=color),size=1) +
              stat_smooth(aes(x=factor(xaxis), y=exp, group=color),size=0.3, fill="grey80") +
              geom_boxplot(aes(fill=color),alpha = 0.2) +
              theme_bw(base_size = 7) +
              scale_color_brewer(palette="Set1")+
              theme_bw(base_size = 16, base_family = "serif") +
              labs(list(y="abundance",x=""))
          suppressWarnings(print(p))
      }

  })
})