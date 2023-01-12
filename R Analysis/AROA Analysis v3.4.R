# This script processes data and calls testing and plotting functions for 
# "Using augmented reality to cue obstacles for people with low vision."

# Setup -----------------------------
# load libraries for plotting
# install.packages("groundhog")
# install.packages("ez")
# install.packages("rlang")
# install.packages("tidyverse")
# install.packages("gridExtra")
# install.packages("svglite")
# install.packages("ggpubr")
# install.packages("coin")
#install.packages("rfstatix")

# Note the below packages require RTools, which can be found at https://cran.r-project.org/bin/windows/Rtools/
# install.packages("lsr")
# install.packages("effsize")

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
library(coin)
library(lsr)
library(effsize)
library(rstatix)

source("friedmanTests.R")
source("friedmanControl.R")
source("plotAndAnova.R")
source("compareCSVs.R")


# load in data
# Note that we must load in both the Summary Statistics generated from the Matlab code
# as well as the Supplementary Data added separately.
DataMain = read.csv("Summary Statistics.csv", header=T)
DataSup = read.csv("AROA Main Study 2_Participant Tracking - Supplementary Data.csv", header=T)

#Set unique IDs to enable a join
DataMain$ID = paste(DataMain$Participant.ID, DataMain$Condition, DataMain$Direction)
DataSup$ID = paste(DataSup$Participant.ID, DataSup$Condition, DataSup$Direction)

#Join data
Data = left_join(DataSup, DataMain, by=c("ID"))

#Combine time data
#Creates new column, Calibrated.Time
#If the data from Summary Statistics (Calibrated.Time..s.) is there, use that; otherwise, use 0
Data$Calibrated.Time <- ifelse(is.na(Data$Calibrated.Time..s.), 0, Data$Calibrated.Time..s.)
#Then replace those zeros with the control times (Control.Time) that aren't NA
Data$Calibrated.Time <- ifelse(is.na(Data$Control.Time), Data$Calibrated.Time, Data$Control.Time)

#Clean data
#Delete extra columns
Data <- Data %>% select(-c(ID, Participant.ID.y, Condition.y, Direction.y, Layout.y, Calibrated.Time..s., Control.Time))


#Rename columns to match original Data setup
colnames(Data) <- c('Participant.ID', 'Eye.calibration.success', 'HUD.adjustment', 
                    'White.Cane', 'PWS.average.time', 'Preferred.Walking.Speed..m.s.',
                    'Condition', 'Direction', 'Layout', 'Order', 'PPWS', 'Errors', 
                    'Median.Rating', 'Confidence', 'Obstacle.location', 'Obstacle.size',
                    'Awareness', 'Preferred.Condition', 'Calibrated.Distance', 
                    'Average.Speed', 'X.Pitch', 'Y.Yaw', 'Z.Roll', 'Total.Rotation', 
                    'rotSpeedX', 'rotSpeedY', 'rotSpeedZ', 'Percent.Stopped', 'Percent.Slowed', 
                    'Speed.Variance', 'Speed.Variance.Corrected', 'Calibrated.Time')

write.csv(Data, "Data Combined.csv", row.names = TRUE)


#DataOld = read.csv("AROA Main Study 2_Participant Tracking - Experiment Data_8-10-22.csv",header=T)

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
Data$rotSpeedX <- gsub("N/A", "9999", Data$rotSpeedX)
Data$rotSpeedY <- gsub("N/A", "9999", Data$rotSpeedY)
Data$rotSpeedZ <- gsub("N/A", "9999", Data$rotSpeedZ)
Data$Percent.Stopped <- gsub("N/A", "9999", Data$Percent.Stopped)
Data$Percent.Slowed <- gsub("N/A", "9999", Data$Percent.Slowed)
Data$Speed.Variance <- gsub("N/A", "9999", Data$Speed.Variance)
Data$Speed.Variance.Corrected <- gsub("N/A", "9999", Data$Speed.Variance.Corrected)



# Fix Likert range to go from -3 to 3 for experimental conditions
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

