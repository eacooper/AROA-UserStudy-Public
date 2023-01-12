% This script can summarize key statistics for each participant. 
% It iterates through each participant's trials and creates CSVs 
% with the following attributes (one row per trial):

% Participant ID - e.g. OA01
% Condition - one of the four experimental cue conditions
% Direction - Forward or Backward
% Calibrated Distance - distance travelled per trial (after removing data past z = 15)
% Calibrated Time - time per trial (after removing data past z = 15)
% Average Speed - average speed per trial
% X/Y/Z Rotation - the absolute sum of rotation in the X, Y, and Z directions. (e.g. if a participant turned their head right 45 degrees and then back to the left 45 degrees, the total rotation would be 90 degrees.)
% Total Rotation - the sum of X, Y, and Z rotation
% Percent Stopped - the percentage of the trial for which a participant was moving < 0.1 m/s
% Percent Slowed - the percentage of the trial for which a participant was moving < 0.3 m/s
% Speed Variance - the variance of the participant's speed
% Speed Variance Corrected - the variance of the participant's speed, divided by their average velocity to account for increased variance at higher speeds

%clear all;
clear variables;
close all;

%Sets directory path to the raw data folder
datapath = '../PosPCADataV3/';

% Subject directory list
listing = dir([datapath '*OA*' ]);

disp("Listing: ");
disp(listing);

task = 'summary_stats';

% Prepare Summary Stats table for later
summaryStats = array2table(zeros(0, 18)); 
summaryStats.Properties.VariableNames(1:end) = {'Participant ID', 'Condition', 'Direction', 'Layout', ...
            'Calibrated Distance (m)', 'Calibrated Time (s)', 'Average Speed (m/s)', ...
            'X Rotation Sum (degs)', 'Y Rotation Sum (degs)', 'Z Rotation Sum (degs)', 'Total Rotation (degs)', ...
            'Rotation Speed X (deg/s)', 'Rotation Speed Y (deg/s)', 'Rotation Speed Z (deg/s)', ...
            'Percent Stopped', 'Percent Slowed', 'Speed Variance', 'Speed Variance Corrected'};

