# load libraries for plotting
# install.packages("groundhog")
# install.packages("ez")
# install.packages("rlang")
# install.packages("tidyverse")
# install.packages("gridExtra")


# may not need all these these packages, but loading them now for simplicity
library(ez)
library(plyr)
library(dplyr)
library(rlang)
library(tidyverse)
library(gridExtra)
library(ggplot2)


# load in data
Data = read.csv("AROA Main Study 2_Participant Tracking - Experiment Data_8-10-22.csv",header=T)

#Remove percentage signs in PPWS, commas in rotation
Data$PPWS <- gsub("%", "", Data$PPWS)
Data$X.Pitch <- gsub(",", "", Data$X.Pitch)
Data$Y.Yaw <- gsub(",", "", Data$Y.Yaw)
Data$Z.Roll <- gsub(",", "", Data$Z.Roll)
Data$Total.Rotation <- gsub(",", "", Data$Total.Rotation)

# Define Data Sets ---------------------------------------------
# Data: raw data
# Data_avg: forward and backward runs combined
# Data_avg_noErr: as above but with the two excluded runs filtered out
# Data_exp: Data_avg_noErr, but experimental conditions only
# Data_ctrl: Data_avg_noErr, but control conditions only
# Data_Likert_exp: Data_Avg but with corrected Likert. Includes conditions with discarded times
# Data_Likert_ctrl: Data_Avg but control only. Includes conditions with discarded times.


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
        
        print(paste("Error discovered at row", x))
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

#Write to a spreadsheet to verify
write.csv(Data_avg,"Data_avg.csv", row.names = TRUE)
write.csv(Data_exp, "Data_exp.csv", row.names = TRUE)


#also create a version with no NaN 
Data_avg_noErr <- Data_avg %>% filter(Calibrated.Time != "Excluded")

#Need to make these numeric. Time, PPWS, and Errors can be for all conditions 
Data_avg_noErr$Calibrated.Time <- as.numeric(Data_avg_noErr$Calibrated.Time)
Data_avg_noErr$PPWS <- as.numeric(Data_avg_noErr$PPWS)
Data_avg_noErr$Errors <- as.numeric(Data_avg_noErr$Errors)


#Create control only dataset
Data_ctrl <- Data_avg_noErr %>% filter(Condition == "Control (first)" | Condition == "Control (last)")

#Experimental conditions only. Distance, speed, and rotation need to be set to numeric here
Data_exp <- Data_avg_noErr %>% filter(Condition != "Control (first)" & Condition != "Control (last)")
Data_exp$Calibrated.Distance <- as.numeric(Data_exp$Calibrated.Distance)
Data_exp$Average.Speed <- as.numeric(Data_exp$Average.Speed)
Data_exp$X.Pitch <- as.numeric(Data_exp$X.Pitch)
Data_exp$Y.Yaw <- as.numeric(Data_exp$Y.Yaw)
Data_exp$Z.Roll <- as.numeric(Data_exp$Z.Roll)
Data_exp$Total.Rotation <- as.numeric(Data_exp$Total.Rotation)


#Experimental Likert only, with likert rating corrections to -3 to 3. Includes runs with botched data collection
Data_Likert_exp <- Data_avg %>% filter(Condition != "Control (first)" & Condition != "Control (last)")
  
Data_Likert_exp$Median.Rating = Data_Likert_exp$Median.Rating - 4
Data_Likert_exp$Confidence = Data_Likert_exp$Confidence - 4
Data_Likert_exp$Obstacle.location = Data_Likert_exp$Obstacle.location - 4
Data_Likert_exp$Obstacle.size = Data_Likert_exp$Obstacle.size - 4
Data_Likert_exp$Awareness = Data_Likert_exp$Awareness - 4

# Control Likert. Includes runs with botched data collection
Data_Likert_ctrl <- Data_avg %>% filter(Condition == "Control (first)" | Condition == "Control (last)")


# Likert Ratings ----------------------------------------------------------
  
#Set default order
defaultOrder = c("Control (first)", "Control (last)", "No Cues", "Collocated", "HUD", "Combined")
  

# calculate and plot mean Likert rating across participants for each experimental condition
graph_Ratings <- ddply(Data_Likert_exp, .(Condition), summarise, med = median(Median.Rating))

FigLikert <-  Data_Likert_exp %>%
  mutate(Condition = factor(Condition, levels=defaultOrder)) %>%  #Sets correct order
  ggplot(aes(x = Condition, y = Median.Rating, color = Condition))+
    geom_boxplot(outlier.shape = NA)+
    geom_jitter(width = 0.15)+
    theme(legend.position = 'none')+
    ggtitle("Median Likert Ratings for Experimental Conditions (-3 to 3)")+
    geom_label(data = graph_Ratings, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigLikert)

# do the same for control condition

graph_Ratings_ctrl <- ddply(Data_Likert_ctrl, .(Condition), summarise, med = median(Median.Rating))