# Iterate through every row of Data
for (x in 1:nrow(Data)) {

  if (Data$Direction[x] == "Forward") {
    
    # Mark all the Forward rows as "combined." We'll put the combined info there and delete the backwards rows later.
    Data_avg$Direction[x] = "Combined"
    
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
      Data_avg$rotSpeedX[x] = "Excluded"
      Data_avg$rotSpeedY[x] = "Excluded"
      Data_avg$rotSpeedY[x] = "Excluded"
      Data_avg$Percent.Stopped[x] = "Excluded"
      Data_avg$Percent.Slowed[x] = "Excluded"
      Data_avg$Speed.Variance[x] = "Excluded"
      Data_avg$Speed.Variance.Corrected[x] = "Excluded"
      
      
    } else { 
      
      # Average metrics for forward and backward trial. Assumes a consistent forward/backward/forward/backward pattern.
    
      #Calibrated Time
      Data_avg$Calibrated.Time[x] = mean(c(Data$Calibrated.Time[x], Data$Calibrated.Time[x + 1]))
      
      #PPWS (Percentage of Preferred Walking Speed)
      Data_avg$PPWS[x] = mean(c(as.numeric(Data$PPWS[x]), as.numeric(Data$PPWS[x + 1])))
      
      #Errors
      Data_avg$Errors[x] = mean(c(Data$Errors[x], Data$Errors[x + 1]))
      
      #Now do ones that are only for experimental, excluding Control conditions
      if (Data_avg$Condition[x] != "Control (first)" & Data_avg$Condition[x] != "Control (last)") {
        
        #Calibrated Distance
        Data_avg$Calibrated.Distance[x] = mean(c(as.numeric(Data$Calibrated.Distance[x]), as.numeric(Data$Calibrated.Distance[x + 1])))
        
        #Average Speed
        Data_avg$Average.Speed[x] = mean(c(as.numeric(Data$Average.Speed[x]), as.numeric(Data$Average.Speed[x + 1])))
        
        #Rotation
        Data_avg$X.Pitch[x] = mean(c(as.numeric(Data$X.Pitch[x]), as.numeric(Data$X.Pitch[x + 1])))
        Data_avg$Y.Yaw[x] = mean(c(as.numeric(Data$Y.Yaw[x]), as.numeric(Data$Y.Yaw[x + 1])))
        Data_avg$Z.Roll[x] = mean(c(as.numeric(Data$Z.Roll[x]), as.numeric(Data$Z.Roll[x + 1])))
        Data_avg$Total.Rotation[x] = mean(c(as.numeric(Data$Total.Rotation[x]), as.numeric(Data$Total.Rotation[x + 1])))
        
        Data_avg$rotSpeedX[x] = mean(c(as.numeric(Data$rotSpeedX[x]), as.numeric(Data$rotSpeedX[x + 1])))
        Data_avg$rotSpeedY[x] = mean(c(as.numeric(Data$rotSpeedY[x]), as.numeric(Data$rotSpeedY[x + 1])))
        Data_avg$rotSpeedZ[x] = mean(c(as.numeric(Data$rotSpeedZ[x]), as.numeric(Data$rotSpeedZ[x + 1])))
        
        Data_avg$Percent.Stopped[x] = mean(c(as.numeric(Data$Percent.Stopped[x]), as.numeric(Data$Percent.Stopped[x + 1])))
        Data_avg$Percent.Slowed[x] = mean(c(as.numeric(Data$Percent.Slowed[x]), as.numeric(Data$Percent.Slowed[x + 1])))
        Data_avg$Speed.Variance[x] = mean(c(as.numeric(Data$Speed.Variance[x]), as.numeric(Data$Speed.Variance[x + 1])))
        Data_avg$Speed.Variance.Corrected[x] = mean(c(as.numeric(Data$Speed.Variance.Corrected[x]), as.numeric(Data$Speed.Variance.Corrected[x + 1])))
        
      }
    }
  } 
}

#Remove backward runs, leaving only forward
Data_avg <- Data_avg %>% filter(Direction == "Combined")


# We're also averaging the Control (first) and Control (last) conditions.
# We'll use the same process of marking the control (first) as control, change the values to the mean
# of control (first) and control (last), then delete control (last) rows.

