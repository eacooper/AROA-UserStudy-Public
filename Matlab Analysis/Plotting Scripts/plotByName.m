% Takes in a CSV file of processed data for one trial and plots it.

function plotByName (fileName, topDown, plotRotation)

% fileName = posPCA CSV file to use. e.g. char("OA10_22-04-11_Collocated_Layout 6_Forward_posTracking.csv")
% topDown -> 1 if top-down graph, 0 if side-on graph
% plotRotation -> 1 if you want to show rotation, 0 for just speed circles

    close all;

    %Establish data path
    datapath = '../PosPCADataV3/';
    sbjFileName = fileName(1:13);
    participantID = fileName(1:4);

    disp("Now plotting " + sbjFileName);

    % Sample rate. Used if scaling circles to speed in Plot Speed Scaled Circles.
    sampRate = 50;
    
    %Colours
    colour1 = [82, 161, 181]./256; %teal
    colour2 = [255, 180, 26]./256; %orange
    colour3 = [230, 26, 113]./256; %rose
    colour4 = [205, 135, 255]./256; %lavender
    colour5 = [175, 255, 117]./256; %honeydew
    
    colours = [colour1; colour2; colour3; colour4; colour5];

%% File Setup

    %Opens the file
    if isfile([datapath sbjFileName '/' fileName])
        %Opens up a figure window
        fig = figure(1);
        %ax1 = axes;
        grid on;
        hold on;
        %Set the scale ratio to be 1
        set(gca,'DataAspectRatio',[1 1 1], 'color', 'none');%'XTick',[], 'YTick', [])
        %Sets the size of the graph in pixels
        set(gcf,'Position',[0, 0, 1800, 450]);%maxX*400,maxY*400]);
        %Resizes the axes within the figure (as a proportion of the total figure size
        set(gca,'OuterPosition',[0.02, 0, 0.97, 0.97])


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

        % Get the differences between adjacent elements
        xDiffs = diff(x);
        %yDiffs = diff(y);
        zDiffs = diff(z);
        %tDiffs = diff(t);

        % Calculate total distance
        dists = sqrt(xDiffs.^2 + zDiffs.^2);
        totalDist = sum(dists);
        
        %Finding out which trial type it is
        if strcmp(trialType, 'No Cues')
            typeID = 1;
            trialString = 'No Cues';
        elseif strcmp(trialType, 'Collocated')
            typeID = 2;
            trialString = 'World-Locked';
        elseif strcmp(trialType, 'Combined')
            typeID = 3;
            trialString = 'Combined';
        elseif strcmp(trialType, 'HUD')
            typeID = 4;
            trialString = 'Heads-Up';
        else
            warning(strcat("Unknown Trial Type!!: ", trialType));
            typeID = 5;
        end

        %% Plotting

        % Top-down plot (aka horizontal)
        if (topDown)

            %Plot base line
            plot(z, -x, 'LineWidth', 1.25, 'Color', [0.5 0.5 0.5]);
    
            %Add circles or rotation vectors
            if (plotRotation == 0)
                fig = plotSpeedScaledCircles(z, x, t, dists, sampRate, fig, colours(typeID, :), 0, 0.5);
            
            else 
                fig = plotPathRotation(fig, x, y, z, t, dists, rotationX, rotationY, rotationZ, direction == "Backward", topDown, 0.5);

            end    

            % Set limits for graph
            minX = 0;
            maxX = 15;
            minY = -0.9;
            maxY = 0.9;
            tick = 0.3;

            typeText = "top down";
            heightVal = 0;
            %hudCuesInput = x;
            
            %Plotting the START/END text
            if (direction == "Backward")
                txt = {'END'};
            else
                txt = {'START'};
            end
            t1 = text (0.1, 1.1, txt);
            t1.FontName = 'Gill Sans MT';
            t1.FontSize = 20;

        else % side-on
            
            %Plot base line
            plot(z, y, 'LineWidth', 1.25, 'Color', [0.5 0.5 0.5]);
    
            %Add circles or rotation vectors
            if (plotRotation == 0)
                 fig = plotSpeedScaledCircles(z, -y, t, dists, sampRate, fig, colours(typeID, :), 0, 0.5);

            else 
                fig = plotPathRotation(fig, x, y, z, t, dists, rotationX, rotationY, rotationZ, direction == "Backward", topDown, 0.5);

            end    

            % Set limits for graph
            minX = 0;
            maxX = 15;
            minY = 0;
            maxY = 2.5;
            tick = 0.5;

            typeText = "side on";
            heightVal = subjHeightMeters;
            %hudCuesInput = -y;

            %Plotting the START/END text
            if (direction == "Backward")
                txt = {'END'};
            else
                txt = {'START'};
            end
            t1 = text (0.1, 2.7, txt);
            t1.FontName = 'Gill Sans MT';
            t1.FontSize = 20;

        end
        
        % Set axes parameters
        xlim([minX maxX]);
        ylim([minY maxY]);
        ax = gca;
        ax.Clipping = 'off';
        ax.FontName = 'Gill Sans MT';
        ax.FontSize = 20;

        % Tick marks
        set(gca,'XTick', [minX:1.5:maxX], 'YTick', [minY:tick:maxY]);

        % Tight border around the graph
        set(gca,'LooseInset',get(gca,'TightInset'));   

        %Surrounding bars for indicating where the hallway is
        borderX = 0:0.1:15;
        borderY1 = minY * ones(length(borderX), 1);
        borderY2 = maxY * ones(length(borderX), 1); 
        plot(borderX, borderY1, 'k', 'Linewidth', 3, 'Color', '#737373');
        plot(borderX, borderY2, 'k', 'Linewidth', 3, 'Color', '#737373');

        %Plotting the 1m scale marking
        refX = 14:0.1:15;
        refY = (borderY2(1)+0.15)*ones(length(refX), 1);
        plot(refX, refY, 'k', 'Linewidth', 2);

        %Plotting the 1m scale text
        txt = {'1m'};
        t1 = text(14.7,refY(1)+0.15,txt);
        t1.FontName = 'Gill Sans MT';
        t1.FontSize = 20;
       

        %Plotting name text
        sbjFileName(5) = ' ';
        sbjFileName(2) = '';
        sbjFileName(1) = '';
        nameText = strcat("Participant ", sbjFileName, ", ", trialString, ", Layout ", num2str(layoutNum), ", " , direction);
        t2 = text(0.25, borderY1(1)-0.5, nameText); 
        t2.FontName = 'Gill Sans MT';
        t2.FontSize = 24;

        %Plotting total distance text (rounded to 2 dps)
        distText = strcat('Total Distance:  ', num2str(round(totalDist*100)/100), 'm');
        t3 = text(13, borderY1(1)+0.6, distText); %text(0.25, -borderY2(1)+2, nameText);
        t3.FontName = 'Gill Sans MT';
        t3.FontSize = 16;

        %Plotting total time elapsed (rounded to 2 dps)
        timeText = strcat('Total Time:', " ", num2str(round(t(end)*100)/100), 's');
        t3 = text(13, borderY1(1)+0.3, timeText); %text(0.25, -borderY2(1)+2, nameText);
        t3.FontName = 'Gill Sans MT';
        t3.FontSize = 16;

        %Plotting average velocity elapsed (rounded to 2 dps)
        %velText = strcat('Average Velocity:', " ", num2str(round(totalDist/t(end)*100)/100), 'm/s');
        %t3 = text(13, borderY1(1)+0.3, velText); %text(0.25, -borderY2(1)+2, nameText);
        %t3.FontName = 'Gill Sans MT';
        %t3.FontSize = 16;


        % Overlay obstacles
        fig = overlayObstacles(fig, layoutNum, topDown, heightVal);        

        % Overlay HUD cues for HUD or Combined conditions
        % Disabled for now
        %if(strcmp(trialType, 'HUD')||strcmp(trialType, 'Combined'))
        %    fig = overlayHUDCues(fig, z, hudCuesInput, upHUD, downHUD, rightHUD, leftHUD, ax1, topDown);
        %end

        % Draw person to help indicate top-down vs side-on
        if topDown %Just draw ellipses representing head and shoulders seen from above
            annotation('ellipse', [0.082 0.415 0.01 0.15], 'FaceColor', 'black'); %Shoulders
            annotation('ellipse', [0.08 0.46 0.015 0.06], 'Color', '#888', 'LineWidth', 2, 'FaceColor', 'black'); %head

            % Draw arrow and arms to indicate direction
            if (direction == "Backward")
                annotation('ellipse', [0.073 0.41 0.015 0.02], 'FaceColor', 'black');
                annotation('ellipse', [0.073 0.55 0.015 0.02], 'FaceColor', 'black');                   
                annotation('arrow', [0.11 0.08], [0.6 0.6])
            else
                annotation('ellipse', [0.086 0.41 0.015 0.02], 'FaceColor', 'black');
                annotation('ellipse', [0.086 0.55 0.015 0.02], 'FaceColor', 'black');                
                annotation('arrow', [0.08 0.11], [0.6 0.6])
            end
            annotation("textbox", [.06 .4 .3 .3], 'String', 'Top-down', 'FitBoxToText', 'on', 'FontSize', 16, 'LineStyle', 'none');

        else % draw a little person
            % head
            annotation('ellipse', [0.075 0.55 0.02 0.08], 'FaceColor', 'black');
            % body
            annotation('ellipse', [0.075 0.35 0.02 0.2], 'FaceColor', 'black');
            % legs
            annotation('rectangle', [0.095 0.181 0.008 0.2], 'FaceColor', 'black', 'Rotation', 15);
            annotation('rectangle', [0.065 0.181 0.008 0.2], 'FaceColor', 'black', 'Rotation', -15);
            % Draw arrow and arm to indicate direction
            if (direction == "Backward")
                annotation('arrow', [0.1 0.07], [0.7 0.7])
                annotation('rectangle', [0.051 0.415 0.008 0.12], 'FaceColor', 'black', 'Rotation', -60);
            else
                annotation('arrow', [0.07 0.1], [0.7 0.7])
                annotation('rectangle', [0.11 0.415 0.008 0.12], 'FaceColor', 'black', 'Rotation', 60);
            end
            annotation("textbox", [.06 .5 .3 .3], 'String', 'Side-on', 'FitBoxToText', 'on', 'FontSize', 16, 'LineStyle', 'none');
        end

        %% Saving

        %Defines folderpath to save the figures to
        if(plotRotation)
            folderPath = strcat('../posFiguresV3/', participantID,'/Rotation');
        else
            folderPath = strcat('../posFiguresV3/', participantID,'/Position');
        end
        
        if ~exist(folderPath, 'dir')
            mkdir(folderPath);
        end

        % Saves the figure as a .png and .fig
        filePath = strcat(folderPath,"/", sbjFileName, "_", trialType, "_Layout", num2str(layoutNum), "_", direction, "_", typeText);
        saveas(fig, strcat(filePath,'.fig'));
        %exportgraphics(fig,strcat(filePath,'.png'),'Resolution',900); %%For really high resolution pngs
        saveas(fig, strcat(filePath,'.png')); %lower resolution pngs, but fast   

    else
        %errorMsg = msgbox("Sorry, couldn't find the file you're referring to! Please double-check the participantID and filename", '404filenotfound');
        error("Sorry, couldn't find the file you're referring to! Please double-check the participantID and filename");
 

    end
end

