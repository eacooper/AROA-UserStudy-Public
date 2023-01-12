# Setup -----------------------------
# load libraries for plotting
# install.packages("groundhog")
# install.packages("ez")
# install.packages("rlang")
# install.packages("tidyverse")
# install.packages("gridExtra")
# install.packages("svglite")
# install.packages("ggpubr")


# may not need all these these packages, but loading them now for simplicity
library(ez)
library(plyr)
library(dplyr)
library(rlang)
library(tidyverse)
library(gridExtra)
library(ggplot2)
library(svglite)
library(ggpubr)

source("friedmanTests.R")
source("friedmanControl.R")
source("plotAndAnova.R")


# load in data
Data = read.csv("AROA Main Study 2_Participant Tracking - Experiment Data_8-10-22.csv",header=T)

#Remove percentage signs in PPWS, commas in rotation
Data$PPWS <- gsub("%", "", Data$PPWS)
Data$X.Pitch <- gsub(",", "", Data$X.Pitch)
Data$Y.Yaw <- gsub(",", "", Data$Y.Yaw)
Data$Z.Roll <- gsub(",", "", Data$Z.Roll)
Data$Total.Rotation <- gsub(",", "", Data$Total.Rotation)

#Replace N/A in data columns with 9999
Data$Calibrated.Distance <- gsub("N/A", "9999", Data$Calibrated.Distance)
Data$Average.Speed <- gsub("N/A", "9999", Data$Average.Speed)
Data$X.Pitch <- gsub("N/A", "9999", Data$X.Pitch)
Data$Y.Yaw <- gsub("N/A", "9999", Data$Y.Yaw)
Data$Z.Roll <- gsub("N/A", "9999", Data$Z.Roll)
Data$Total.Rotation <- gsub("N/A", "9999", Data$Total.Rotation)

# fix Likert range to go from -3 to 3 for experimental conditions
Data$Median.Rating[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] = 
  Data$Median.Rating[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] - 4

Data$Confidence[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] = 
  Data$Confidence[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] - 4

Data$Obstacle.location[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] = 
  Data$Obstacle.location[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] - 4

Data$Obstacle.size[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] = 
  Data$Obstacle.size[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] - 4

Data$Awareness[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] = 
  Data$Awareness[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] - 4


# Define Data Sets ---------------------------------------------
# Data: whole dataset. Percent signs and commas removed, Likert scores for experimental conditions correct from 1:7 to -3:3
# Data_avg: forward and backward runs combined
# Data_avg_noErr: as above but with the two excluded participants filtered out, and all made numeric
# Data_noErr: as Data but with two excluded participants filtered out, all made numeric (primarily used for forward/backward testing)


# Average forward and backward runs

Data_avg <- Data