for s = 1:length(listing) %Goes through all folders
    
    if listing(s).isdir && listing(s).name ~= "OA21_22-06-15"  % Exclude test data
        
        dirname = listing(s).name;

        % File list
        files = dir([datapath dirname '/*.csv']);

        fileName = files(1).name;
        sbjFileName = fileName(1:13);
        participantID = fileName(1:4);

        % Create blank structures of the appropriate length
        ParticipantID = cell(length(files), 1, 1);
        Condition = cell(length(files), 1, 1);
        Direction = cell(length(files), 1, 1);
        Layout = zeros(length(files), 1);
        TotalDist = zeros(length(files), 1);
        TotalTime = zeros(length(files), 1);
        AverageVelocity = zeros(length(files), 1);
        RotationX = zeros(length(files), 1);
        RotationY = zeros(length(files), 1);
        RotationZ = zeros(length(files), 1);
        TotalRotation = zeros(length(files), 1);
        RotSpeedX = zeros(length(files),1);
        RotSpeedY = zeros(length(files),1);
        RotSpeedZ = zeros(length(files),1);
        percentStopped = zeros(length(files), 1);
        percentSlowed = zeros(length(files), 1);
        speedVariance = zeros(length(files), 1);
        speedVarCorrected = zeros(length(files), 1);

        % For each file for this subject
        for f = 1:length(files)
            fileName = files(f).name;
            % Read in data from csv
            pData = readtable([datapath sbjFileName '/' fileName]);
            
            % Get trial type and layout from table
            trialType = string(pData.TrialType(1));
            layoutNum = pData.LayoutNumber(1);

            % Look up subject height
            subjHeightMeters = lookupHeight(participantID); 

            % Get core data
            x = pData.X;
            y = pData.Y + subjHeightMeters;
            z = pData.Z;
            t = pData.Time;
            upHUD = pData.UpHUD;
            rightHUD = pData.RightHUD;
            downHUD = pData.DownHUD;
            leftHUD = pData.LeftHUD;
            rotationX = pData.RotationX;
            rotationY = pData.RotationY;
            rotationZ = pData.RotationZ;

            direction = pData.Direction(1);

            if (direction == "Backward")
                x = -x;
                z = max(z) - z;
            end
        
            % Get the differences between adjacent elements
            xDiffs = diff(x);
            yDiffs = diff(y);
            zDiffs = diff(z);
            tDiffs = diff(t);
            
            % Calculate total distance
            dists = sqrt(xDiffs.^2 + zDiffs.^2);
            totalDist = sum(dists);

            %Total time of the run
            totalTime = t(end);

            %Average velocity
            aveVel = totalDist/totalTime;
           
            %Calculate speeds and percent of time stopped and slowed
            stopCount = 0;
            slowCount = 0;
            speeds = zeros(1, length(dists));

            for n = 1:length(dists)
                speeds(n) = dists(n)/tDiffs(n);
                %Speed less than 0.1 is considered a stop; less than 0.3 is slowed
                if (abs(speeds(n)) <= 0.1) 
                    stopCount = stopCount + 1;
                    %disp("Speed of " + speeds(n) + " found at position " + n + " in file " + files(f).name);
                end
                if (abs(speeds(n)) <= 0.3)
                    slowCount = slowCount + 1;
                end
            end
            percentStoppedTrial = 100*stopCount/length(speeds);
            percentSlowedTrial = 100*slowCount/length(speeds);

            % Calculate speed variance; divide by average velocity to get
            % corrected version
            speedVarianceTrial = var(speeds);
            speedVarCorrectedTrial = var(speeds)/aveVel;  %Corrected by dividing by mean speed

            %disp("For file " + files(f).name + ": Length = " + length(speeds) + "; Stop count = " + stopCount + "; Slow count = " + slowCount);            
            %disp("Percent Stopped = " + percentStoppedTrial + "; Percent Slowed = " + percentSlowedTrial + "; Speed Variance = " + speedVarianceTrial);


            % Get the differences between adjacent rotation elements of the vector
            % We use trig here to account for going from 0 to 360 degrees
            % and back
            rotatoXDiffs = atan2(sin((diff(rotationX))*pi/180),cos((diff(rotationX))*pi/180))*180/pi;
            rotatoYDiffs = atan2(sin((diff(rotationY))*pi/180),cos((diff(rotationY))*pi/180))*180/pi;
            rotatoZDiffs = atan2(sin((diff(rotationZ))*pi/180),cos((diff(rotationZ))*pi/180))*180/pi;


            %Calculate cumulative differences for each vector
            rotatoXCumuSum = sum(abs(rotatoXDiffs));
            rotatoYCumuSum = sum(abs(rotatoYDiffs));
            rotatoZCumuSum = sum(abs(rotatoZDiffs));

            %Calculate rotation speed for each vector
            rotSpeedX = rotatoXCumuSum/totalTime;
            rotSpeedY = rotatoYCumuSum/totalTime;
            rotSpeedZ = rotatoZCumuSum/totalTime;

            % The num2cell() is needed because the previous format
            % won't support writing both numbers and strings to the
            % csv file at the same time
            
            ParticipantID{f} = participantID;
            Condition{f} = trialType;
            Direction{f} = direction;
            Layout(f) = layoutNum;
            TotalDist(f) = totalDist;
            TotalTime(f) = totalTime;
            AverageVelocity(f) = aveVel;
            RotationX(f) = rotatoXCumuSum;
            RotationY(f) = rotatoYCumuSum;
            RotationZ(f) = rotatoZCumuSum;
            TotalRotation(f) = rotatoXCumuSum+rotatoYCumuSum+rotatoZCumuSum;
            RotSpeedX(f) = rotSpeedX;
            RotSpeedY(f) = rotSpeedY;
            RotSpeedZ(f) = rotSpeedZ;
            percentStopped(f) = percentStoppedTrial;
            percentSlowed(f) = percentSlowedTrial;
            speedVariance(f) = speedVarianceTrial;
            speedVarCorrected(f) = speedVarCorrectedTrial;


            % I this is one of the corrupted trajectories, replace
            % everything with a NaN
            if (TotalDist(f) == 0)
                warning('need to exclude corrupted trajectory files')
                TotalDist(f) = "NaN";
                TotalTime(f) = "NaN";
                AverageVelocity(f) = "NaN";
                RotationX(f) = "NaN";
                RotationY(f) = "NaN";
                RotationZ(f) = "NaN";
                TotalRotation(f) = "NaN";
                RotSpeedX(f) = "NaN";
                RotSpeedY(f) = "NaN";
                RotSpeedZ(f) = "NaN";
                percentStopped(f) = "NaN";
                percentSlowed(f) = "NaN";
                speedVariance(f) = "NaN";
                speedVarCorrected(f) = "NaN";
            end

        end
        

        % Write to table
        participantStats = cell2table([ParticipantID, Condition, Direction, num2cell(Layout), ...
            num2cell(TotalDist), num2cell(TotalTime), num2cell(AverageVelocity), ...
            num2cell(RotationX), num2cell(RotationY), num2cell(RotationZ), num2cell(TotalRotation), ...
            num2cell(RotSpeedX), num2cell(RotSpeedY), num2cell(RotSpeedZ), ...
            num2cell(percentStopped), num2cell(percentSlowed), num2cell(speedVariance), num2cell(speedVarCorrected)]);

        %Rearrange rows to No Cues (F,B), Collocated (F,B), HUD (F,B), Combined (F,B)
        participantStats = [participantStats(8,:); participantStats(7,:); participantStats(2,:); participantStats(1,:); ...
            participantStats(6,:); participantStats(5,:); participantStats(4,:); participantStats(3,:)];

        %Label variable names
        participantStats.Properties.VariableNames(1:end) = {'Participant ID', 'Condition', 'Direction', 'Layout', ...
            'Calibrated Distance (m)', 'Calibrated Time (s)', 'Average Speed (m/s)', ...
            'X Rotation Sum (degs)', 'Y Rotation Sum (degs)', 'Z Rotation Sum (degs)', 'Total Rotation (degs)', ...
            'Rotation Speed X (deg/s)', 'Rotation Speed Y (deg/s)', 'Rotation Speed Z (deg/s)', ...
            'Percent Stopped', 'Percent Slowed', 'Speed Variance', 'Speed Variance Corrected'};
        %writetable((participantStats),csvname,'writevariablenames',1);

        % Add to main table
        summaryStats = [summaryStats; participantStats];
            
    end
    
end

% Create summary stats for entire group, meant to combine with
% supplementary data sheet. Should include data in individual summary
% blocks, as well as participant ID (e.g. "OA01").
csvname = strcat('../', "Summary Statistics.csv");
writetable((summaryStats), csvname, 'writevariablenames',1);