FigLikertCtrl <-  Data_Likert_ctrl %>%
  mutate(Condition = factor(Condition, levels=defaultOrder)) %>%
  ggplot(aes(x = Condition, y = Median.Rating, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Median Likert Ratings for Control Conditions (1 to 7)")+
  geom_label(data = graph_Ratings_ctrl, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigLikertCtrl)



# Quantitative Data -------------------------------------------------------


#TIME
#Graphing times by condition
#Box & Whisker, Mean
graph_time <- ddply(Data_avg_noErr, .(Condition), summarise, mean = mean(Calibrated.Time))

FigTime <-  Data_avg_noErr %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = Calibrated.Time, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Times by Condition")+
  geom_label(data = graph_time, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Time (s)")

print(FigTime)

#Plot total time by participant ID to find outliers
graph_distByID <- ddply(Data_avg_noErr, .(Participant.ID), summarise, mean = mean(Calibrated.Time))

figTimeByID <-  Data_avg_noErr %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = Calibrated.Time, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Time by Participant ID")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Time (s)")

print(figTimeByID)

#PERCENTAGE OF PREFERRED WALKING SPEED
#Box & Whisker, Mean
graph_ppws <- ddply(Data_avg_noErr, .(Condition), summarise, mean = mean(PPWS))

FigPPWS <- Data_avg_noErr %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = PPWS, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15, height = 0)+
  theme(legend.position = 'none')+
  ggtitle("Percentage of Preferred Walking Speed (PPWS) by Condition")+
  geom_label(data = graph_ppws, aes(x = Condition, y = mean, label = paste0(round(mean, digits=2), "%"), fontface="bold"), size = 5)

print(FigPPWS)


#ERRORS
#Box & Whisker, Mean
graph_errors <- ddply(Data_avg_noErr, .(Condition), summarise, mean = mean(Errors))

FigErrors <- Data_avg_noErr %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = Errors, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15, height = 0)+
  theme(legend.position = 'none')+
  ggtitle("Errors by Condition")+
  geom_label(data = graph_errors, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)

print(FigErrors)


#DISTANCE
graph_distance <- ddply(Data_exp, .(Condition), summarise, mean = mean(Calibrated.Distance))

FigDistance <-  Data_exp %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = Calibrated.Distance, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Distance by Condition")+
  geom_label(data = graph_distance, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total Distance Travelled (m)")

print(FigDistance)

#Plot total distance by participant ID to find outliers
graph_distByID <- ddply(Data_exp, .(Participant.ID), summarise, mean = mean(Calibrated.Distance))

figDistByID <-  Data_exp %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = Calibrated.Distance, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Distance Travelled by Participant ID")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Distance travelled (m)")

print(figDistByID)

#AVERAGE SPEED
graph_speed <- ddply(Data_exp, .(Condition), summarise, mean = mean(Average.Speed))

figSpeed <-  Data_exp %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = Average.Speed, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Average Speed by Condition")+
  geom_label(data = graph_speed, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Average Speed (m/s)")

print(figSpeed)


#ROTATION
#X Rotation/Pitch
graph_rotX <- ddply(Data_exp, .(Condition), summarise, mean = mean(X.Pitch))

figRotX <-  Data_exp %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = X.Pitch, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation - Pitch (X)")+
  geom_label(data = graph_rotX, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total change in pitch (degrees)")

print(figRotX)

#Y Rotation/Yaw
graph_rotY <- ddply(Data_exp, .(Condition), summarise, mean = mean(Y.Yaw))

figRotY <-  Data_exp %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = Y.Yaw, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation - Yaw (Y)")+
  geom_label(data = graph_rotY, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total change in yaw (degrees)")

print(figRotY)

#Z Rotation/Roll
graph_rotZ <- ddply(Data_exp, .(Condition), summarise, mean = mean(Z.Roll))

figRotZ <-  Data_exp %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = Z.Roll, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation - Roll (Z)")+
  geom_label(data = graph_rotZ, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total change in roll (degrees)")

print(figRotZ)

#Total Rotation
graph_rotTot <- ddply(Data_exp, .(Condition), summarise, mean = mean(Total.Rotation))

figRotTot <-  Data_exp %>%
  mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
  ggplot(aes(x = Condition, y = Total.Rotation, color = Condition))+
  geom_boxplot(outlier.shape = NA)+
  #geom_point()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation - Total")+
  #geom_label(data = graph_rotTot, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total change in rotation (degrees)")

print(figRotTot)


#Plot total rotation by participant ID to find outliers
graph_RotByID <- ddply(Data_exp, .(Participant.ID), summarise, mean = mean(Total.Rotation))

figRotByID <-  Data_exp %>%
  #mutate(Participant.ID = factor(Participant.ID, levels=defaultOrder )) %>%
  ggplot(aes(x = Participant.ID, y = Total.Rotation, color = Participant.ID))+
  geom_point()+
  #geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Rotation - Total")+
  #geom_label(data = graph_RotByID, aes(x = Participant.ID, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
  scale_y_continuous(name="Total change in rotation (degrees)")

print(figRotByID)
