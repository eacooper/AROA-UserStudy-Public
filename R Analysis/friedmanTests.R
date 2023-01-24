# Runs Friedman test and followup Friedman or Wilcox tests on experimental condition Likert ratings.
# Output includes a text file with test results (if runTests = True) and a figure.

friedmanTests <- function (title, filepath, plotpath, dataSet, targetRating, runTests = TRUE, addJitter = FALSE) {
    
  #Title is the title of the test
  #Filepath is the filepath to save results to (text and CSV), e.g. "./Tests./Preferred./Likert Ratings_WorldPref_Median"
  #plotpath is the filepath to save plots to, e.g. "./Plots./Likert"
  #dataSet is the data set to use (typically dataSet)
  #targetRating = target rating (e.g. Median.Rating, Confidence, etc.) as string
  #runTests -> Runs tests if true, otherwise only graphs
  #addJitter -> Adds geom_jitter to graphs if true

  # Clear any outstanding sinks
  while (sink.number() > 0) {
    sink(file = NULL)
    print("Excess sink detected.")
  }
  
  print(paste("Friedman Test for",title))
  sink(file = paste0(filepath, ".txt")) # Start recording to a text file
  print(paste("Friedman Test for",title))
  

# Median Values -----------------------------------------------------------

  
  print("----------------MEDIAN VALUES----------------")

  # Calculate the mean, standard deviation, lower quantile, upper quantile, IQR, and maximum/minimum range for outliers.
  # (Max/min range = upper/lower quantile +/- 1.5*IQR)
  graph_Ratings <- ddply(dataSet %>% filter(Condition != "Control"), .(Condition), summarise,
                         med = median(get(targetRating)), sd = sd(get(targetRating)), 
                         lower = quantile(get(targetRating), 0.25), mid = quantile(get(targetRating), 0.5), 
                         upper = quantile(get(targetRating), 0.75), iqr = upper - lower, 
                         max_range = upper + 1.5*iqr, min_range = lower - 1.5*iqr)
  
  print(graph_Ratings)
  
  # Isolate rating, condition, and participant ID.
  tmp_rating <- dataSet[[targetRating]][dataSet$Condition != "Control"]
  tmp_cond <- dataSet$Condition[dataSet$Condition != "Control"]
  tmp_subj <- dataSet$Participant.ID[dataSet$Condition != "Control"]
  
  #Graphing values
  
  FigLikert <-  dataSet %>% filter(Condition != "Control") %>%  #Filter by non-Control conditions
    mutate(Condition = factor(Condition, levels=defaultOrder)) %>%  #Sets correct order
    ggplot(aes(x = Condition, y = get(targetRating), color = Condition))+  # Plot target rating by condition
    geom_hline(yintercept = 0, linetype = "dashed", color = "black", size = 0.5)+ #Draw line across a rating of 0
    geom_boxplot(outlier.shape = NA)+  #Put into boxplot shape, with no outliers
    theme(legend.position = 'none', axis.title.x = element_blank(), axis.text.x = element_text(size = 12), 
          axis.title.y = element_text(size = 12, face="plain"))+ #Adjust axis titles
    ggtitle(title)+ #Add title
    #geom_label(data = graph_Ratings, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)+  #Label medians
    scale_x_discrete(labels=c("Collocated" = "World", "HUD" = "Head"))+  #Label X axis
    scale_y_continuous(name=paste("Likert Scale Ratings", "(-3 to 3)"), limits = c(-3,3), breaks = c(-3, -2, -1, 0, 1, 2, 3))  #Set Y axis limits
  
  if (addJitter) {
    FigLikert <- FigLikert + geom_jitter(width = 0.15, height=0)  #Add data points with jitter
  }
  
  print("---------------------")
  print("Graph Data")  
  #print(ggplot_build(FigLikert)$data)  # Print graph info for bug checking
  
  #Print figure, save in multiple file formats
  print(FigLikert)
  ggsave(paste0(title,".svg"), path = plotpath)
  ggsave(paste0(title,".eps"), path = plotpath)
  ggsave(paste0(title,".png"), path = plotpath)
  

# Run Tests ---------------------------------------------------------------

  
  if(runTests) {
    
    # Create an empty results table and name the columns
    resultsTable = data.frame(matrix(ncol = 7, nrow = 0))
    colnames(resultsTable) <- c("Test", "Test Statistic (V or Chi)", "p value", "Corrected p threshold", "Result", "Effect Size", "Effect Magnitude")
    

# Single Sample Wilcoxon Signed-Rank --------------------------------------

    
    print("")
    print("----------------Single Sample Wilcoxon Signed-Rank Tests----------------")
    print("Comparing conditions to a value of 0, representing Control.")
    
    # Set empty lists. SS stands for Single Sample to differentiate from followup tests below.
    SSnameList = list() # Names
    SSvList = list() # V values
    SSpList = list() # P values
    SSeffSizeList = list() # Effect sizes
    SSeffMagList = list() # Effect magnitudes
    
    # Run Wilcox Signed Rank test
    # Uses function to be able to pass each of the four cue conditions 
    wilcoxSignedRank  <- function(condition) {
      
      print(paste("Wilcox Signed Rank test for", condition))
      testString = paste(condition, "vs 0")
      
      
      # Run wilcoxon test for the designated rating and condition.
      wilcoxResult = wilcox.test(dataSet[[targetRating]][dataSet$Condition == condition], mu = 0, alternative = "two.sided")
      print(wilcoxResult)
      
      # Get V value.
      wilcoxV = wilcoxResult$statistic
      
      # Create a rounded, print-friendly value for p.
      roundWilcox = round(as.numeric(wilcoxResult$p.value)*10000)/10000
      if(roundWilcox < 0.001) {
        roundWilcox = "<<0.001"
      }
      
      # Check p-value pass or fail
      if(as.numeric(wilcoxResult$p.value) < pVal) {
        pfWilcox = "PASS"
      } else {
        pfWilcox = "FAIL"
      }
      
      # Effect size
      effSize = qnorm((as.numeric(wilcoxResult$p.value))/2)/sqrt(length(tmp_cond)/2) * (-1)
      effSizeRound = round(as.numeric(effSize)*1000)/1000
      
      #Determine effect magnitude
      if (effSize < 0.3)
        effMag = "small"
      else if (effSize < 0.5)
        effMag = "medium"
      else
        effMag = "large"
      
      # Add test values to lists
      SSnameList[[testString]] <<- testString
      SSvList[[testString]] <<- wilcoxResult["statistic"]
      SSpList[[testString]] <<- wilcoxResult["p.value"]
      SSeffSizeList[[testString]] <<- effSizeRound
      SSeffMagList[[testString]] <<- effMag
      
      # Print result 
      testString = paste0(condition, ": V = ", wilcoxV, "; p-value = ", roundWilcox, "; result: ", 
                          pfWilcox, "; effect size: ", effSizeRound, "; effect magnitude: ", effMag)
      print(testString)
      print("")
      return(testString) #Save results strings to print at bottom
    }
    
    # Run tests for each condition.
    WSR_NoCues = wilcoxSignedRank("No Cues")
    WSR_Collocated = wilcoxSignedRank("Collocated")
    WSR_HUD = wilcoxSignedRank("HUD")
    WSR_Combined = wilcoxSignedRank("Combined")
    
    #Add to results table
    for (test in 1:length(SSvList)) {
      # For each test, calculate a rounded value for V and p 
      SSroundV = round(as.numeric(SSvList[[test]])*1000)/1000
      SSroundP = round(as.numeric(SSpList[[test]])*1000)/1000
      if(SSroundP < 0.001) {SSroundP = "<<0.001"}
      
      # Check if the p value is a pass or fail
      if(SSpList[[test]] < pVal) {SSpf = "PASS"} else {SSpf = "FAIL"}
      
      # Declare effect size & magnitude
      SSeffSize = SSeffSizeList[[test]]
      SSeffMag = SSeffMagList[[test]]
      
      # Add results to results table
      resultsTable[nrow(resultsTable) + 1,] = c(names(SSvList)[[test]], SSroundV, SSroundP, pVal, SSpf, SSeffSize, SSeffMag)
    }

    
# Omnibus -----------------------------------------------------------------


    print("----------------OMNIBUS TEST----------------")
    
    # Run omnibus friedman test, create rounded values and test pass/fail.
    print("Omnibus Friedman Test")
    friedmanAll = (friedman.test(tmp_rating,tmp_cond,tmp_subj))
    print(friedmanAll)
    
    # Round results, check if pass or fail
    roundChiOmnibus = round(as.numeric(friedmanAll[["statistic"]])*10000)/10000
    roundPOmnibus = round(as.numeric(friedmanAll[["p.value"]])*10000)/10000
    if(roundPOmnibus < 0.001) {roundPOmnibus = "<<0.001"}
    if(as.numeric(friedmanAll[["p.value"]]) < pVal) {pfOmnibus = "PASS"} else {pfOmnibus = "FAIL"}
    
    # Add a row to the results table for the omnibus results
    resultsTable[nrow(resultsTable) + 1,] = c("Omnibus", roundChiOmnibus, roundPOmnibus, pVal, pfOmnibus, "N/A", "N/A")
    

# Followup ----------------------------------------------------------------

    
    print("----------------FOLLOWUP TESTS----------------")
    
    # do pairwise follow up tests
    # Replaced with paired sample Wilcoxon tests, removing No Cues
    print(paste0("Followup tests using Wilcoxon"))
    
    # Set test counter and empty lists
    numTest = 0
    nameList = list() # Names
    vList = list() # Chi Squared values
    pList = list() # P values
    #fList = list() # 
    effSizeList = list() # Effect sizes
    effMagList = list() # Effect magnitudes
    

    wFunc <- function(con1, con2) {
      # Create a custom test string
      testString = paste(con1, "vs", con2)
      print(testString)
      
      # Run wilcoxon test
      test <<- wilcox.test(tmp_rating[tmp_cond == con1], tmp_rating[tmp_cond == con2], paired = TRUE, alternative = "two.sided")
      print(test)
      
      # Calculate effect size
      effSize = qnorm((as.numeric(test["p.value"]))/2)/sqrt(length(tmp_cond)/2) * (-1)
      effSizeRound = round(as.numeric(effSize)*1000)/1000
      
      #Determine magnitude
      if (effSize < 0.3)
        effMag = "small"
      else if (effSize < 0.5)
        effMag = "medium"
      else
        effMag = "large"
      
      print(paste("Wilcoxon effect size:", effSizeRound))
      
      # Add test values to lists and increment test counter
      nameList[[testString]] <<- testString
      vList[[testString]] <<- test["statistic"]
      pList[[testString]] <<- test["p.value"]
      #fList[["Chi"]][[testString]] <<- test["statistic"]
      #fList[["P"]][[testString]] <<- test["p.value"]
      effSizeList[[testString]] <<- effSizeRound
      effMagList[[testString]] <<- effMag
      
      numTest <<- numTest + 1
    }
    
    # Run tests for desired condition comparisons
    wFunc("Collocated", "HUD")
    wFunc("Collocated", "Combined")
    wFunc("HUD", "Combined")
    

# Results -----------------------------------------------------------------


    
    print("----------------RESULTS----------------")
    print("SIGNED-RANK WILCOXON")
    print("Evaluated against p threshold of 0.05.")
    # Print results for each test
    print(WSR_NoCues)
    print(WSR_Collocated)
    print(WSR_HUD)
    print(WSR_Combined)

    print("-----")
    print("OMNIBUS")
    #Omnibus Test and Followups
    print(paste("Omnibus test with chi-squared value of", roundChiOmnibus, "and p-value of",roundPOmnibus,"tested against default p value", pVal,". Result =", pfOmnibus))
    
    print("-----")
    print("FOLLOWUPS")
    # p value threshold for 3 following, using bonferroni correction"
    p_threshold = round(1000*pVal/numTest)/1000
    print(paste("Bonferroni-corrected p value threshold based on default p value of ",pVal,"divided by", numTest,"tests is set at", p_threshold))
    
    for (test in 1:length(vList)) {
      # For each test, calculate a rounded value for Chi and p 
      roundV = round(as.numeric(vList[[test]])*1000)/1000
      roundP = round(as.numeric(pList[[test]])*1000)/1000
      if(roundP < 0.001) {roundP = "<<0.001"}
      
      # Check if the p value is a pass or fail
      if(pList[[test]] < p_threshold) {pf = "PASS"} else {pf = "FAIL"}
      
      # Declare effect size & magnitude
      effSize = effSizeList[[test]]
      effMag = effMagList[[test]]
      
      # Print followup information and add to results table
      print(paste("Followup for", names(vList)[test],"with V value of",roundV,"and p-value of",roundP,"=", pf, 
                  "; Effect size:", effSize, "Magnitude: ", effMag))
      resultsTable[nrow(resultsTable) + 1,] = c(names(vList)[[test]], roundV, roundP, p_threshold, pf, effSize, effMag)
      
    }
    
    # Write results to CSV
    write.csv(resultsTable, paste0(filepath, ".csv"), row.names = TRUE)
    
  }
  
  # Stop logging to text file
  sink(file = NULL)
  
}