for (x in 1:nrow(Data_avg)) {
  if (Data_avg$Condition[x] == "Control (first)") {

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
    Data_avg$Calibrated.Time[x] = mean(c(as.numeric(Data_avg$Calibrated.Time[x]), as.numeric(Data_avg$Calibrated.Time[lastX])))

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


# Now create a new version that removes any bad data marked as "NaN."
# This is from trials for which HoloLens data gathering failed.
# Note that below removed only Excluded conditions; to make analysis more straightforward, we just remove OA07 and OA11 entirely
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
Data_avg_noErr$rotSpeedX <- as.numeric(Data_avg_noErr$rotSpeedX)
Data_avg_noErr$rotSpeedY <- as.numeric(Data_avg_noErr$rotSpeedY)
Data_avg_noErr$rotSpeedZ <- as.numeric(Data_avg_noErr$rotSpeedZ)
Data_avg_noErr$Percent.Stopped <- as.numeric(Data_avg_noErr$Percent.Stopped)
Data_avg_noErr$Percent.Slowed <- as.numeric(Data_avg_noErr$Percent.Slowed)
Data_avg_noErr$Speed.Variance <- as.numeric(Data_avg_noErr$Speed.Variance)
Data_avg_noErr$Speed.Variance.Corrected <- as.numeric(Data_avg_noErr$Speed.Variance.Corrected)


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
Data_noErr$rotSpeedX <- as.numeric(Data_noErr$rotSpeedX)
Data_noErr$rotSpeedY <- as.numeric(Data_noErr$rotSpeedY)
Data_noErr$rotSpeedZ <- as.numeric(Data_noErr$rotSpeedZ)
Data_noErr$Percent.Stopped <- as.numeric(Data_noErr$Percent.Stopped)
Data_noErr$Percent.Slowed <- as.numeric(Data_noErr$Percent.Slowed)
Data_noErr$Speed.Variance <- as.numeric(Data_noErr$Speed.Variance)
Data_noErr$Speed.Variance.Corrected <- as.numeric(Data_noErr$Speed.Variance.Corrected)

write.csv(Data_noErr, "Data_noErr.csv", row.names = TRUE)


#For comparing first and last control without "excluded"
Data_avg_controlComp <- Data %>% filter((Condition == "Control (first)" | Condition == "Control (last)") 
                                        & (Participant.ID != "OA07" & Participant.ID != "OA11"))

Data_avg_controlComp_first <- Data_avg_controlComp %>% filter(Condition == "Control (first)")
Data_avg_controlComp_last <- Data_avg_controlComp %>% filter(Condition == "Control (last)")

# #Graph of control condition likert responses
Data_ctrl <- Data %>% filter((Condition == "Control (first)" | Condition == "Control (last)") & Direction == "Forward") 



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


friedmanControl("Control Median Ratings", "./Tests./Likert Ratings Control_Median", "./Plots./Likert", Data_ctrl, "Median.Rating", "runTests" = TRUE, "addJitter" = FALSE, type = "Wilcoxon")
friedmanControl("Control Confidence Ratings", "./Tests./Likert Ratings Control_Confidence", "./Plots./Likert", Data_ctrl, "Confidence", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Location", "./Tests./Likert Ratings Control_Obstacle Location", "./Plots./Likert", Data_ctrl, "Obstacle.location", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Size Ratings", "./Tests./Likert Ratings Control_Obstacle Size", "./Plots./Likert", Data_ctrl, "Obstacle.size", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Awareness Ratings", "./Tests./Likert Ratings Control_Awareness", "./Plots./Likert", Data_ctrl, "Awareness", "runTests" = TRUE, "addJitter" = FALSE)


# Single Sample Wilcoxon Signed-Rank Test - No Cues vs. Control
# This determines whether No Cues is significantly different than 0 (control)
# Baked into friedmanTests


#Run basic Friedman tests
friedmanTests("Median Ratings", "./Tests./Likert Ratings_Median", "./Plots./Likert", Data_avg, "Median.Rating", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Confidence Ratings", "./Tests./Likert Ratings_Confidence", "./Plots./Likert", Data_avg, "Confidence", "runTests" = TRUE, "addJitter" = FALSE, followup = "Wilcox")
friedmanTests("Obstacle Location Ratings",  "./Tests./Likert Ratings_Obstacle Location", "./Plots./Likert", Data_avg, "Obstacle.location", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Obstacle Size Ratings", "./Tests./Likert Ratings_Obstacle Size", "./Plots./Likert", Data_avg, "Obstacle.size", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Awareness Ratings", "./Tests./Likert Ratings_Awareness", "./Plots./Likert", Data_avg, "Awareness", "runTests" = TRUE, "addJitter" = FALSE)


# Quantitative Data -------------------------------------------------------


#TIME
plotAndAnova("Time by Condition", "./Tests./Time", "./Plots./Time", Data_avg_noErr, TRUE, "Calibrated.Time", "Time (s)", c(10,40))

#PPWS
plotAndAnova("PPWS by Condition", "./Tests./PPWS", "./Plots./PPWS", Data_avg_noErr, TRUE, "PPWS", "Percentage of Preferred Walking Speed")
#Also calculate average PPWS for first and last condition. Use Data_avg_controlComp
mean(as.numeric(Data_avg_controlComp$PPWS))
mean(as.numeric(Data_avg_controlComp_first$PPWS))
mean(as.numeric(Data_avg_controlComp_last$PPWS))
wilcox.test(as.numeric(Data_avg_controlComp$PPWS[Data_avg_controlComp$Condition == "Control (first)"]), as.numeric(Data_avg_controlComp$PPWS[Data_avg_controlComp$Condition == "Control (last)"]), paired = TRUE, alternative = "two.sided")



#ERRORS
plotAndAnova("Errors by Condition", "./Tests./Errors", "./Plots./Errors", Data_avg_noErr, TRUE, "Errors", "Number of Errors")


#DISTANCE
plotAndAnova("Distance by Condition", "./Tests./Distance", "./Plots./Distance", 
             Data_avg_noErr, FALSE, "Calibrated.Distance", "Total Distance Walked (m)", c(15, 17))


#SPEED
plotAndAnova("Average Speed by Condition", "./Tests./Speed Average", "./Plots./Speed", Data_avg_noErr, FALSE, "Average.Speed", "Average Speed (m/s)")
plotAndAnova("Percentage Stopped", "./Tests./Percent Stopped", "./Plots./Speed", Data_avg_noErr, FALSE, "Percent.Stopped", "Percentage", c(0, 1.5))
plotAndAnova("Percentage Slowed", "./Tests./Percent Slowed", "./Plots./Speed", Data_avg_noErr, FALSE, "Percent.Slowed", "Percentage", c(0, 16))
plotAndAnova("Speed Variance", "./Tests./Speed Variance", "./Plots./Speed", Data_avg_noErr, FALSE, "Speed.Variance", "Speed Variance (m/s)^2")
plotAndAnova("Speed Variance Corrected", "./Tests./Speed Variance Corrected", "./Plots./Speed", Data_avg_noErr, FALSE, "Speed.Variance.Corrected", "Speed Variance Corrected", c(0, 0.35))


#Percentage stopped by participant
graph_stopped_participant <- ddply(Data_avg_noErr, .(Participant.ID), summarise, mean = mean(Percent.Stopped))

figStopped <-  Data_avg_noErr %>% 
  filter(Condition != "Control") %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = Percent.Stopped, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Percentage Stopped")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Percent Stopped")

print(figStopped)


#Percentage slowed by participant
graph_slowed_participant <- ddply(Data_avg_noErr, .(Participant.ID), summarise, mean = mean(Percent.Slowed))

figSlowed <-  Data_avg_noErr %>% 
  filter(Condition != "Control") %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = Percent.Slowed, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Percentage Slowed")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Percent Slowed")

print(figSlowed)



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

#X Rotation (Pitch) Per Second
plotAndAnova("X Rotation (Pitch)", "./Tests./Rotation X per second", "./Plots./Rotation Per Second",
             Data_avg_noErr, FALSE, "rotSpeedX", "Rotation (degrees per second)", c(10, 35))

#Y Rotation (Yaw) Per Second
plotAndAnova("Y Rotation (Yaw)", "./Tests./Rotation Y per second", "./Plots./Rotation Per Second",
             Data_avg_noErr, FALSE, "rotSpeedY", "Rotation (degrees per second)", c(10, 35))

#Z Rotation (Roll) Per Second
plotAndAnova("Z Rotation (Roll)", "./Tests./Rotation Z per second", "./Plots./Rotation Per Second",
             Data_avg_noErr, FALSE, "rotSpeedZ", "Rotation (degrees per second)")


#ROTATION BY PARTICIPANT

#X, total
graph_RotByID_X <- ddply(Data_avg_noErr, .(Participant.ID), summarise, mean = mean(X.Pitch))

figRotByID_X <-  Data_avg_noErr %>% 
  filter(Condition != "Control") %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = X.Pitch, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation - Pitch")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total change in pitch (degrees)")

print(figRotByID_X)

#Y, total
graph_RotByID_Y <- ddply(Data_avg_noErr, .(Participant.ID), summarise, mean = mean(Y.Yaw))

figRotByID_Y <-  Data_avg_noErr %>% 
  filter(Condition != "Control") %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = Y.Yaw, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation - Yaw")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total change in yaw (degrees)")