for (x in 1:nrow(Data)) {
  #print(typeof(Data$Calibrated.Time[x]))
  #print(is.numeric(Data$Calibrated.Time[x]))
  #print(is.numeric(Data$Calibrated.Time[x]) & (is.numeric(Data$Calibrated.Time[x+1])))
  
  if (Data$Forward.or.Backward[x] == "Forward") {
    
    # Mark row as "combined"
    Data_avg$Forward.or.Backward[x] = "Combined"
    
    #First average values that are present for control and experimental conditions: Calibrated Time, PPWS, Errors
    #Use as.numeric because many vars are considered character because of a few N/As
    
    if (is.na(Data$Calibrated.Time[x]) || (is.na(Data$Calibrated.Time[x+1]))) {
      #If forward or backward run is marked as NAN, then apply that to all elements
      
      #print(paste("Error discovered at row", x))
      Data_avg$Calibrated.Time[x] = "Excluded"
      Data_avg$PPWS[x] = "Excluded"
      Data_avg$Errors[x] = "Excluded"
      Data_avg$Calibrated.Distance[x] = "Excluded"
      Data_avg$Average.Speed[x] = "Excluded"
      Data_avg$X.Pitch[x] = "Excluded"
      Data_avg$Y.Yaw[x] = "Excluded"
      Data_avg$Z.Roll[x] = "Excluded"
      Data_avg$Total.Rotation[x] = "Excluded"
      
      
    } else { 
    
      #Calibrated Time
      Data_avg$Calibrated.Time[x] = mean(c(Data$Calibrated.Time[x], Data$Calibrated.Time[x + 1]))
      #print(paste("Calibrated Time for row",x, "set at", Data_avg$Calibrated.Time[x]))
      
      
      #PPWS (Percentage of Preferred Walking Speed)
      Data_avg$PPWS[x] = mean(c(as.numeric(Data$PPWS[x]), as.numeric(Data$PPWS[x + 1])))
      
      #Errors
      Data_avg$Errors[x] = mean(c(Data$Errors[x], Data$Errors[x + 1]))
      
      #Now do ones that are only for experimental
      if (Data_avg$Condition[x] != "Control (first)" & Data_avg$Condition[x] != "Control (last)") {
        
        #Calibrated Distance
        Data_avg$Calibrated.Distance[x] = mean(c(as.numeric(Data$Calibrated.Distance[x]), as.numeric(Data$Calibrated.Distance[x + 1])))
        
        #Average Speed
        Data_avg$Average.Speed[x] = mean(c(as.numeric(Data$Average.Speed[x]), as.numeric(Data$Average.Speed[x + 1])))
        
        #Rotation
        Data_avg$X.Pitch[x] = mean(c(as.numeric(Data$X.Pitch[x])), as.numeric(Data$X.Pitch[x + 1]))
        Data_avg$Y.Yaw[x] = mean(c(as.numeric(Data$Y.Yaw[x]), as.numeric(Data$Y.Yaw[x + 1])))
        Data_avg$Z.Roll[x] = mean(c(as.numeric(Data$Z.Roll[x]), as.numeric(Data$Z.Roll[x + 1])))
        Data_avg$Total.Rotation[x] = mean(c(as.numeric(Data$Total.Rotation[x]), as.numeric(Data$Total.Rotation[x + 1])))
      }
    }
  } 
}

#Remove backward runs, leaving only forward
Data_avg <- Data_avg %>% filter(Forward.or.Backward == "Combined")

#write.csv(Data_avg,"Data_avg_pre-Control avg.csv", row.names = TRUE)

#We're also averaging the Control (first) and Control (last) conditions
for (x in 1:nrow(Data_avg)) {
  if (Data_avg$Condition[x] == "Control (first)") {
    #print(paste("At x =", x, "Data_avg$Condition[x] =", Data_avg$Condition[x]))
    
    # Mark row as "Control"
    Data_avg$Condition[x] = "Control"
    
    #The corresponding "last" row should be 5 rows down
    #Check to make sure it has the same participant ID
    if (Data_avg$Participant.ID[x] != Data_avg$Participant.ID[x + 5]) {
      warning("Participant ID mismatch between control (first) and control (last)") 
      print(paste("Participant ID at warning:", Data_avg$Participant.ID[x]))
    }
    
    lastX = x + 5
    #print(paste("When x is", x, "last x is", lastX))
    
    #Assign average values of control (first) and control (last)
    
    #Calibrated Time
    #print(paste("Averaging control times: old times for participant", Data_avg$Participant.ID[x],"are", Data_avg$Calibrated.Time[x],"for first and", Data_avg$Calibrated.Time[lastX],"for last."))
    Data_avg$Calibrated.Time[x] = mean(c(as.numeric(Data_avg$Calibrated.Time[x]), as.numeric(Data_avg$Calibrated.Time[lastX])))
    #print(paste("New time is", Data_avg$Calibrated.Time[x]))
    
    
    #PPWS (Percentage of Preferred Walking Speed)
    Data_avg$PPWS[x] = mean(c(as.numeric(Data_avg$PPWS[x]), as.numeric(Data_avg$PPWS[lastX])))
    
    #Errors
    Data_avg$Errors[x] = mean(c(as.numeric(Data_avg$Errors[x]), as.numeric(Data_avg$Errors[lastX])))
    
    #Likert ratings (take median)
    Data_avg$Median.Rating[x] = median(c(Data_avg$Median.Rating[x], Data_avg$Median.Rating[lastX]))
    Data_avg$Confidence[x] = median(c(Data_avg$Confidence[x], Data_avg$Confidence[lastX]))
    Data_avg$Obstacle.location[x] = median(c(Data_avg$Obstacle.location[x], Data_avg$Obstacle.location[lastX]))
    Data_avg$Obstacle.size[x] = median(c(Data_avg$Obstacle.size[x], Data_avg$Obstacle.size[lastX]))
    Data_avg$Awareness[x] = median(c(Data_avg$Awareness[x], Data_avg$Awareness[lastX]))
    
    }
}

