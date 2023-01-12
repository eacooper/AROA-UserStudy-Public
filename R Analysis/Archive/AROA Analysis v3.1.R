# load libraries for plotting
# install.packages("groundhog")
# install.packages("ez")
# install.packages("rlang")
# install.packages("tidyverse")
# install.packages("gridExtra")
#install.packages("svglite")


# may not need all these these packages, but loading them now for simplicity
library(ez)
library(plyr)
library(dplyr)
library(rlang)
library(tidyverse)
library(gridExtra)
library(ggplot2)
library(svglite)

source("friedmanTests.R")
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
Data$Median.Rating[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] = Data$Median.Rating[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] - 4
Data$Confidence[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] = Data$Confidence[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] - 4
Data$Obstacle.location[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] = Data$Obstacle.location[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] - 4
Data$Obstacle.size[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] = Data$Obstacle.size[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] - 4
Data$Awareness[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] = Data$Awareness[Data$Condition != "Control (first)" & Data$Condition != "Control (last)"] - 4


# Define Data Sets ---------------------------------------------
# Data: whole dataset. Percent signs and commas removed, Likert scores for experimental conditions correct from 1:7 to -3:3
# Data_avg: forward and backward runs combined
# Data_avg_noErr: as above but with the two excluded participants filtered out, and all made numeric
# Data_noErr: as Data but with two excluded participants filtered out, all made numeric (primarily used for forward/backward testing)
# OLD: Data_exp: Data_avg_noErr, but experimental conditions only
# OLD: Data_ctrl: Data_avg_noErr, but control conditions only
# OLD: Data_Likert_exp: Data_Avg but with corrected Likert. Includes conditions with discarded times
# OLD: Data_Likert_ctrl: Data_Avg but control only. Includes conditions with discarded times.


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


#Run plots and Friedman Tests from a separate R script

friedmanTests("Median Ratings", "./Tests./Likert Ratings_Median.txt", Data_avg, "Median.Rating")
friedmanTests("Confidence Ratings", "./Tests./Likert Ratings_Confidence.txt", Data_avg, "Confidence")
friedmanTests("Obstacle Location Ratings", "./Tests./Likert Ratings_Obstacle Location.txt", Data_avg, "Obstacle.location")
friedmanTests("Obstacle Size Ratings", "./Tests./Likert Ratings_Obstacle Size.txt", Data_avg, "Obstacle.size")
friedmanTests("Awareness Ratings", "./Tests./Likert Ratings_Awareness.txt", Data_avg, "Awareness")


# # do the same for control condition
# graph_Ratings_ctrl <- ddply(Data_Likert_ctrl, .(Condition), summarise, med = median(Median.Rating))
# 
# FigLikertCtrl <-  Data_Likert_ctrl %>%
#   mutate(Condition = factor(Condition, levels=defaultOrder)) %>%
#   ggplot(aes(x = Condition, y = Median.Rating, color = Condition))+
#   geom_boxplot(outlier.shape = NA)+
#   geom_jitter(width = 0.15)+
#   theme(legend.position = 'none')+
#   ggtitle("Median Likert Ratings for Control Conditions (1 to 7)")+
#   geom_label(data = graph_Ratings_ctrl, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)
# 
# print(FigLikertCtrl)


# Quantitative Data -------------------------------------------------------


#TIME
#Graphing times by condition
#Box & Whisker, Mean


# graph_time <- ddply(Data_avg_noErr, .(Condition), summarise, mean = mean(Calibrated.Time))
# 
# FigTime <-  Data_avg_noErr %>%
#   mutate(Condition = factor(Condition, levels=defaultOrder )) %>%
#   ggplot(aes(x = Condition, y = Calibrated.Time, color = Condition))+
#   geom_boxplot(outlier.shape = NA)+
#   #geom_jitter(width = 0.15)+
#   theme(legend.position = 'none', axis.title.x = element_blank(), axis.text.x = element_text(size = 12))+
#   ggtitle("Times by Condition")+
#   #geom_label(data = graph_time, aes(x = Condition, y = mean, label = round(mean, digits=2), fontface="bold"), size = 5)+
#   scale_y_continuous(name="Time (s)", limits = c(10,40))
# 
# 
# print(FigTime)
# ggsave("Times by Condition_all.svg", path = "./Plots")
# ggsave("Times by Condition_all.eps", path = "./Plots")
# ggsave("Times by Condition_all.png", path = "./Plots")
# print("Mean times by condition:")
# print(graph_time)

plotAndAnova("Time by Condition", "./Tests./Time.txt", "./Plots./Time", Data_avg_noErr, "Calibrated.Time", "Time (s)", c(10,40))



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





#PPWS -------------------------------------

plotAndAnova("PPWS by Condition", "./Tests./PPWS.txt", "./Plots./PPWS", Data_avg_noErr, "PPWS", "Percentage of Preferred Walking Speed")




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


