friedmanControl <- function (title, filepath, plotPath, dataSet, targetRating, runTests = TRUE, addJitter = FALSE, type = "Wilcoxon") {
  
  
  #Title is the title of the test
  #Filepath is the filepath to save test results to (text and CSV), e.g. "./Tests./Preferred./Likert Ratings_WorldPref_Median"
  #plotPath is the filepath to save plots to, e.g. "./Plots./Likert"
  #dataSet is the data set to use (typically dataSet)
  #targetRating = target rating (e.g. Median.Rating, Confidence, etc.) as string
  #runTests -> Runs tests if true, otherwise only graphs
  #addJitter -> Adds geom_jitter to graphs if true
  #type = Wilcoxon or Friedman
  
  # Clear any outstanding sinks
  while (sink.number() > 0) {
    sink(file = NULL)
    print("Excess sink detected.")
  }
  
  print(paste("Friedman Test for",title))
  sink(file = paste0(filepath, ".txt")) # Start recording to a text file
  print(paste("Friedman Test for",title))
  
  # Calculate median and standard deviation
  graph_Ratings <- ddply(dataSet %>% filter(Condition == "Control (first)" | Condition == "Control (last)"), .(Condition), summarise, 
                         med = median(get(targetRating)), sd = sd(get(targetRating)))
  
  print("----------------MEDIAN VALUES----------------")
  print(graph_Ratings)
  
  # Get rating, condition, and subjects for test
  tmp_rating <- dataSet[[targetRating]][dataSet$Condition == "Control (first)" | dataSet$Condition == "Control (last)"]
  tmp_cond <- dataSet$Condition[dataSet$Condition == "Control (first)" | dataSet$Condition == "Control (last)"]
  tmp_subj <- dataSet$Participant.ID[dataSet$Condition == "Control (first)" | dataSet$Condition == "Control (last)"]
  # 
  # print(paste("tmp_rating:", tmp_rating))
  # print(paste("tmp_cond:", tmp_cond))
  # print(paste("tmp_subj:", tmp_subj))
  
  # print(tmp_rating)
  # print(tmp_cond)
  # print(tmp_subj)
  
  
  #Graphing values
  
  FigLikert <-  dataSet %>% filter(Condition == "Control (first)" | dataSet$Condition == "Control (last)") %>%
    #mutate(Condition = factor(Condition, levels=defaultOrder)) %>%  #Sets correct order
    ggplot(aes(x = Condition, y = get(targetRating), color = Condition))+
    geom_boxplot(outlier.shape = NA)+
    theme(legend.position = 'none', axis.title.x = element_blank(), axis.text.x = element_text(size = 12), axis.title.y = element_text(size = 12, face="plain"))+
    ggtitle(title)+
    #geom_label(data = graph_Ratings, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)+
    scale_x_discrete(labels=c("Collocated" = "World", "HUD" = "Head"))+
    scale_y_continuous(name=paste("Likert Scale Ratings", "(1 to 7)"), limits = c(1,7), breaks = c(1, 2, 3, 4, 5, 6, 7))
  
  if (addJitter) {
    FigLikert <- FigLikert + geom_jitter(width = 0.15, height=0)
  }
  
  #Display and save plots
  print(FigLikert)
  ggsave(paste0(title,".svg"), path = plotPath)
  ggsave(paste0(title,".eps"), path = plotPath)
  ggsave(paste0(title,".png"), path = plotPath)
  

  if(runTests) {
    
    if (type == "Friedman") {
      print("----------------FRIEDMAN TESTS----------------")
      
      print("Omnibus Friedman Test")
      friedmanAll = (friedman.test(tmp_rating,tmp_cond,tmp_subj))
      print(friedmanAll)
      roundChiOmnibus = round(as.numeric(friedmanAll[["statistic"]])*10000)/10000
      roundPOmnibus = round(as.numeric(friedmanAll[["p.value"]])*10000)/10000
      if(roundPOmnibus < 0.001) {roundPOmnibus = "<<0.001"}
      if(as.numeric(friedmanAll[["p.value"]]) < pVal) {pfOmnibus = "PASS"} else {pfOmnibus = "FAIL"}
      
      
      print("----------------FRIEDMAN RESULTS----------------")
      resultsTable = data.frame(matrix(ncol = 5, nrow = 0))
      colnames(resultsTable) <- c("Test", "Chi Sq", "p value", "Corrected p threshold", "Result")
      resultsTable[nrow(resultsTable) + 1,] = c("Omnibus", roundChiOmnibus, roundPOmnibus, pVal, pfOmnibus)
      
      print(paste("Omnibus test with chi-squared value of", roundChiOmnibus, "and p-value of",roundPOmnibus,"tested against default p value", pVal,". Result =", pfOmnibus))
      
    }
    
    else if (type == "Wilcoxon") {
      print("----------------WILCOXON TESTS----------------")
      
      # Method 1, using wilcox.test
      print("Wilcoxon Test")
      WilcoxonTest <<- wilcox.test(tmp_rating[tmp_cond == "Control (first)"], tmp_rating[tmp_cond == "Control (last)"], paired = TRUE, alternative = "two.sided")
      print(WilcoxonTest)
      
      WilcoxonV = WilcoxonTest[["statistic"]]
      WilcoxonP = WilcoxonTest[["p.value"]]
      roundPWilcoxon = round(as.numeric(WilcoxonP)*10000)/10000
      if (roundPWilcoxon < 0.001) {roundPWilcoxon = "<<0.001"}
      if(as.numeric(WilcoxonP) < pVal) {pfOmnibus = "PASS"} else {pfOmnibus = "FAIL"}
      
      # Calculate effect size
      effSize = qnorm(WilcoxonP/2)/sqrt(length(tmp_cond)/2) * (-1)
      effSizeRound = round(as.numeric(effSize)*1000)/1000
      
      #Determine magnitude
      if (effSize < 0.3)
        effMag = "small"
      else if (effSize < 0.5)
        effMag = "medium"
      else
        effMag = "large"
      
      print(paste("Wilcoxon effect size:", effSizeRound))
      

      # #Method 2, using wilcox_test
      # print("Wilcoxon Test")
      # formulaText = paste0(targetRating, " ~ Condition")
      # wilcoxonTest2 <- wilcox_test(data = dataSet, formula = as.formula(formulaText), paired = TRUE, alternative = "two.sided")
      # print(wilcoxonTest2)
      # 
      # #Calculate effect size. 
      # Note that result using wilcox_effsize may be different than qnorm above.
      # print("Wilcoxon effect size")
      # wilcoxonSize <- wilcox_effsize(data = dataSet, formula = as.formula(formulaText), paired = TRUE, alternative = "two.sided")
      # effSize = wilcoxonSize[["effsize"]]
      # effSizeRound = round(as.numeric(effSize)*1000)/1000
      # effMag = wilcoxonSize[["magnitude"]]
      # print(wilcoxonSize)
      
      
      print("----------------WILCOXON RESULTS----------------")
      resultsTable = data.frame(matrix(ncol = 7, nrow = 0))
      colnames(resultsTable) <- c("Test", "V", "p value", "Corrected p threshold", "Result", "Effect Size", "Effect Magnitude")
      resultsTable[nrow(resultsTable) + 1,] = c("Omnibus", WilcoxonV, roundPWilcoxon, pVal, pfOmnibus, effSize, effMag)
      
      print(paste("Omnibus test with V value of", WilcoxonV, "and p-value of",roundPWilcoxon,"tested against default p value", pVal,". Result =", pfOmnibus))
      print(paste("Wilcoxon effect size of", effSizeRound, "and magnitude", effMag))
      
    }
    
    else {print("Test type incorrect. Please use Wilcoxon or Friedman.")}
    
    # Write results to table
    write.csv(resultsTable, paste0(filepath, ".csv"), row.names = TRUE)
    
  
    
  }
  
  sink(file = NULL)
  
  
  
}