#Remove control (last) runs, leaving only control and experimental conditions
Data_avg <- Data_avg %>% filter(Condition != "Control (last)")

#Write to a spreadsheet to verify
write.csv(Data_avg,"Data_avg.csv", row.names = TRUE)


#also create a version with no NaN
#Note that below removed only Excluded conditions; to make analysis more straightforward, we just remove OA07 and OA11 entirely
#Data_avg_noErr <- Data_avg %>% filter(Calibrated.Time != "Excluded")
Data_avg_noErr <- Data_avg %>% filter(Participant.ID != "OA07" & Participant.ID != "OA11")

#Need to make these numeric. Time, PPWS, and Errors can be for all conditions 
Data_avg_noErr$Calibrated.Time <- as.numeric(Data_avg_noErr$Calibrated.Time)
Data_avg_noErr$PPWS <- as.numeric(Data_avg_noErr$PPWS)
Data_avg_noErr$Errors <- as.numeric(Data_avg_noErr$Errors)

Data_avg_noErr$Calibrated.Distance <- as.numeric(Data_avg_noErr$Calibrated.Distance)
Data_avg_noErr$Average.Speed <- as.numeric(Data_avg_noErr$Average.Speed)
Data_avg_noErr$X.Pitch <- as.numeric(Data_avg_noErr$X.Pitch)
Data_avg_noErr$Y.Yaw <- as.numeric(Data_avg_noErr$Y.Yaw)
Data_avg_noErr$Z.Roll <- as.numeric(Data_avg_noErr$Z.Roll)
Data_avg_noErr$Total.Rotation <- as.numeric(Data_avg_noErr$Total.Rotation)

write.csv(Data_avg_noErr, "Data_avg_noErr.csv", row.names = TRUE)

# Data_noErr
# We need to verify that forward and backward distance is not different for different conditions
# Unfortunately this means essentially making a "data_avg_noErr" for the full data set
Data_noErr <- Data %>% filter(Participant.ID != "OA07" & Participant.ID != "OA11")
Data_noErr$Calibrated.Time <- as.numeric(Data_noErr$Calibrated.Time)
Data_noErr$PPWS <- as.numeric(Data_noErr$PPWS)
Data_noErr$Errors <- as.numeric(Data_noErr$Errors)

Data_noErr$Calibrated.Distance <- as.numeric(Data_noErr$Calibrated.Distance)
Data_noErr$Average.Speed <- as.numeric(Data_noErr$Average.Speed)
Data_noErr$X.Pitch <- as.numeric(Data_noErr$X.Pitch)
Data_noErr$Y.Yaw <- as.numeric(Data_noErr$Y.Yaw)
Data_noErr$Z.Roll <- as.numeric(Data_noErr$Z.Roll)
Data_noErr$Total.Rotation <- as.numeric(Data_noErr$Total.Rotation)

write.csv(Data_noErr, "Data_noErr.csv", row.names = TRUE)



# Clear any outstanding sinks
while (sink.number() > 0) {
  sink(file = NULL)
  print("Excess sink detected.")
}

#Set default order
defaultOrder = c("Control", "No Cues", "Collocated", "HUD", "Combined")

#Set default p value
pVal = 0.05

# Likert Ratings --------------------------------------------------------------------------------------------------------------------------

# #Graph of control condition likert responses
 Data_ctrl <- Data %>% filter((Condition == "Control (first)" | Condition == "Control (last)") & Forward.or.Backward == "Forward") 
# 
# # do the same for control condition
# graph_Ratings_ctrl <- ddply(Data_ctrl, .(Condition), summarise, med = median(Median.Rating))
# 
# FigLikertCtrl <-  Data_ctrl %>%
#   #mutate(Condition = factor(Condition, levels=defaultOrder)) %>%
#   ggplot(aes(x = Condition, y = Median.Rating, color = Condition))+
#   geom_boxplot(outlier.shape = NA)+
#   #geom_jitter(width = 0.15, height = 0)+
#   theme(legend.position = 'none')+
#   ggtitle("Median Likert Ratings for Control Conditions (1 to 7)")
#   #geom_label(data = graph_Ratings_ctrl, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)
# 
# print(FigLikertCtrl)
# ggsave(paste0(title,".svg"), path = "./Plots./Likert")
# ggsave(paste0(title,".eps"), path = "./Plots./Likert")
# ggsave(paste0(title,".png"), path = "./Plots./Likert")