print(figRotByID_Y)


#Z, total
graph_RotByID_Z <- ddply(Data_avg_noErr, .(Participant.ID), summarise, mean = mean(Z.Roll))

figRotByID_Z <-  Data_avg_noErr %>% 
  filter(Condition != "Control") %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = Z.Roll, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation - Roll")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total change in roll (degrees)")

print(figRotByID_Z)


#X, per second
graph_RotByID_X_time <- ddply(Data_avg_noErr, .(Participant.ID), summarise, mean = mean(rotSpeedX))

figRotByID_X_time <-  Data_avg_noErr %>% 
  filter(Condition != "Control") %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = rotSpeedX, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation per second - Pitch")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Change in pitch (degrees/second)")

print(figRotByID_X_time)

#Y, per second
graph_RotByID_Y_time <- ddply(Data_avg_noErr, .(Participant.ID), summarise, mean = mean(rotSpeedY))

figRotByID_Y_time <-  Data_avg_noErr %>% 
  filter(Condition != "Control") %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = rotSpeedY, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation per second - Yaw")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Change in yaw (degrees/second)")

print(figRotByID_Y_time)

#Z, per second
graph_RotByID_Z_time <- ddply(Data_avg_noErr, .(Participant.ID), summarise, mean = mean(rotSpeedZ))

figRotByID_Z_time <-  Data_avg_noErr %>% 
  filter(Condition != "Control") %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = rotSpeedZ, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation per second - Roll")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Change in pitch (degrees/second)")

print(figRotByID_Z_time)


#Preferred Conditions Only ------------------------

#Formerly did this by looking at all participant's control and no cues condition, 
#then just the other experimental conditions for which users indicated preference.

#Now we're going to look up which participants preferred HUD and Combined, and use only their data for all modes.
#Preferred HUD: 5, 7, 18
#Preferred Combined: 1, 12, 13, 15, 20

#Filter data (Likert)
Data_ctrl_HeadPref <- Data_ctrl %>% filter(Participant.ID == "OA01" | Participant.ID == "OA05" | 
                                             Participant.ID == "OA07" | Participant.ID == "OA12" | 
                                             Participant.ID == "OA13" | Participant.ID == "OA15" | 
                                             Participant.ID == "OA18" | Participant.ID == "OA20" )

Data_ctrl_WorldPref <- Data_ctrl %>% filter(Participant.ID != "OA01" & Participant.ID != "OA05" & 
                                             Participant.ID != "OA07" & Participant.ID != "OA12" & 
                                             Participant.ID != "OA13" & Participant.ID != "OA15" & 
                                             Participant.ID != "OA18" & Participant.ID != "OA20" )

Data_avg_HeadPref <- Data_avg %>% filter(Participant.ID == "OA01" | Participant.ID == "OA05" | 
                                       Participant.ID == "OA07" | Participant.ID == "OA12" | 
                                       Participant.ID == "OA13" | Participant.ID == "OA15" | 
                                       Participant.ID == "OA18" | Participant.ID == "OA20" )

Data_avg_WorldPref <- Data_avg %>% filter(Participant.ID != "OA01" & Participant.ID != "OA05" & 
                                           Participant.ID != "OA07" & Participant.ID != "OA12" & 
                                           Participant.ID != "OA13" & Participant.ID != "OA15" & 
                                           Participant.ID != "OA18" & Participant.ID != "OA20" )


#Likert Ratings

#World Preference
friedmanControl("Control Median - World Preference", "./Tests./Preferred./Likert Ratings Control_WorldPref_Median", "./Plots./Likert./Preference", Data_ctrl_WorldPref, "Median.Rating", "runTests" = FALSE, "addJitter" = FALSE)
friedmanControl("Control Confidence - World Preference", "./Tests./Preferred./Likert Ratings Control_WorldPref_Confidence", "./Plots./Likert./Preference", Data_ctrl_WorldPref, "Confidence", "runTests" = FALSE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Location - World Preference", "./Tests./Preferred./Likert Ratings Control_WorldPref_Obstacle Location", "./Plots./Likert./Preference", Data_ctrl_WorldPref, "Obstacle.location", "runTests" = FALSE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Size  - World Preference", "./Tests./Preferred./Likert Ratings Control_WorldPref_Obstacle Size", "./Plots./Likert./Preference", Data_ctrl_WorldPref, "Obstacle.size", "runTests" = FALSE, "addJitter" = FALSE)
friedmanControl("Control Awareness - World Preference", "./Tests./Preferred./Likert Ratings Control_WorldPref_Awareness", "./Plots./Likert./Preference", Data_ctrl_WorldPref, "Awareness", "runTests" = FALSE, "addJitter" = FALSE)

