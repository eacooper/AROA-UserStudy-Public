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

source("plotPilot.R")

# load in data
PilotData = read.csv("Pilot Study Data.csv",header=T)

c("Noticed Obstacles", "Know Location", "Know Size", "Cue Helped Notice", 
  "Cue Helped Navigation", "Not Obscuring", "Not Distracting")

metric <- c(rep("Noticed Obstacles", 4), rep("Know Location", 4), rep("Know Size", 4), 
            rep("Cue Helped Notice", 4), rep("Cue Helped Navigation", 4), rep("Not Obscuring", 4), 
            rep("Not Distracting", 4))

condition <- c(rep("Control", 7), rep("World-Locked", 7), rep("Heads-Up", 7), rep("Combined", 7))



plotPilot("Participant A", PilotData, "A")


