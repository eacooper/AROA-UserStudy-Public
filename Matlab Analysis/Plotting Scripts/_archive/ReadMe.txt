Set-Up
- Put all raw data files into a folder named "PosRawData" adjacent to the PositionTrackingScripts folder where the scripts are
ex. if this folder is located at C:/Documents/Plotting/PositionTrackingScripts, then put all the raw data files into C:/Documents/PosRawData

- Keep the .txt files sorted in the folders sorted by participant (the way they come from the Google Drive)
ex. if you were to access a file the path would be 
C:/Documents/PosRawData/AR01_11-17-21/2021-11-17_03-48-14-PM_No Cues_Layout 6.txt

- The Matlab plotting scripts will create a new folders called "PosPCAData" and "PositionPlots" inside whatever folder you put the PositionTrackingScripts folder in.



To run position tracking:
1. Put all folders of raw data into the PositionTracking/Data/raw data folder. 
Keep the data in their folders, ie. PositionTracking/Data/raw data/ARXX_2021_xx_xx

2. Run export_PCA_alt.m to convert data to a graphable form

3. Run posTrackPlot.m to graphs position tracking plots. These will plot them according to participant, 
but can be modifed to sort data according to condition, etc.


UPDATE 12/23 (Dylan):
I set up an "export PCA_alt_withY" feature that preserves the y values in the modified data (so the columns are z, y, x, and t), and a "posTrackPlot_Height_v2" that shows a side-view of the hallway as compared to the original's top-down view. Each is set to export to its own folder. 

Hand-Off 25/05/2022

posTrackPlot_singlePath_Condition_byName.m: Makes a .png of the path a subject takes during a trial run - top-down view. Chooses the file based on name

posTrackPlot_singlePath_Condition_byName_Vertical.m: Makes a .png of the path a subject takes during a trial run - side view. Chooses the file based on name

posTrackPlot_multiPath_Subject.m: Make a .png of all the paths a subject takes across trial runs. However, it's currently only able to accept version 1 trials.

posTrackPlot_singlePath_Condition_byName_gif.m: Makes a .gif of the path a subject takes during a trial run - top-down view. 

gazeTrackPlot_singlePath_Condition_byName_Vertical.m: Makes a .png of the path a subject takes during a trial run and their head rotation vector - top-down view.

gazeTrackPlot_singlePath_Condition_byName_Vertical.m: Makes a .png of the path a subject takes during a trial run and their head rotation vector - side view.

overlayHUDCues.m: Helper function that overlays the HUD activated tracks

plotSpeedScaledCircles.m: Helper function that overlays the speed scaled circles 

collocated_scene_maker.m: Makes a .avi video of the supposed FOV of the participant during one trial run. Currently only has layout 5