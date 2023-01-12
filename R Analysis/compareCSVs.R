compareCSVs <- function(path1, path2, outputPath) {
  
  # For each CSV in path1, finds the matching one(s) in path 2 and compares them
  # Stores results in a new CSV in outputPath
  # Designed to compare typical results against low and high acuity
  
  # Get lists of files
  files1 <- list.files(path = path1, pattern = ".csv")
  files2 <- list.files(path = path2, pattern = ".csv")
  
  #Instantiate list of differences
  diffList = list()

  #Create new text file to hold summary of differences
  outputFilePath = paste0(outputPath, "/", "Comparison Summary.txt")
  outputFile <- file(outputFilePath, "w")
  summaryText = "Summary of differences:"
  writeLines("Summary of differences: ", outputFile)
  
  #Iterate through files
  for (file1 in 1:length(files1)) {
    # For each file in file 1, find corresponding ones in files2
    # i.e. ones whose text is the same before the first underscore
    # Note that Likert ratings look like "Likert Ratings Control_Awareness" in files1
      # and "Likert Ratings Control_HighAcuity_Awareness" in files2
      # so additional measures are needed
    
    #Remove ".csv" from end of files
    baseName1 <- sub(".csv", "", files1[file1])
    
    #Instantiate list of matches
    matches <- list()
    
    for (file2 in 1:length(files2)) {
      #Check which files in path2 match
      if (grepl("Likert", files2[file2], fixed=TRUE)) {
        #For Likert ratings, remove High or Low Acuity and see if it matches
        baseName2 <- sub("HighAcuity_", "", files2[file2])
        baseName2 <- sub("LowAcuity_", "", baseName2)
      }
      else {
        #Otherwise just remove everything before the first underscore
        baseName2 <- sub('\\_.*', "", files2[file2])
      }
      #Remove ".csv" if it's still there
      baseName2 <- sub(".csv", "", baseName2)

      
      if (baseName1 == baseName2) {
        #Add to list of matches
        matches <- append(matches, files2[file2])
  
      }
    }

    #If there are no matches, do nothing
    if(length(matches > 0)) {
      
      #Add descriptor to data from file1
      data1 = read.csv(paste0(path1, "/", toString(files1[file1])))
      data1$category = c("Default")
      
      #Create new table based on data1
      comparisonData <- data1
      
      #Grab results from data1
      results1 = data1$Result
      
      #Add descriptors to data from file2
      for (m in 1:length(matches)) {
        #Access data
        data2 = read.csv(paste0(path2, "/", toString(matches[m])))
        
        if (grepl("High", toString(matches[m])))
          descriptor = "High Acuity"
        else
          descriptor = "Low Acuity"
        
        data2$category = c(descriptor)
        
        #Add to table
        comparisonData <- rbind(comparisonData, data2)
        
        comparisonList <- data1$Result == data2$Result #Will return e.g. "TRUE FALSE FALSE..." if first matches but not second and third
        #Check results against data1; if there are any differences, note them
        if (!all(comparisonList)){  #Checks for any differences
          #diffList <- append(diffList, toString(matches[m])) 
          
          writeLines(paste(toString(files1[file1]),"vs", toString(matches[m])), outputFile)
          
          for(n in 1:length(comparisonList)) {
            if(!comparisonList[n]) {
              writeLines(paste(toString(data1$Test[n]), data1$Result[n], "to", data2$Result[n]), outputFile)
            }
          }
          writeLines("", outputFile)
        }
          
      }
      
      # Write comparison data to new CSV
      write.csv(comparisonData, paste0(outputPath, "/", files1[file1]), row.names = TRUE)
      
    }

    
  }
  

  
  # if (length(diffList > 0)) {
  #   for (d in 1:length(diffList)) {
  #     writeLines(toString(diffList[d]), outputFile)
  #   }
  #     
  # }
  # else {
  #   writeLines("No differences found.", outputFile)
  # }
  
  close(outputFile)
  
}