friedmanControl("Control Median Ratings", "./Tests./Likert Ratings Control_Median", Data_ctrl, "Median.Rating", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Confidence Ratings", "./Tests./Likert Ratings Control_Confidence", Data_ctrl, "Confidence", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Location", "./Tests./Likert Ratings Control_Obstacle Location", Data_ctrl, "Obstacle.location", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Size Ratings", "./Tests./Likert Ratings Control_Obstacle Size", Data_ctrl, "Obstacle.size", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Awareness Ratings", "./Tests./Likert Ratings Control_Awareness", Data_ctrl, "Awareness", "runTests" = TRUE, "addJitter" = FALSE)


# Single Sample Wilcoxon Signed-Rank Test - No Cues vs. Control
# This determines whether No Cues is significantly different than 0 (control)
# Baked into friedmanTests


#Run plots and Friedman Tests from a separate R script
friedmanTests("Median Ratings", "./Tests./Likert Ratings_Median", Data_avg, "Median.Rating", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Confidence Ratings", "./Tests./Likert Ratings_Confidence", Data_avg, "Confidence", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Obstacle Location Ratings",  "./Tests./Likert Ratings_Obstacle Location", Data_avg, "Obstacle.location", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Obstacle Size Ratings", "./Tests./Likert Ratings_Obstacle Size", Data_avg, "Obstacle.size", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Awareness Ratings", "./Tests./Likert Ratings_Awareness", Data_avg, "Awareness", "runTests" = TRUE, "addJitter" = FALSE)


# Quantitative Data -------------------------------------------------------


#TIME
plotAndAnova("Time by Condition", "./Tests./Time", "./Plots./Time", Data_avg_noErr, TRUE, "Calibrated.Time", "Time (s)", c(10,40))

#PPWS
plotAndAnova("PPWS by Condition", "./Tests./PPWS", "./Plots./PPWS", Data_avg_noErr, TRUE, "PPWS", "Percentage of Preferred Walking Speed")

#ERRORS
plotAndAnova("Errors by Condition", "./Tests./Errors", "./Plots./Errors", Data_avg_noErr, TRUE, "Errors", "Number of Errors")

#DISTANCE
plotAndAnova("Distance by Condition", "./Tests./Distance", "./Plots./Distance", 
             Data_avg_noErr, FALSE, "Calibrated.Distance", "Total Distance Walked (m)", c(15, 17))



#Plot distance for forward only
graph_distance_forward <- ddply(Data_noErr %>% filter(Forward.or.Backward == "Forward" & Condition != "Control (first)" & Condition != "Control (last)"), 
                                .(Condition), summarise, mean = mean(Calibrated.Distance))