friedmanTests("Median - World Preference", "./Tests./Preferred./Likert Ratings_WorldPref_Median", "./Plots./Likert./Preference", Data_avg_WorldPref, "Median.Rating", "runTests" = FALSE, "addJitter" = FALSE)
friedmanTests("Confidence - World Preference", "./Tests./Preferred./Likert Ratings_WorldPref_Confidence", "./Plots./Likert./Preference", Data_avg_WorldPref, "Confidence", "runTests" = FALSE, "addJitter" = FALSE)
friedmanTests("Obstacle Location - World Preference", "./Tests./Preferred./Likert Ratings_WorldPref_Obstacle Location", "./Plots./Likert./Preference", Data_avg_WorldPref, "Obstacle.location", "runTests" = FALSE, "addJitter" = FALSE)
friedmanTests("Obstacle Size - World Preference", "./Tests./Preferred./Likert Ratings_WorldPref_Obstacle Size", "./Plots./Likert./Preference", Data_avg_WorldPref, "Obstacle.size","runTests" = FALSE, "addJitter" = FALSE)
friedmanTests("Awareness - World Preference", "./Tests./Preferred./Likert Ratings_WorldPref_Awareness", "./Plots./Likert./Preference", Data_avg_WorldPref, "Awareness", "runTests" = FALSE, "addJitter" = FALSE)

#Head Preference
friedmanControl("Control Median - Head Preference", "./Tests./Preferred./Likert Ratings Control_HeadPref_Median", "./Plots./Likert./Preference", Data_ctrl_HeadPref, "Median.Rating", "runTests" = FALSE, "addJitter" = FALSE)
friedmanControl("Control Confidence - Head Preference", "./Tests./Preferred./Likert Ratings Control_HeadPref_Confidence", "./Plots./Likert./Preference", Data_ctrl_HeadPref, "Confidence", "runTests" = FALSE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Location - Head Preference", "./Tests./Preferred./Likert Ratings Control_HeadPref_Obstacle Location", "./Plots./Likert./Preference", Data_ctrl_HeadPref, "Obstacle.location", "runTests" = FALSE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Size  - Head Preference", "./Tests./Preferred./Likert Ratings Control_HeadPref_Obstacle Size", "./Plots./Likert./Preference", Data_ctrl_HeadPref, "Obstacle.size", "runTests" = FALSE, "addJitter" = FALSE)
friedmanControl("Control Awareness - Head Preference", "./Tests./Preferred./Likert Ratings Control_HeadPref_Awareness", "./Plots./Likert./Preference", Data_ctrl_HeadPref, "Awareness", "runTests" = FALSE, "addJitter" = FALSE)

friedmanTests("Median - Head Preference", "./Tests./Preferred./Likert Ratings_HeadPref_Median", "./Plots./Likert./Preference", Data_avg_HeadPref, "Median.Rating", "runTests" = FALSE, "addJitter" = FALSE)
friedmanTests("Confidence - Head Preference", "./Tests./Preferred./Likert Ratings_HeadPref_Confidence", "./Plots./Likert./Preference", Data_avg_HeadPref, "Confidence", "runTests" = FALSE, "addJitter" = FALSE)
friedmanTests("Obstacle Location - Head Preference", "./Tests./Preferred./Likert Ratings_HeadPref_Obstacle Location", "./Plots./Likert./Preference", Data_avg_HeadPref, "Obstacle.location", "runTests" = FALSE, "addJitter" = FALSE)
friedmanTests("Obstacle Size - Head Preference", "./Tests./Preferred./Likert Ratings_HeadPref_Obstacle Size", "./Plots./Likert./Preference", Data_avg_HeadPref, "Obstacle.size","runTests" = FALSE, "addJitter" = FALSE)
friedmanTests("Awareness - Head Preference", "./Tests./Preferred./Likert Ratings_HeadPref_Awareness", "./Plots./Likert./Preference", Data_avg_HeadPref, "Awareness", "runTests" = FALSE, "addJitter" = FALSE)


# Acuity Analysis ---------------------------------------------------------

#Filter participants by low or high acuity
# Acuity from lowest to highest (highest logMAR to lowest): 
# 10, 6, 2, 17, 8, 7, 14, 12, 9, 13, 15, 11, 3, 16, 5, 18, 20, 19, 4, 1

lowAcuity <- list("OA10", "OA06", "OA02", "OA17", "OA08", "OA07", "OA14", "OA12", "OA09", "OA13")
highAcuity <- list("OA15", "OA11", "OA03", "OA16", "OA05", "OA18", "OA20", "OA19", "OA04", "OA01")

Data_ctrl_LowAcuity <- Data_ctrl %>% filter(Participant.ID %in% lowAcuity)
Data_ctrl_HighAcuity <- Data_ctrl %>% filter(Participant.ID %in% highAcuity)
Data_avg_LowAcuity <- Data_avg %>% filter(Participant.ID %in% lowAcuity)
Data_avg_HighAcuity <- Data_avg %>% filter(Participant.ID %in% highAcuity)
Data_avg_noErr_LowAcuity <- Data_avg_noErr %>% filter(Participant.ID %in% lowAcuity)
Data_avg_noErr_HighAcuity <- Data_avg_noErr %>% filter(Participant.ID %in% highAcuity)

