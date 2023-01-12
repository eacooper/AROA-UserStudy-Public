plotAndAnova <- function (title, textPath, plotPath, dataSet, inclControl = TRUE, targetStat, yAxisLabel, yLimits = c(NA, NA), runTests = TRUE, addJitter = FALSE, filterOutliers = TRUE) {
  
  #Creates a plot and conducts ANOVA analysis for quantitative elements such as time and distance against condition
  #title: Title of graph/analysis
  #textPath: Where to save text and CSV results of analysis
  #plotPath: Where to save plots
  #dataSet: Dataset to use
  #inclControl: If false, will filter out control condition (defaults to true)
  #targetStat: The target statistic, e.g. Calibrated.Time
  #yAxisLabel: Label for the y axis
  #yLimits: Limits for the y axis (defaults to based on data)
  #runTests -> Runs tests if true, otherwise only graphs
  
  # Clear any outstanding sinks
  while (sink.number() > 0) {
    sink(file = NULL)
    print("Excess sink detected.")
  }
  
  print(paste("ANOVA for", title)) 
  sink(file = paste0(textPath, ".txt")) # Start recording to a text file
  
  #If control isn't included, filter it out of the dataset
  if (!inclControl) {
    dataSet = dataSet %>% filter(Condition != "Control")
  }
  
  print(paste("ANOVA for", title))
  print("-----------------------MEAN VALUES-----------------------")
  
  # Calculate mean, median, standard deviation, quartiles, and IQRs
  graph <- ddply(dataSet, .(Condition), summarise, mean = mean(get(targetStat)), sd = sd(get(targetStat)), 
                 median = median(get(targetStat)), mid = quantile(get(targetStat), 0.5), 
                 lower = quantile(get(targetStat), 0.25), upper = quantile(get(targetStat), 0.75), iqr = upper - lower, 
                 max_range = upper + 1.5*iqr, min_range = lower - 1.5*iqr)
  print(graph)

  if(filterOutliers) {
    #To filter out outliers:
    #Calculate outliers
    #First, store max and minimum ranges for each condition. If items are above or below this, they are outliers.
    if(inclControl) {
      maxWorld = graph$max_range[1]
      maxCombined = graph$max_range[2]
      maxControl = graph$max_range[3]
      maxHead = graph$max_range[4]
      maxNoCues = graph$max_range[5]
      
      minWorld = graph$min_range[1]
      minCombined = graph$min_range[2]
      minControl = graph$min_range[3]
      minHead = graph$min_range[4]
      minNoCues = graph$min_range[5]
    }
    
    else {
      maxWorld = graph$max_range[1]
      maxCombined = graph$max_range[2]
      maxHead = graph$max_range[3]
      maxNoCues = graph$max_range[4]
      
      minWorld = graph$min_range[1]
      minCombined = graph$min_range[2]
      minHead = graph$min_range[3]
      minNoCues = graph$min_range[4]
    }
    
    outlierList <- list()
    
    #Now iterate through each participant and see which ones are outliers.
    for (participant in unique(dataSet$Participant.ID)) {
      #Filter data set to just the given participant
      participantData <- dataSet %>% filter(Participant.ID == participant)
      
      #Assign the participant's scores for each condition
      pNoCues = participantData[[targetStat]][participantData$Condition == "No Cues"]
      pWorld = participantData[[targetStat]][participantData$Condition == "Collocated"]
      pHead = participantData[[targetStat]][participantData$Condition == "HUD"]
      pCombined = participantData[[targetStat]][participantData$Condition == "Combined"]
      if(inclControl) {pControl = participantData[[targetStat]][participantData$Condition == "Control"]}
      
      #Compare scores for each condition against that condition's maximum and minimum range
      #Add outliers to the outlier list
      if (as.numeric(pNoCues) > maxNoCues || as.numeric(pNoCues) < minNoCues) {
        print(paste0("Outlier found. Participant ", participant, " has NoCues score of ", pNoCues))
        outlierList <- append(outlierList, participant)
      }
      if (as.numeric(pWorld) > maxWorld || as.numeric(pWorld) < minWorld) {
        print(paste0("Outlier found. Participant ", participant, " has World score of ", pWorld))
        outlierList <- append(outlierList, participant)
      }
      if (as.numeric(pHead) > maxHead || as.numeric(pHead) < minHead) {
        print(paste0("Outlier found. Participant ", participant, " has Head score of ", pHead))
        outlierList <- append(outlierList, participant)
      }
      if (as.numeric(pCombined) > maxCombined || as.numeric(pCombined) < minCombined) {
        print(paste0("Outlier found. Participant ", participant, " has Combined score of ", pCombined))
        outlierList <- append(outlierList, participant)
      }
      
      if(inclControl) {
        if (as.numeric(pControl) > maxControl || as.numeric(pControl) < minControl) {
          print(paste0("Outlier found. Participant ", participant, " has Control score of ", pControl))
          outlierList <- append(outlierList, participant)
        }
      }
    }
    
    #Remove duplicates
    outlierList <- unique(outlierList) 
    
    print(paste0("Number of participants with outliers:", length(outlierList)))
    print(outlierList)
    
    #Remove outliers from dataset
    for (participant in outlierList) {
      dataSet <- dataSet %>% filter(Participant.ID != participant)
    }

    
    print("-----------------------MEAN VALUES - NO OUTLIERS-----------------------")
    
    # Calculate new values without outliers
    graph <- ddply(dataSet, .(Condition), summarise, mean = mean(get(targetStat)), sd = sd(get(targetStat)), 
                   median = median(get(targetStat)), mid = quantile(get(targetStat), 0.5), 
                   lower = quantile(get(targetStat), 0.25), upper = quantile(get(targetStat), 0.75), iqr = upper - lower, 
                   max_range = upper + 1.5*iqr, min_range = lower - 1.5*iqr)
    print(graph)
    
    
  }

  
  
  #Graph data
  FigTarget <- dataSet %>%
    mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
    ggplot(aes(x = Condition, y = get(targetStat), color = Condition))+
    geom_boxplot(outlier.shape = NA)+
    theme(legend.position = 'none', axis.title.x = element_blank(), 
          axis.text.x = element_text(size = 12), axis.title.y = element_text(size = 12, face="plain"))+
    ggtitle(title)+
    scale_x_discrete(labels=c("Collocated" = "World", "HUD" = "Head"))+
    #scale_y_continuous(name = yAxisLabel, limits = yLimits)  #This code accidentally scaled data, not axes
    labs(y = yAxisLabel)+
    coord_cartesian(ylim=yLimits)+
    stat_summary(fun.y="mean", shape = 20, size = 1)
  
  if (addJitter) {
    FigTarget <- FigTarget + geom_jitter(width = 0.15, height=0)
  }
  
  print("---------------------")
  print("Graph Data")  
  print(ggplot_build(FigTarget)$data)
  print(FigTarget)
  
  #Save graph
  ggsave(paste0(title,".svg"), path = plotPath)
  ggsave(paste0(title,".eps"), path = plotPath)
  ggsave(paste0(title,".png"), path = plotPath)
  
  if (runTests) {  
  
    print("-----------------------ANOVA-----------------------")
    
    print("Overall ANOVA")
    
    #Filter out outliers
    
    #Necessary workaround because ezAnova doesn't like to take variable names
    anovaFunc <- function (the_data, the_dv) {
      eval(
        substitute(
          ezANOVA(data = dataSet, 
                  dv = the_dv, 
                  wid = .(Participant.ID), 
                  within = .(Condition)), 
          list(the_dv = the_dv))
      )
    }
    
    anova_result = anovaFunc(dataSet, targetStat)
    
    print(anova_result)
    
    if (anova_result$`Mauchly's Test for Sphericity`$p <0.05) {
      mtsPass = FALSE
    } else {mtsPass = TRUE}
  
  
    
    print("-----------------------PAIRED T-TESTS-----------------------")
    
    # Create a counter and empty lists to store T-test information
    numTest = 0
    tList = list()
    dfList = list()
    pList = list()
    sizeList = list()
    sizeList2 = list()
    
    # Defining the T Test function. 
    tFunc <- function(con1, con2) {
      #Define unique test string
      testString = paste(con1, "vs", con2)
      print(testString)
      
      #Run test
      test <<- t.test(dataSet[[targetStat]][dataSet$Condition == con1], 
                    dataSet[[targetStat]][dataSet$Condition == con2], 
                    paired = TRUE, alternative = "two.sided")
      print(test)

      #Add test values to lists, identified by test string
      dfList[[testString]] <<- test["parameter"]
      tList[[testString]]  <<-  test["statistic"]
      pList[[testString]]  <<-  test["p.value"]
    
      print(paste("Effect size for", testString))
      
      # Calculate effect size (option 1)
      #print("Using cohen.d:")
      size <- cohen.d(dataSet[[targetStat]][dataSet$Condition == con1], 
                       dataSet[[targetStat]][dataSet$Condition == con2]) 
      sizeList[[testString]] <<- size["estimate"]
      print(size)

      #Calculate effect size (option 2)
      print("Using cohensD:")
      size2 <<- cohensD(dataSet[[targetStat]][dataSet$Condition == con1],
                        dataSet[[targetStat]][dataSet$Condition == con2])
      sizeList2[[testString]] <<- size2
      print(size2)

      numTest  <<- numTest + 1
        
    }
    
  
    if (inclControl) {
      tFunc("Control", "No Cues")
      tFunc("Control", "Collocated")
      tFunc("Control", "HUD")
      tFunc("Control", "Combined")
    }
    tFunc("No Cues", "Collocated")
    tFunc("No Cues", "HUD")
    tFunc("No Cues", "Combined")
    tFunc("Collocated", "HUD")
    tFunc("Collocated", "Combined")
    HCResult = tFunc("HUD", "Combined")
  

    print("-----------------------RESULTS-----------------------")
    resultsTable = data.frame(matrix(ncol = 9, nrow = 0))
    colnames(resultsTable) <- c("Test", "DFn", "DFd", "F", "GES/T-Value", "p value", "Corrected p threshold", "Result", "Effect Size")
    
    DFn = anova_result$ANOVA$DFn
    DFd = anova_result$ANOVA$DFd
    Fval = anova_result$ANOVA$F
    
    print(paste("Mauchly's Test for Sphericity passed:", mtsPass))
    
    roundGES = round(as.numeric(anova_result$ANOVA$ges)*1000)/1000
    
    if(mtsPass) {
      print(paste("Therefore use standard ANOVA values."))
      roundP = round(as.numeric(anova_result$ANOVA$p)*1000)/1000
      if(roundP < 0.001) {roundP = "<<0.001"}
      print(paste("P value of", roundP))
      print(paste("Degrees of freedom: ", DFn, ",", DFd))
      print(paste("F value of: ", Fval))
      print(paste("Generalized Eta-Squared (ges) of", roundGES))
      if (anova_result$ANOVA$p < pVal) {pf = "PASS"} else {pf = "FAIL"}
      print(paste("Statistical significance based on threshold of", pVal,":", pf))
      
    } else {
      print(paste("Therefore use Greenhouse-Geisser corrections."))
      roundP = round(as.numeric(anova_result$`Sphericity Corrections`$`p[GG]`)*1000)/1000
      if(roundP < 0.001) {roundP = "<<0.001"}
      print(paste("P value of", roundP))
      print(paste("Degrees of freedom: ", DFn, ",", DFd))
      print(paste("F value of: ", Fval))
      print(paste("Generalized Eta-Squared (ges) of", roundGES))
      if (anova_result$`Sphericity Corrections`$`p[GG]` < pVal) {pf = "PASS"} else {pf = "FAIL"}
      print(paste("Statistical significance based on threshold of", pVal,":", pf))
    }
    
    resultsTable[nrow(resultsTable) + 1,] = c("Overall", DFn, DFd, Fval, roundGES, roundP, pVal, pf, "N/A")
    
  
    p_threshold = round(1000*pVal/numTest)/1000
    print(paste("Bonferroni-corrected p value threshold based on default p value of ",pVal,"divided by", numTest,"tests is set at", p_threshold))
    
    for (test in 1:length(tList)) {
      roundT = round(as.numeric(tList[[test]])*1000)/1000
      roundP = round(as.numeric(pList[[test]])*1000)/1000
      effSizeRound = round(as.numeric(sizeList[[test]])*1000)/1000
      if(roundP < 0.001) {roundP = "<<0.001"}
      
      if(pList[[test]] < p_threshold) {pf = "PASS"} else {pf = "FAIL"}
      
      
      print(paste("Followup for", names(pList)[test],
                  "with t-value of",roundT,
                  ", degrees of freedom of", as.numeric(dfList[[test]]),
                  ", and p-value of",roundP,"=", pf, 
                  "; effect size: ", effSizeRound))
      
      resultsTable[nrow(resultsTable) + 1,] = c(names(pList)[[test]], as.numeric(dfList[[test]]), "N/A", "N/A", roundT, roundP, p_threshold, pf, effSizeRound)
    }
    
  }
  
  write.csv(resultsTable, paste0(textPath, ".csv"), row.names = TRUE)
  sink(file = NULL)
  
  
  
}