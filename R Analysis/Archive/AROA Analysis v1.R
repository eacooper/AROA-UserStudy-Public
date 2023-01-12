# load libraries for plotting
# install.packages("groundhog")
# install.packages("ez")
# install.packages("rlang")
# install.packages("tidyverse")
# install.packages("gridExtra")


# may not need all these these packages, but loading them now for simplicity
# library(groundhog)
library(ez)
library(plyr)
library(dplyr)
library(rlang)
library(tidyverse)
library(gridExtra)
library(ggplot2)
#groundhog.library('rlang','2022-06-01') 
#groundhog.library('tidyverse', '2022-06-01')
#groundhog.library('gridExtra', '2022-06-01') 

# load in data
Data = read.csv("AROA Main Study 2_Participant Tracking - Experiment Data_7-1-22.csv",header=T)

# reorder conditions


# Likert Ratings ----------------------------------------------------------


# we're going to plot ratings, so just grab the rows in which the walk direction was Forward, since the Backward rows are identical
Data_Ratings <- Data %>% filter(Forward.or.Backward == "Forward" & Condition != "Control (first)" & Condition != "Control (last)")
Data_Ratings$Median.Rating = Data_Ratings$Median.Rating - 4

graph_Ratings <- ddply(Data_Ratings, .(Condition), summarise, med = median(Median.Rating))

