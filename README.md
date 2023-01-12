# AROA-Trajectory-Analysis

This repository holds the data and analysis code for "Using augmented reality to cue obstacles for people with low vision."

It has two sections:
  - **Matlab Analysis** uses Matlab R2022B and holds the raw data, the code for examining individual trials, and code for summarization. 
  - **R Analysis** uses R 4.2.0 and holds the summative data and most of the plots used in the paper.

Note that any reference to "Collocated" indicates world-locked cues, and to "HUD" indicates heads-up cues.

---

## Matlab Analysis

### Folder Breakdown
 - **Plotting Scripts** - holds Matlab scripts for data analysis. See "Data Plotting" and "Data Processing" below.
 - **PosRawData** - holds raw data for each participant as text files. Each subfolder contains one text file per trial. See "Raw Data Breakdown" for more information.
 - **PosPCADataV2** - holds processed data for each participant as CSV files. Each subfolder contains one CSV per trial. See "Data Processing" for more information.
 - **PosFiguresV2** - holds graphs of participant paths during each trial as PNGs and Matlab figures. Each participant subfolder has a "Position" folder and a "Rotation" folder, with four images per trial: PNG and Matlab figure of side-on view, and the same for top-down view. "Position" images mark the participant's path with dots indicating position at every 0.5 seconds, whereas "Rotation" images feature an arrow showing the participant's rotation every 0.5s.  This folder also holds an "Empty Layout" folder showing layouts with no participant. 
 - **Interval Summaries** - holds PNGs, Matlab figures, and supplementary text files with histograms of measures across all participants. Useful for e.g. determining average delay in logging time (see "t" for time intervals.) Text files contain outlier values and locations.
 - **SummaryStatsV2** - holds summary stats for each participant. One CSV per participant. See "Data Processing" below for more detail.


### Raw Data Breakdown

File structure for raw data should be as follows, from top-level to bottom:

1. Raw data folder
2. Folder for each participant, titled [yy-mm-dd OA##] (e.g. "22-02-16 OA01").
3. One text file per trial, with titles as generated by Experiment Logger (e.g. "2022-02-16_03-15-26-PM_No Cues_Layout 2_Forward").

Trial data is separated by a semicolon (and a space for most strings). Columns are as follows:
 - **Log Type** - Whether logging was done in Update or Fixed Update in Unity. All data uses Fixed.
 - **Cue Condition** - The cue condition: No Cues, Collocated (world-locked), HUD (head-locked), or Combined.
 - **Layout** - The layout number used. Integer between 1 and 8.
 - **Direction** - Whether the trial was Forward or Backward
 - **Time** - Time since start of trial. Note that raw data starts at the first recorded time after 0, whereas fixed data is set to startL at 0.
 - **Position X/Y/Z** - Location coordinates of HoloLens in meters
 - **Rotation X/Y/Z** - Rotation of HoloLens in degrees
 - **Eye Tracking Enabled** - Boolean of whether eye tracking is enabled. *Not used.*
 - **Eye Tracking Data Valid** - Boolean of whether eye tracking data is valid. *Not used.*
 - **Gaze Direction X/Y/Z, Eye Movement X/Y/Z** - data related to eye movement and total gaze vector. *Not used.*
 - **HUD Cue Up/Right/Down/Left** - Boolean of whether each heads-up cue was enabled.

Raw data files also have "Stopped logging at [end time]" at the bottom.
 
### Data Processing
First, run **export_PCA_alt** to turn the raw data into processed CSVs. This includes setting initial X, Y, and Z values to 0, realigning along the axis of maximal variance so that Z always represents moving down the hallway, removing duplicate entries, deleting data after Z = 15 (when the participant has crossed the finish line), and removing OA07 and OA11 which had corrupted data.

Second, **summary_stats_exporter** can summarize key statistics for each participant. It iterates through each participant's trials and creates CSVs with the following attributes (one row per trial):
 - **Condition** - as per Cue Condition above
 - **Direction** - as per Direction above
 - **Total Distance** - distance travelled per trial
 - **Total Time** - time per trial
 - **Average Speed** - average speed per trial
 - **X/Y/Z Rotation** - the absolute sum of rotation in the X, Y, and Z directions. (e.g. if a participant turned their head right 45 degrees and then back to the left 45 degrees, the total rotation would be 90 degrees.)
 - **Total Rotation** - the sum of X, Y, and Z rotation
 - **Percent Stopped** - the percentage of the trial for which a participant was moving < 0.1 m/s
 - **Percent Slowed** - the percentage of the trial for which a participant was moving < 0.3 m/s
 - **Speed Variance** - the variance of the participant's speed
 - **Speed Variance Corrected** - the variance of the participant's speed, divided by their average velocity to account for increased variance at higher speeds
 
These data were manually added to the "AROA Main Study 2_Participant Tracking - Experiment Data_8-10-22" document used as the input into the R Analysis portion of the codebase.

### Data Plotting
Plotting is done via **plotByName** and its helper functions. This function takes in a filename, a boolean for top-down or side-on, and a boolean for plotting position or rotation, and plots the layout and participant's path. Helper functions include **lookupHeight** to look up a participant's height in inches (hardcoded); **plotSpeedScaledCircles** and **plotPathRotation** to add position/rotation indicators every 0.5 seconds along the path; and **overlayObstacles** to add the appropriate obstacles based on layout and orientation.  

Example position plot:

![Example position plot](https://user-images.githubusercontent.com/5995674/202317362-436e1cd8-45a3-4a7f-8a37-29141d286f40.png)

Note that **plotAll** can be used to call plotByName repeatedly to iterate through all participants; while **plotEmpty** can be used to draw an empty layout, with no participant data.  **plotRawRotation** can plot rotation output in X, Y, and Z against time. 

Finally, **sumIntervals** can create a histogram of intervals across all participants. This is helpful for confirming results and finding outliers in e.g. processing time or distance. (If there is a very large interval, it likely indicates that the HoloLens lost tracking for some period of time.)

Example interval summary plot (time intervals):

![Example interval summary plot](https://user-images.githubusercontent.com/5995674/202317560-b3c6f834-5b7c-42cb-9e0f-bc58e7b5c3cd.png)

---

---

## R Analysis

### Folder Breakdown
Here is a breakdown of the files and subfolders in R Analysis.

- Folders
  - **Plots** - a folder to hold all plots generated via R, sorted by type.
  - **Tests** - a folder to hold all tests generated via R. Additional sub-analyses of "Preferred" conditions can be found in the Preferred subfolder.
  - **Pilot** - contains data, scripts, and results for Pilot study. *(Work in progress; graphs in original submission created via Google Sheets.)*
- Data
  - **AROA Main Study 2_Participant Tracking - Experiment Data_8-10-22** - The main source of raw data for R analysis. See "Raw Data Breakdown" below.
  - **Data_avg** - Cleaned data, with forward and backward runs combined.
  - **Data_noErr** - Cleaned data, but with the two participants excluded from quantitative trials (07 and 11) filtered out.
  - **Data_avg_noErr** - Cleaned data, with forward and backward runs combined and disqualified participants excluded.
- Scripts
  - **AROA Analysis v3.3** - Master script. Creates above datasets from the raw data, calls below functions to create all plots and tests.
  - **friedmanTests** - Runs Friedman and/or Wilcox tests on likert rating answers, and exports plots.
  - **friedmanControl** - As above, but for control condition only.
  - **plotAndAnova** - Creates a plot and conducts ANOVA analysis for quantitative elements (e.g. time, distance) against cue condition.
  
### Raw Data Breakdown

Here are the columns in AROA Main Study 2_Participant Tracking - Experiment Data_8-10-22. There's one row per trial. Note that columns marked with an asterisk are not available for the Control condition.

 - **Participant ID** - Participant ID string, e.g. "OA01."
 - **Eye calibration success** - Boolean indicating whether eye calibration worked for that participant.
 - **HUD adjustment** - String indicating whether the heads-up cues needed any adjustment to accommodate a lack of vision in one eye. Either "none" or number of times the cues were condensed and moved left or right.
 - **White Cane** - Boolean indicating whether the participant used a white cane.
 - **PWS Average Time** - Double indicating preferred walking speed average time in seconds.
 - **Preferred Walking Speed** - Double indicating the average preferred walking speed in meters per second.
 - **Condition** - String indicating cue condition. Control (first), Control (last), No Cues, Collocated, HUD, or Combined.
 - **Forward or Backward** - String indicating direction. "Forward" or "Backward".
 - **Layout** - Integer indicating layout (1-8).
 - **Calibrated Distance*** - Double indicating true distance walked by the participant in each trial between the starting and ending lines, in meters.
 - **Calibrated Time** - Double indicating time taken to walk from starting to ending line, in seconds.
 - **Average Speed*** - Double indicating average speed of the participant based on calibrated distance and time, in meters per second.
 - **X Pitch/Y Yaw/Z Roll*** - Double indicating total degrees of rotation in X/Y/Z directions.
 - **Total Rotation*** - Sum of X, Y, and Z rotation.
 - **Order** - Integer indicating what order the trials ocurred in for each participant. (1-6)
 - **PPWS** - Double indicating percentage of preferred walking speed for each trial. (Format: 50%)
 - **Errors** - Integer indicating number of errors committed per trial.
 - **Median Rating** - Double indicating the median of the Likert ratings for each trial.
 - **Confidence/Obstacle location/Obstacle size/Awareness** - Integers indicating participant's Likert rating for each trial.
 - **Preferred Condition** - String indicating whether each condition was the participant's preferred condition. "Yes" or "No" for world-locked, heads-up, and combined; "N/A" for control and no cues.
 - **rotSpeedX/Y/Z*** - Average rotation speed in the X/Y/Z direction, in degrees per second.
 - **Percent Stopped/Slowed*** - Double indicating percentage of time each participant was moving less than 0.1 m/s or 0.3 m/s, respectively. (Format: 0.50)
 - **Speed Variance*** - Double indicating the variance of the participant's speed in each trial.
 - **Speed Variance Corrected*** - As above but divided by the participant's average speed.
 


### Data Processing

Here are the steps taken to process the raw data as given above. This is done in AROA Analysis v3.3R.

1. Non-numerical data such as percenctage signs and commas are removed.
2. The "N/As" in data columns are replaced with 9999 to keep them numerical.
3. The Likert scores for all non-control conditions are changed from 1 to 7 to -3 to 3 by subtracting 4. This is because the non-control conditions are compared against the control condition (with 0 = same as the control).
4. Data_avg is created by averaging forward and backward runs for each trial, then averaging the Control (first) and Control (last) trials.
5. Data_avg_noErr is created by removing any participants with NaN marked (indicating that the HoloLens did not record properly for one or more of their trials).
6. Data_noErr is created by removing any participants with NaN marked, but leaving forward and backward/Control (first) and Control (last) intact.

For information on how Friedman and ANOVA tests were run, see the relevant scripts.

Note that the code also includes means of analyzing the data based on each participant's cue preference, but these are not used in the paper. 

### Data Plotting
Plotting is done primarily in the friedmanTests, friedmanControl, and plotAndAnova scripts.

Example Likert plot (in this case, Confidence ratings by condition): 

![Confidence Ratings](https://user-images.githubusercontent.com/5995674/203158946-892f06c0-c10f-4e37-9451-732b41b555bc.png)

Example quantitative plot (Percentage of Preferred Walking Speed by condition):

![PPWS by Condition](https://user-images.githubusercontent.com/5995674/203159184-a16cfcf9-f54f-49f2-bcb4-435147e7625d.png)