# Likert ratings
# Low acuity
friedmanControl("Control Median - Low Acuity", "./Tests./Acuity./Likert Ratings Control_LowAcuity_Median", "./Plots./Likert./Acuity", Data_ctrl_LowAcuity, "Median.Rating", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Confidence - Low Acuity", "./Tests./Acuity./Likert Ratings Control_LowAcuity_Confidence", "./Plots./Likert./Acuity", Data_ctrl_LowAcuity, "Confidence", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Location - Low Acuity", "./Tests./Acuity./Likert Ratings Control_LowAcuity_Obstacle Location", "./Plots./Likert./Acuity", Data_ctrl_LowAcuity, "Obstacle.location", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Size  - Low Acuity", "./Tests./Acuity./Likert Ratings Control_LowAcuity_Obstacle Size", "./Plots./Likert./Acuity", Data_ctrl_LowAcuity, "Obstacle.size", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Awareness - Low Acuity", "./Tests./Acuity./Likert Ratings Control_LowAcuity_Awareness", "./Plots./Likert./Acuity", Data_ctrl_LowAcuity, "Awareness", "runTests" = TRUE, "addJitter" = FALSE)

friedmanTests("Median - Low Acuity", "./Tests./Acuity./Likert Ratings_LowAcuity_Median", "./Plots./Likert./Acuity", Data_avg_LowAcuity, "Median.Rating", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Confidence - Low Acuity", "./Tests./Acuity./Likert Ratings_LowAcuity_Confidence", "./Plots./Likert./Acuity", Data_avg_LowAcuity, "Confidence", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Obstacle Location - Low Acuity", "./Tests./Acuity./Likert Ratings_LowAcuity_Obstacle Location", "./Plots./Likert./Acuity", Data_avg_LowAcuity, "Obstacle.location", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Obstacle Size - Low Acuity", "./Tests./Acuity./Likert Ratings_LowAcuity_Obstacle Size", "./Plots./Likert./Acuity", Data_avg_LowAcuity, "Obstacle.size","runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Awareness - Low Acuity", "./Tests./Acuity./Likert Ratings_LowAcuity_Awareness", "./Plots./Likert./Acuity", Data_avg_LowAcuity, "Awareness", "runTests" = TRUE, "addJitter" = FALSE)

# High acuity
friedmanControl("Control Median - High Acuity", "./Tests./Acuity./Likert Ratings Control_HighAcuity_Median", "./Plots./Likert./Acuity", Data_ctrl_HighAcuity, "Median.Rating", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Confidence - High Acuity", "./Tests./Acuity./Likert Ratings Control_HighAcuity_Confidence", "./Plots./Likert./Acuity", Data_ctrl_HighAcuity, "Confidence", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Location - High Acuity", "./Tests./Acuity./Likert Ratings Control_HighAcuity_Obstacle Location", "./Plots./Likert./Acuity", Data_ctrl_HighAcuity, "Obstacle.location", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Obstacle Size  - High Acuity", "./Tests./Acuity./Likert Ratings Control_HighAcuity_Obstacle Size", "./Plots./Likert./Acuity", Data_ctrl_HighAcuity, "Obstacle.size", "runTests" = TRUE, "addJitter" = FALSE)
friedmanControl("Control Awareness - High Acuity", "./Tests./Acuity./Likert Ratings Control_HighAcuity_Awareness", "./Plots./Likert./Acuity", Data_ctrl_HighAcuity, "Awareness", "runTests" = TRUE, "addJitter" = FALSE)

friedmanTests("Median - High Acuity", "./Tests./Acuity./Likert Ratings_HighAcuity_Median", "./Plots./Likert./Acuity", Data_avg_HighAcuity, "Median.Rating", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Confidence - High Acuity", "./Tests./Acuity./Likert Ratings_HighAcuity_Confidence", "./Plots./Likert./Acuity", Data_avg_HighAcuity, "Confidence", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Obstacle Location - High Acuity", "./Tests./Acuity./Likert Ratings_HighAcuity_Obstacle Location", "./Plots./Likert./Acuity", Data_avg_HighAcuity, "Obstacle.location", "runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Obstacle Size - High Acuity", "./Tests./Acuity./Likert Ratings_HighAcuity_Obstacle Size", "./Plots./Likert./Acuity", Data_avg_HighAcuity, "Obstacle.size","runTests" = TRUE, "addJitter" = FALSE)
friedmanTests("Awareness - High Acuity", "./Tests./Acuity./Likert Ratings_HighAcuity_Awareness", "./Plots./Likert./Acuity", Data_avg_HighAcuity, "Awareness", "runTests" = TRUE, "addJitter" = FALSE)


# Qualitative data


#TIME
plotAndAnova("Time by Condition - Low Acuity", "./Tests./Acuity./Time_Low Acuity", "./Plots./Acuity./Time", Data_avg_noErr_LowAcuity, TRUE, "Calibrated.Time", "Time (s)", c(10,40))
plotAndAnova("Time by Condition - High Acuity", "./Tests./Acuity./Time_High Acuity", "./Plots./Acuity./Time", Data_avg_noErr_HighAcuity, TRUE, "Calibrated.Time", "Time (s)", c(10,40))

#PPWS
plotAndAnova("PPWS by Condition - Low Acuity", "./Tests./Acuity./PPWS_Low Acuity", "./Plots./Acuity./PPWS", Data_avg_noErr_LowAcuity, TRUE, "PPWS", "Percentage of Preferred Walking Speed")
plotAndAnova("PPWS by Condition - High Acuity", "./Tests./Acuity./PPWS_High Acuity", "./Plots./Acuity./PPWS", Data_avg_noErr_HighAcuity, TRUE, "PPWS", "Percentage of Preferred Walking Speed")


#ERRORS
plotAndAnova("Errors by Condition - Low Acuity", "./Tests./Acuity./Errors_Low Acuity", "./Plots./Acuity./Errors", Data_avg_noErr_LowAcuity, TRUE, "Errors", "Number of Errors")
plotAndAnova("Errors by Condition - High Acuity", "./Tests./Acuity./Errors_High Acuity", "./Plots./Acuity./Errors", Data_avg_noErr_HighAcuity, TRUE, "Errors", "Number of Errors")


#DISTANCE
plotAndAnova("Distance by Condition - Low Acuity", "./Tests./Acuity./Distance_Low Acuity", "./Plots./Acuity./Distance", 
             Data_avg_noErr_LowAcuity, inclControl = FALSE, "Calibrated.Distance", "Total Distance Walked (m)", c(15, 17))
plotAndAnova("Distance by Condition - High Acuity", "./Tests./Acuity./Distance_High Acuity", "./Plots./Acuity./Distance", 
             Data_avg_noErr_HighAcuity, inclControl = FALSE, "Calibrated.Distance", "Total Distance Walked (m)", c(15, 17))


#SPEED
plotAndAnova("Average Speed by Condition - Low Acuity", "./Tests./Acuity./Speed Average_Low Acuity", "./Plots./Acuity./Speed", Data_avg_noErr_LowAcuity, FALSE, "Average.Speed", "Average Speed (m/s)")
plotAndAnova("Average Speed by Condition - High Acuity", "./Tests./Acuity./Speed Average_High Acuity", "./Plots./Acuity./Speed", Data_avg_noErr_HighAcuity, FALSE, "Average.Speed", "Average Speed (m/s)")

plotAndAnova("Percentage Stopped - Low Acuity", "./Tests./Acuity./Percent Stopped_Low Acuity", "./Plots./Acuity./Speed", Data_avg_noErr_LowAcuity, inclControl = FALSE, "Percent.Stopped", "Percentage", c(0, 1.5))
plotAndAnova("Percentage Stopped - High Acuity", "./Tests./Acuity./Percent Stopped_High Acuity", "./Plots./Acuity./Speed", Data_avg_noErr_HighAcuity, inclControl = FALSE, "Percent.Stopped", "Percentage", c(0, 1.5))


plotAndAnova("Percentage Slowed - Low Acuity", "./Tests./Acuity./Percent Slowed_Low Acuity", "./Plots./Acuity./Speed", Data_avg_noErr_LowAcuity, inclControl = FALSE, "Percent.Slowed", "Percentage", c(0, 16))
plotAndAnova("Percentage Slowed - High Acuity", "./Tests./Acuity./Percent Slowed_High Acuity", "./Plots./Acuity./Speed", Data_avg_noErr_HighAcuity, inclControl = FALSE, "Percent.Slowed", "Percentage", c(0, 16))


plotAndAnova("Speed Variance - Low Acuity", "./Tests./Acuity./Speed Variance_Low Acuity", "./Plots./Acuity./Speed", Data_avg_noErr_LowAcuity, inclControl = FALSE, "Speed.Variance", "Speed Variance (m/s)^2")
plotAndAnova("Speed Variance - High Acuity", "./Tests./Acuity./Speed Variance_High Acuity", "./Plots./Acuity./Speed", Data_avg_noErr_HighAcuity, inclControl = FALSE, "Speed.Variance", "Speed Variance (m/s)^2")


plotAndAnova("Speed Variance Corrected - Low Acuity", "./Tests./Acuity./Speed Variance Corrected_Low Acuity", "./Plots./Acuity./Speed", Data_avg_noErr_LowAcuity, inclControl = FALSE, "Speed.Variance.Corrected", "Speed Variance Corrected", c(0, 0.35))
plotAndAnova("Speed Variance Corrected - High Acuity", "./Tests./Acuity./Speed Variance Corrected_High Acuity", "./Plots./Acuity./Speed", Data_avg_noErr_HighAcuity, inclControl = FALSE, "Speed.Variance.Corrected", "Speed Variance Corrected", c(0, 0.35))

#X Rotation (Pitch) Per Second
plotAndAnova("X Rotation (Pitch) - Low Acuity", "./Tests./Acuity./Rotation X per second_Low Acuity", "./Plots./Acuity./Rotation Per Second",
             Data_avg_noErr_LowAcuity, inclControl = FALSE, "rotSpeedX", "Rotation (degrees per second)", c(10, 35))
plotAndAnova("X Rotation (Pitch) - High Acuity", "./Tests./Acuity./Rotation X per second_High Acuity", "./Plots./Acuity./Rotation Per Second",
             Data_avg_noErr_HighAcuity, inclControl = FALSE, "rotSpeedX", "Rotation (degrees per second)", c(10, 35))

#Y Rotation (Yaw) Per Second
plotAndAnova("Y Rotation (Yaw) - Low Acuity", "./Tests./Acuity./Rotation Y per second_Low Acuity", "./Plots./Acuity./Rotation Per Second",
             Data_avg_noErr_LowAcuity, inclControl = FALSE, "rotSpeedY", "Rotation (degrees per second)", c(10, 35))
plotAndAnova("Y Rotation (Yaw) - High Acuity", "./Tests./Acuity./Rotation Y per second_High Acuity", "./Plots./Acuity./Rotation Per Second",
             Data_avg_noErr_HighAcuity, inclControl = FALSE, "rotSpeedY", "Rotation (degrees per second)", c(10, 35))

#Z Rotation (Roll) Per Second
plotAndAnova("Z Rotation (Roll) - Low Acuity", "./Tests./Acuity./Rotation Z per second_Low Acuity", "./Plots./Acuity./Rotation Per Second",
             Data_avg_noErr_LowAcuity, inclControl = FALSE, "rotSpeedZ", "Rotation (degrees per second)")
plotAndAnova("Z Rotation (Roll) - High Acuity", "./Tests./Acuity./Rotation Z per second_High Acuity", "./Plots./Acuity./Rotation Per Second",
             Data_avg_noErr_HighAcuity, inclControl = FALSE, "rotSpeedZ", "Rotation (degrees per second)")



# Comparison --------------------------------------------------------------

# Create spreadsheet that compares original condition against acuity conditions

compareCSVs("./Tests", "./Tests./Acuity", "./Tests./Acuity Comparisons")



#UNUSED CODE -----------------------

# # Example of how to graph control likert conditions
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

# #Plot distance for forward only 
# graph_distance_forward <- ddply(Data_noErr %>% filter(Direction == "Forward" & Condition != "Control (first)" & Condition != "Control (last)"), 
#                                 .(Condition), summarise, mean = mean(Calibrated.Distance))
# 
# FigDistanceForward <-  Data_noErr %>% filter(Direction == "Forward" & Condition != "Control (first)" & Condition != "Control (last)") %>%
#   mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
#   ggplot(aes(x = Condition, y = Calibrated.Distance, color = Condition))+
#   geom_boxplot(outlier.shape = NA)+
#   geom_jitter(width = 0.15, height = 0)+
#   theme(legend.position = 'none')+
#   expand_limits(y = c(15,20))+
#   ggtitle("Distance by Condition - Forward Only")+
#   geom_label(data = graph_distance_forward, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
#   scale_y_continuous(name="Total Distance Travelled (m)")
# 
# print(FigDistanceForward)
# 
# #Plot distance for backward only
# graph_distance_backward <- ddply(Data_noErr %>% filter(Direction == "Backward" & Condition != "Control (first)" & Condition != "Control (last)"), 
#                                  .(Condition), summarise, mean = mean(Calibrated.Distance))
# 
# FigDistanceBackward <-  Data_noErr %>% filter(Direction == "Backward" & Condition != "Control (first)" & Condition != "Control (last)") %>%
#   mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
#   ggplot(aes(x = Condition, y = Calibrated.Distance, color = Condition))+
#   geom_boxplot(outlier.shape = NA)+
#   geom_jitter(width = 0.15, height = 0)+
#   theme(legend.position = 'none')+
#   expand_limits(y = c(15,20))+
#   ggtitle("Distance by Condition - Backward Only")+
#   geom_label(data = graph_distance_backward, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
#   scale_y_continuous(name="Total Distance Travelled (m)")
# 
# print(FigDistanceBackward)


# 
# 
#Filter data (Quant)
# Data_avg_noErr_Pref <- Data_avg_noErr %>% filter(Condition == "Control" | Condition == "No Cues" | Preferred.Condition == "Yes")
# 
# #Time
# plotAndAnova("Time by Condition_Preferred", "./Tests./Time_Preferred", "./Plots./Time", Data_avg_noErr_Pref, TRUE, "Calibrated.Time", "Time (s)", c(10,40), "runTests" = FALSE, "addJitter" = TRUE)
# 
# #PPWS
# plotAndAnova("PPWS by Condition_Preferred", "./Tests./PPWS_Preferred", "./Plots./PPWS", Data_avg_noErr_Pref, TRUE, "PPWS", "Percentage of Preferred Walking Speed", "runTests" = FALSE, "addJitter" = TRUE)
# 
# #Errors
# plotAndAnova("Errors by Condition_Preferred", "./Tests./Errors_Preferred", "./Plots./Errors", Data_avg_noErr_Pref, TRUE, "Errors", "Number of Errors", "runTests" = FALSE, "addJitter" = TRUE)
# 
# 
# #Distance
# plotAndAnova("Distance by Condition_Preferred", "./Tests./Distance_Preferred", "./Plots./Distance", 
#              Data_avg_noErr_Pref, FALSE, "Calibrated.Distance", "Total Distance Walked (m)", c(15, 17), "runTests" = FALSE, "addJitter" = TRUE)
# 
# #Average Speed
# plotAndAnova("Average Speed by Condition_Preferred", "./Tests./Speed_Preferred", "./Plots./Speed", 
#              Data_avg_noErr_Pref, FALSE, "Average.Speed", "Average Speed (m/s)", "runTests" = FALSE, "addJitter" = TRUE)

#Rotation

#X Rotation (Pitch)
# plotAndAnova("X Rotation (Pitch)_Preferred", "./Tests./Rotation X_Preferred", "./Plots./Rotation", 
#              Data_avg_noErr_Pref, FALSE, "X.Pitch", "Absolute Rotation (degrees)", c(NA, 1000), "runTests" = FALSE, "addJitter" = TRUE)
# 
# #Y Rotation (Yaw)
# plotAndAnova("Y Rotation (Yaw)_Preferred", "./Tests./Rotation Y_Preferred", "./Plots./Rotation", 
#              Data_avg_noErr_Pref, FALSE, "Y.Yaw", "Absolute Rotation (degrees)", c(NA, 600), "runTests" = FALSE, "addJitter" = TRUE)
# 
# #Z Rotation (Roll)
# plotAndAnova("Z Rotation (Roll)_Preferred", "./Tests./Rotation Z_Preferred", "./Plots./Rotation", 
#              Data_avg_noErr_Pref, FALSE, "Z.Roll", "Absolute Rotation (degrees)", c(NA, 750), "runTests" = FALSE, "addJitter" = TRUE)
# 
# #Total Rotation
# plotAndAnova("Total Rotation_Preferred", "./Tests./Rotation Total_Preferred", "./Plots./Rotation", 
#              Data_avg_noErr_Pref, FALSE, "Total.Rotation", "Absolute Rotation (degrees)", c(NA, 2250), "runTests" = FALSE, "addJitter" = TRUE)
# 