# calculate and plot mean Likert rating across participants for each condition
FigLikert <-  Data_Ratings %>%
  ggplot(aes(x = Condition, y = Median.Rating, color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Median Likert Ratings for Cue Conditions")+
  geom_label(data = graph_Ratings, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5, hjust = 1, nudge_x = 0.3)


print(FigLikert)

#Now plot likert scale for control conditions only
Data_Ratings_Control <- Data %>% filter(Forward.or.Backward == "Forward" & Condition == "Control (first)" | Condition == "Control (last)")
graph_Ratings_Control <- ddply(Data_Ratings_Control, .(Condition), summarise, med = median(Median.Rating))

FigLikertControl <- Data_Ratings_Control %>%
  ggplot(aes(x = Condition, y = Median.Rating, color = Condition))+
  geom_boxplot()+
  geom_jitter(width=0.15)+
  theme(legend.position = 'none')+
  ggtitle("Median Likert Ratings for Control Conditions")+
  geom_label(data = graph_Ratings_Control, aes(x = Condition, y = med, label = med, fontface = "bold"), size = 5)

print(FigLikertControl)

#Fig2 <-  Data_Ratings %>%
#  ggplot(aes(x = Condition, y = Median.Rating, color = Condition))+
#  geom_bar(position = "dodge",
#           stat = "summary",
#           fun = "mean")+
#   geom_jitter(width = 0.15)

#print(Fig2)

# calculate averages and report in console
Data_Ratings %>%
  group_by(Condition) %>%
  summarise_at(vars(Median.Rating), list(name = mean))

# run a 1 way within subjects ANOVA to ask whether the ratings differ across conditions
# NOTE: ANOVA is actually not correct for ordinal data

anova_result = ezANOVA(
  data = Data_Ratings
  , dv = .(Median.Rating)
  , wid = .(Participant.ID)
  , within = .(Condition)
)

print(anova_result)

#Filtering by white cane use
Data_Ratings_Cane <- Data_Ratings %>% filter(White.Cane == "Yes")
Data_Ratings_NoCane <- Data_Ratings %>% filter(White.Cane == "No")

#Cane Users
graph_Ratings_Cane <- ddply(Data_Ratings_Cane, .(Condition), summarise, med = median(Median.Rating))

FigLikertCane <-  Data_Ratings_Cane %>%
  ggplot(aes(x = Condition, y = Median.Rating, color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Median Likert Ratings for Cue Conditions - White Cane Users")+
  geom_label(data = graph_Ratings_Cane, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigLikertCane)

#Non-Cane Users
graph_Ratings_NoCane <- ddply(Data_Ratings_NoCane, .(Condition), summarise, med = median(Median.Rating))

FigLikertNoCane <-  Data_Ratings_NoCane %>%
  ggplot(aes(x = Condition, y = Median.Rating, color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Median Likert Ratings for Cue Conditions - Non-White Cane Users")+
  geom_label(data = graph_Ratings_NoCane, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigLikertNoCane)


#Likert Ratings for Control Conditions
Data_Ratings_Control <- Data %>% filter(Forward.or.Backward == "Forward" & Condition == "Control (first)" | Condition == "Control (last)") 


# Quantitative Data -------------------------------------------------------


#TIME
#Graphing times by condition
#Box & Whisker, Median
graph_time <- ddply(Data, .(Condition), summarise, med = median(Time))

FigTime <-  Data %>%
  ggplot(aes(x = Condition, y = Time, color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Times by Condition")+
  geom_label(data = graph_time, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigTime)

#Bar Chart, Mean
graph_time_bar <- ddply(Data, .(Condition), summarise, mean = mean(Time), timeSD = sd(Time))

FigTimeBar <- Data %>%
  ggplot(aes(x = Condition, y = Time, color = Condition))+
  geom_bar(position = "dodge",
           stat = "summary",
           fun = "mean")+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Times by Condition")+
  geom_label(data = graph_time_bar, aes(x = Condition, y = mean, label = mean, fontface="bold"), size = 5)
  #geom_errorbar(data = graph_time_bar, aes(x = Condition, ymin = mean - timeSD, ymax = mean + timeSD))

print(FigTimeBar)

#ggplot(Data, aes(x = Condition, y = Time, color = Condition)) + 
ggplot(Data)+
  geom_bar(aes(x = Condition, y = Time, color = Condition), position = "dodge", stat = "summary", fun = "mean")+
  geom_point(aes(x = Condition, y = Time, color = Condition))+
  #geom_jitter(width = 0.15)+
  geom_errorbar(data = graph_time_bar, aes(x = Condition, ymin = mean - timeSD, ymax = mean + timeSD), width=0.4, colour="orange", alpha=0.9, size=1.3)+
  geom_label(data = graph_time_bar, aes(x = Condition, y = mean, label = mean, fontface="bold"), size = 5)+
  theme(legend.position = 'none')+
  ggtitle("Times by Condition")
  

#PERCENTAGE OF PREFERRED WALKING SPEED
#Graphing percentage of preferred walking speed by condition
#Remove % signs
Data$PPWS = gsub("%$", "", Data$PPWS)
Data$PPWS = as.numeric(Data$PPWS)
graph_ppws <- ddply(Data, .(Condition), summarise, med = median(PPWS))

FigPPWS <- Data %>% 
  ggplot(aes(x = Condition, y = PPWS, color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Percentage of Preferred Walking Speed by Condition")+
  geom_label(data = graph_ppws, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigPPWS)

#ERRORS
#Graphing errors by condition
graph_errors <- ddply(Data, .(Condition), summarise, avg = mean(Errors))

FigErrors <- Data %>%
  ggplot(aes(x = Condition, y = Errors, color = Condition))+
  geom_bar(position = "dodge",
           stat = "summary", 
           fun = "mean")+
  geom_jitter(height=0, width = 0.25)+
  theme(legend.position = 'none')+
  ggtitle("Errors by Condition")+
  geom_label(data = graph_errors, aes(x = Condition, y = avg, label = avg, fontface="bold"), size=5)

print(FigErrors)

#Graphing distance traveled by condition
#Ignore control conditions since we don't have direct data for them
Data_HoloLens <- Data %>% filter(Condition != "Control (first)" & Condition != "Control (last)")
#Convert total distances from character to numeric
Data_HoloLens$Total.Distance = as.numeric(Data_HoloLens$Total.Distance) 

graph_totalDist <- ddply(Data_HoloLens, .(Condition), summarise, med = median(Total.Distance))

FigDist <-  Data_HoloLens %>%
  ggplot(aes(x = Condition, y = Total.Distance, color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Total Distance Travelled by Condition")+
  geom_label(data = graph_totalDist, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5, hjust = 1, nudge_x = 0.3)

print(FigDist)

#ROTATION
#Remove commas, turn to numeric
Data_HoloLens$X.Rotation..Pitch. = gsub(",", "", Data_HoloLens$X.Rotation..Pitch.)
Data_HoloLens$X.Rotation..Pitch. = as.numeric(Data_HoloLens$X.Rotation..Pitch.)
Data_HoloLens$Y.Rotation..Yaw. = gsub(",", "", Data_HoloLens$Y.Rotation..Yaw.)
Data_HoloLens$Y.Rotation..Yaw. = as.numeric(Data_HoloLens$Y.Rotation..Yaw.)
Data_HoloLens$Z.Rotation..Roll. = gsub(",", "", Data_HoloLens$Z.Rotation..Roll.)
Data_HoloLens$Z.Rotation..Roll. = as.numeric(Data_HoloLens$Z.Rotation..Roll.)
Data_HoloLens$Total.Rotation = gsub(",", "", Data_HoloLens$Total.Rotation)
Data_HoloLens$Total.Rotation = as.numeric(Data_HoloLens$Total.Rotation)

#X Rotation (Pitch)
graph_RotX <- ddply(Data_HoloLens, .(Condition), summarise, med = median(X.Rotation..Pitch.))

FigRotX <-  Data_HoloLens %>%
  ggplot(aes(x = Condition, y = X.Rotation..Pitch., color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("X Rotation (Pitch) by Condition")+
  geom_label(data = graph_RotX, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigRotX)

#Y Rotation (Yaw)
graph_RotY <- ddply(Data_HoloLens, .(Condition), summarise, med = median(Y.Rotation..Yaw.))

FigRotY <-  Data_HoloLens %>%
  ggplot(aes(x = Condition, y = Y.Rotation..Yaw., color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Y Rotation (Yaw) by Condition")+
  geom_label(data = graph_RotY, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigRotY)

#Z Rotation (Roll)
graph_RotZ <- ddply(Data_HoloLens, .(Condition), summarise, med = median(Z.Rotation..Roll.))

FigRotZ <-  Data_HoloLens %>%
  ggplot(aes(x = Condition, y = Z.Rotation..Roll., color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Z Rotation (Roll) by Condition")+
  geom_label(data = graph_RotZ, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigRotZ)

#Total Rotation
graph_RotTotal <- ddply(Data_HoloLens, .(Condition), summarise, med = median(Total.Rotation))

FigRotTotal <-  Data_HoloLens %>%
  ggplot(aes(x = Condition, y = Total.Rotation, color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Total Rotation by Condition")+
  geom_label(data = graph_RotTotal, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigRotTotal)


# Preferred Conditions ----------------------------------------------------


#PREFERRED CONDITIONS
#Filter to only preferred conditions
Data_Preferred <- Data %>% filter(Preferred.Condition == "Yes")
Data_Preferred_Ratings <- Data_Preferred %>% filter(Forward.or.Backward == "Forward")
Data_Preferred_Ratings$Median.Rating = Data_Preferred_Ratings$Median.Rating - 4

#Count of preferred conditions
#graph_preferred_count <- ddply(Data_Preferred_Ratings, .(Condition))

#FigPreferredCount <- Data_Preferred_Ratings %>%
#  ggplot(aes(x = Condition, y = count))


graph_preferred_ratings <- ddply(Data_Preferred_Ratings, .(Condition), summarise, med = median(Median.Rating))

# calculate and plot mean Likert rating across participants for each condition (preferred only)
FigLikertPref <-  Data_Preferred_Ratings %>%
  ggplot(aes(x = Condition, y = Median.Rating, color = Condition))+
  geom_boxplot()+
  geom_jitter(width = 0.15)+
  theme(legend.position = 'none')+
  ggtitle("Median Likert Ratings for Cue Conditions - Preferred Only")+
  geom_label(data = graph_preferred_ratings, aes(x = Condition, y = med, label = med, fontface="bold"), size = 5)

print(FigLikertPref)

#Errors for preferred conditions
graph_errorsPref <- ddply(Data_Preferred, .(Condition), summarise, avg = mean(Errors))

FigErrorsPref <- Data_Preferred %>%
  ggplot(aes(x = Condition, y = Errors, color = Condition))+
  geom_bar(position = "dodge",
           stat = "summary", 
           fun = "mean")+
  geom_jitter(height=0, width = 0.25)+
  theme(legend.position = 'none')+
  ggtitle("Errors by Condition - Preferred Only")+
  geom_label(data = graph_errorsPref, aes(x = Condition, y = avg, label = avg, fontface="bold"), size=5)

print(FigErrorsPref)

#Errors for preferred and control
Data_PrefAndCont <- Data %>% filter(Preferred.Condition != "No" & Condition!=("No Cues"))
graph_errors_PrefAndCont <- ddply(Data_PrefAndCont, .(Condition), summarise, avg = mean(Errors))

FigErrorsPrefAndCont <- Data_PrefAndCont %>%
  ggplot(aes(x = Condition, y = Errors, color = Condition))+
  geom_bar(position = "dodge", stat = "summary", fun = "mean")+
  geom_jitter(height = 0, width = 0.25) + 
  theme(legend.position = 'none')+
  ggtitle("Errors by Condition - Preferred and Control")+
  geom_label(data = graph_errors_PrefAndCont, aes(x = Condition, y = avg, label = avg, fontface="bold"), size=5)

print(FigErrorsPrefAndCont)