FigDistanceForward <-  Data_noErr %>% filter(Forward.or.Backward == "Forward" & Condition != "Control (first)" & Condition != "Control (last)") %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = Calibrated.Distance, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15, height = 0)+
  theme(legend.position = 'none')+
  expand_limits(y = c(15,20))+
  ggtitle("Distance by Condition - Forward Only")+
  geom_label(data = graph_distance_forward, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total Distance Travelled (m)")

print(FigDistanceForward)

#Plot distance for backward only
graph_distance_backward <- ddply(Data_noErr %>% filter(Forward.or.Backward == "Backward" & Condition != "Control (first)" & Condition != "Control (last)"), 
                                .(Condition), summarise, mean = mean(Calibrated.Distance))

FigDistanceBackward <-  Data_noErr %>% filter(Forward.or.Backward == "Backward" & Condition != "Control (first)" & Condition != "Control (last)") %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = Calibrated.Distance, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15, height = 0)+
  theme(legend.position = 'none')+
  expand_limits(y = c(15,20))+
  ggtitle("Distance by Condition - Backward Only")+
  geom_label(data = graph_distance_backward, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total Distance Travelled (m)")

print(FigDistanceBackward)


#AVERAGE SPEED
plotAndAnova("Average Speed by Condition", "./Tests./Speed", "./Plots./Speed", Data_avg_noErr, FALSE, "Average.Speed", "Average Speed (m/s)")


#ROTATION

#X Rotation (Pitch)
plotAndAnova("X Rotation (Pitch)", "./Tests./Rotation X", "./Plots./Rotation", 
             Data_avg_noErr, FALSE, "X.Pitch", "Absolute Rotation (degrees)", c(NA, 1000))

#Y Rotation (Yaw)
plotAndAnova("Y Rotation (Yaw)", "./Tests./Rotation Y", "./Plots./Rotation", 
             Data_avg_noErr, FALSE, "Y.Yaw", "Absolute Rotation (degrees)", c(NA, 600))

#Z Rotation (Roll)
plotAndAnova("Z Rotation (Roll)", "./Tests./Rotation Z", "./Plots./Rotation", 
             Data_avg_noErr, FALSE, "Z.Roll", "Absolute Rotation (degrees)", c(NA, 750))

#Total Rotation
plotAndAnova("Total Rotation", "./Tests./Rotation Total", "./Plots./Rotation", 
             Data_avg_noErr, FALSE, "Total.Rotation", "Absolute Rotation (degrees)", c(NA, 2250))






#Preferred Conditions Only ------------------------

#Filter data (Likert)
Data_avg_Pref <- Data_avg %>% filter(Condition == "Control" | Condition == "No Cues" | Preferred.Condition == "Yes")

#Likert Ratings
friedmanTests("Median Ratings_Preferred", "./Tests./Likert Ratings_Preferred_Median", Data_avg_Pref, "Median.Rating", "runTests" = FALSE, "addJitter" = TRUE)
friedmanTests("Confidence Ratings_Preferred", "./Tests./Likert Ratings_Preferred_Confidence", Data_avg_Pref, "Confidence", "runTests" = FALSE, "addJitter" = TRUE)
friedmanTests("Obstacle Location Ratings_Preferred", "./Tests./Likert Ratings_Preferred_Obstacle Location", Data_avg_Pref, "Obstacle.location", "runTests" = FALSE, "addJitter" = TRUE)
friedmanTests("Obstacle Size Ratings_Preferred", "./Tests./Likert Ratings_Preferred_Obstacle Size", Data_avg_Pref, "Obstacle.size","runTests" = FALSE, "addJitter" = TRUE)
friedmanTests("Awareness Ratings_Preferred", "./Tests./Likert Ratings_Preferred_Awareness", Data_avg_Pref, "Awareness", "runTests" = FALSE, "addJitter" = TRUE)


#Filter data (Quant)
Data_avg_noErr_Pref <- Data_avg_noErr %>% filter(Condition == "Control" | Condition == "No Cues" | Preferred.Condition == "Yes")

#Time
plotAndAnova("Time by Condition_Preferred", "./Tests./Time_Preferred", "./Plots./Time", Data_avg_noErr_Pref, TRUE, "Calibrated.Time", "Time (s)", c(10,40), "runTests" = FALSE, "addJitter" = TRUE)

#PPWS
plotAndAnova("PPWS by Condition_Preferred", "./Tests./PPWS_Preferred", "./Plots./PPWS", Data_avg_noErr_Pref, TRUE, "PPWS", "Percentage of Preferred Walking Speed", "runTests" = FALSE, "addJitter" = TRUE)

#Errors
plotAndAnova("Errors by Condition_Preferred", "./Tests./Errors_Preferred", "./Plots./Errors", Data_avg_noErr_Pref, TRUE, "Errors", "Number of Errors", "runTests" = FALSE, "addJitter" = TRUE)


#Distance
plotAndAnova("Distance by Condition_Preferred", "./Tests./Distance_Preferred", "./Plots./Distance", 
             Data_avg_noErr_Pref, FALSE, "Calibrated.Distance", "Total Distance Walked (m)", c(15, 17), "runTests" = FALSE, "addJitter" = TRUE)

#Average Speed
plotAndAnova("Average Speed by Condition_Preferred", "./Tests./Speed_Preferred", "./Plots./Speed", 
             Data_avg_noErr_Pref, FALSE, "Average.Speed", "Average Speed (m/s)", "runTests" = FALSE, "addJitter" = TRUE)

#Rotation

#X Rotation (Pitch)
plotAndAnova("X Rotation (Pitch)_Preferred", "./Tests./Rotation X_Preferred", "./Plots./Rotation", 
             Data_avg_noErr_Pref, FALSE, "X.Pitch", "Absolute Rotation (degrees)", c(NA, 1000), "runTests" = FALSE, "addJitter" = TRUE)

#Y Rotation (Yaw)
plotAndAnova("Y Rotation (Yaw)_Preferred", "./Tests./Rotation Y_Preferred", "./Plots./Rotation", 
             Data_avg_noErr_Pref, FALSE, "Y.Yaw", "Absolute Rotation (degrees)", c(NA, 600), "runTests" = FALSE, "addJitter" = TRUE)

#Z Rotation (Roll)
plotAndAnova("Z Rotation (Roll)_Preferred", "./Tests./Rotation Z_Preferred", "./Plots./Rotation", 
             Data_avg_noErr_Pref, FALSE, "Z.Roll", "Absolute Rotation (degrees)", c(NA, 750), "runTests" = FALSE, "addJitter" = TRUE)

#Total Rotation
plotAndAnova("Total Rotation_Preferred", "./Tests./Rotation Total_Preferred", "./Plots./Rotation", 
             Data_avg_noErr_Pref, FALSE, "Total.Rotation", "Absolute Rotation (degrees)", c(NA, 2250), "runTests" = FALSE, "addJitter" = TRUE)


#UNUSED CODE -----------------------

#Friedman tests with question as title

# q1 = "I felt more confident in my ability to navigate this hallway compared to when I was not wearing the HoloLens."
# q2 = "It was easier to figure out where each obstacle was compared to when I was not wearing the HoloLens."
# q3 = "It was harder to tell how big each obstacle was compared to when I was not wearing the HoloLens."
# q4 = "I felt more aware of my surroundings while navigating the hallway compared to when I was not wearing the HoloLens."
# friedmanTests("Median Ratings", "Median Ratings", "./Tests./Likert Ratings_Median", Data_avg, "Median.Rating", "runTests" = TRUE, "addJitter" = FALSE)
# friedmanTests("Confidence Ratings", q1, "./Tests./Likert Ratings_Confidence", Data_avg, "Confidence", "runTests" = TRUE, "addJitter" = FALSE)
# friedmanTests("Obstacle Location Ratings", q2, "./Tests./Likert Ratings_Obstacle Location", Data_avg, "Obstacle.location", "runTests" = TRUE, "addJitter" = FALSE)
# friedmanTests("Obstacle Size Ratings", q3, "./Tests./Likert Ratings_Obstacle Size", Data_avg, "Obstacle.size", "runTests" = TRUE, "addJitter" = FALSE)
# friedmanTests("Awareness Ratings", q4, "./Tests./Likert Ratings_Awareness", Data_avg, "Awareness", "runTests" = TRUE, "addJitter" = FALSE)





# #Plot total time by participant ID to find outliers

# graph_distByID <- ddply(Data_avg_noErr, .(Participant.ID), summarise, mean = mean(Calibrated.Time))
# 
# figTimeByID <-  Data_avg_noErr %>%
#   #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
#   ggplot(aes(x = Participant.ID, y = Calibrated.Time, color = Participant.ID))+
#   geom_point()+
#   #geom_jitter(width = 0.15)+
#   theme(legend.position = 'none')+
#   ggtitle("Time by Participant ID")+
#   #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
#   scale_y_continuous(name="Time (s)")
# 
# print(figTimeByID)




# #Plot total distance by participant ID to find outliers

# graph_distByID <- ddply(Data_exp, .(Participant.ID), summarise, mean = mean(Calibrated.Distance))
# 
# figDistByID <-  Data_exp %>%
#   #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
#   ggplot(aes(x = Participant.ID, y = Calibrated.Distance, color = Participant.ID))+
#   geom_point()+
#   #geom_jitter(width = 0.15)+
#   theme(legend.position = 'none')+
#   ggtitle("Distance Travelled by Participant ID")+
#   #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
#   scale_y_continuous(name="Distance travelled (m)")
# 
# print(figDistByID)

# #Plot total rotation by participant ID to find outliers

# graph_RotByID <- ddply(Data_exp, .(Participant.ID), summarise, mean = mean(Total.Rotation))
# 
# figRotByID <-  Data_exp %>%
#   #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
#   ggplot(aes(x = Participant.ID, y = Total.Rotation, color = Participant.ID))+
#   geom_point()+
#   #geom_jitter(width = 0.15)+
#   theme(legend.position = 'none')+
#   ggtitle("Rotation - Total")+
#   #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
#   scale_y_continuous(name="Total change in rotation (degrees)")
# 
# print(figRotByID)