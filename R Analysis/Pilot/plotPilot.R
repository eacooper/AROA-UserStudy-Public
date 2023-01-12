plotPilot <- function (title, dataSet, participant) {
  
  print(paste0("Plotting pilot study data for participant ", participant))
  
  
  defaultOrderPilot = c("Noticed Obstacles", "Know Location", "Know Size", "Cue Helped Notice", 
                        "Cue Helped Navigation", "Not Obscuring", "Not Distracting")

  
  #Graphing values
  
  FigLikert <-  dataSet %>% filter(Participant == participant) %>%
    mutate(Metric = factor(Metric, levels=defaultOrderPilot)) %>%  #Sets correct order
    ggplot(aes(x = Metric, y = Control, fill = Metric))+
    geom_bar(stat='identity', position='dodge')+
    theme(legend.position = 'none', axis.title.x = element_blank(), axis.text.x = element_text(size = 10), axis.title.y = element_text(size = 12, face="plain"))+
    ggtitle(title)+
    scale_x_discrete(labels = c("Noticed\nObstacles", "Know\nLocation", "Know\nSize", "Cue Helped\nNotice", 
                                "Cue Helped\nNavigation", "Not\nObscuring", "Not\nDistracting"))+
    scale_y_continuous(name=paste("Condition Ratings"), limits = c(0,5))
  
  # if (addJitter) {
  #   FigLikert <- FigLikert + geom_jitter(width = 0.15, height=0)
  # }
  
  print(FigLikert)
  # ggsave(paste0(title,".svg"), path = "./Plots./Likert")
  # ggsave(paste0(title,".eps"), path = "./Plots./Likert")
  # ggsave(paste0(title,".png"), path = "./Plots./Likert")

  
  
}