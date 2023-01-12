%Returns the interval of a variable. Can also plot to see how uniform they
%are.

function [intervalDiffs] = calcIntervals (fileName, intervalType, plot)

% fileName = file to use, e.g. char("OA10_22-04-11_Collocated_Layout 6_Forward_posTracking.csv")
% intervalType = preferred interval to plot (x, y, time, etc.)
% plot = boolean: plots if true

    close all;

    %Establish data path
    datapath = '../PosPCADataV3/';
    sbjFileName = fileName(1:13);
    participantID = fileName(1:4);

    disp("Now plotting intervals for " + sbjFileName);

    
    %% File Setup

    %Opens the file
    if isfile([datapath sbjFileName '/' fileName])
        disp("File opened");
        %Opens up a figure window
        fig = figure(1);
        ax1 = axes;
        grid on;
        hold on;


            % Read in data from csv
            pData = readtable([datapath sbjFileName '/' fileName]);
            
            % Look up subject height
            subjHeightMeters = lookupHeight(participantID); 

            % Get core data
            x = pData.X;
            y = pData.Y + subjHeightMeters;
            z = pData.Z;
            t = pData.Time;
            %upHUD = pData.UpHUD;
            %rightHUD = pData.RightHUD;
            %downHUD = pData.DownHUD;
            %leftHUD = pData.LeftHUD;
            rotationX = pData.RotationX;
            rotationY = pData.RotationY;
            rotationZ = pData.RotationZ;

            direction = pData.Direction(1);

            if (direction == "Backward")
                x = -x;
                z = max(z) - z;
            end


       % Set interval type according to function input
        if (intervalType == "x")
            intervalDiffs = diff(x);

        elseif (intervalType == "y")
            intervalDiffs = diff(y);

        elseif (intervalType == "z")
            intervalDiffs = diff(z);

        elseif (intervalType == "t")
            intervalDiffs = diff(t);

        elseif (intervalType == "rotationX")
            intervalDiffs = diff(rotationX); 

        elseif (intervalType == "rotationY")
            intervalDiffs = diff(rotationY);

        elseif (intervalType == "rotationZ")
            intervalDiffs = diff(rotationZ);

        elseif (intervalType == "distance")
            intervalDiffs = sqrt(diff(x).^2 + diff(z).^2);

        elseif (intervalType == "speed")
            dists = sqrt(diff(x).^2 + diff(z).^2);
            times = diff(t);
            for n = 1:length(dists)
                speeds(n) = dists(n)/times(n);
            end
            intervalDiffs = speeds;

        else
            disp("Unexpected variable requested.");
            return;
        end

        % Adjust rotation data to remove 330+ degree swings
        if (intervalType == "rotationX" || intervalType == "rotationY" || intervalType == "rotationZ")
            for n = 1:length(intervalDiffs)
                if abs(intervalDiffs(n)) > 330
                    if (intervalDiffs(n) > 0)
                        intervalDiffs(n) = intervalDiffs(n) - 360;
                    else
                        intervalDiffs(n) = intervalDiffs(n) + 360;
                    end
                end
            end
        end



        %% Plotting
        if(plot)
            disp("Plotting histogram");
            histogram(intervalDiffs);
            legend(intervalType);
        end
        
    end
end