%This is different from original version in that it selects one csv file by
%name to make a graph of it

function gazeTrackPlot_singlePath_Condition_byName_Vertical(fileName, plotThicknessBool)

    close all;
    %If this bool is true, then it plots the path with line thickness
    %varying with speed. If false, then it's a constant line

    %Side-to-side: Rotation around y axis, positive = right, negative = left
    %Up-and-down: Rotation around x axis, positive = down, negative = up

%||||||||||||||||||||||||||CHANGE AFTER DEBUGGING||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    fileName = 'OA04_22-03-09_Combined_Layout 8_Forward_posTracking_.csv';
    plotThicknessBool = false;
%||||||||||||||||||||||||||CHANGE AFTER DEBUGGING||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

    %Datapath
    datapath = '../PosPCAData/';
    sbjFileName = fileName(1:13);
    subjHeightMeters = 1.75;
    %No cue, collocated, combined, etc. from the filename
    %trialType;
    %Layout Number
    %layoutNum;
    %Backward/Forward
    %directionality;
    %direcBool = 1; %1 = backward, 0 = forward

    sampRate = 50; %Sampling Rate
    
    %For storing the min/max X and Y values from the position data
    maxX = 0;
    minX = 0;
    maxY = 0;
    minY = 0;
    
    %Colours
    colour1 = [82, 161, 181]./256; %teal
    colour2 = [255, 180, 26]./256; %orange
    colour3 = [230, 26, 113]./256; %rose
    colour4 = [205, 135, 255]./256; %lavender
    colour5 = [175, 255, 117]./256; %honeydew
    
    colours = [colour1; colour2; colour3; colour4; colour5];

    %Opens the file
    if isfile([datapath sbjFileName '/' fileName])
        %Opens up a figure window
        fig = figure(1);
        ax1 = axes;
        grid on;
        hold on;
        %Set the scale ratio to be 1
        set(gca,'DataAspectRatio',[1 1 1], 'color', 'none');%'XTick',[], 'YTick', [])
        %Sets the size of the graph in pixels
        set(gcf,'Position',[0, 0, 6400, 450]);%maxX*400,maxY*400]);
        %Resizes the axes within the figure (as a proportion of the total figure size
        set(gca,'OuterPosition',[0.02, 0, 0.97, 0.97])

        % read in data from csv, convert from table to array
        C = readtable([datapath sbjFileName '/' fileName]);
        trialType = string(table2array(C(1, 8)));
        directionality = string(table2array(C(1,14)));
        if strcmp(directionality, "Forward")
            direcBool = 0;
        elseif strcmp(directionality, "Backward")
            direcBool = 1;
        end
        C = table2array(C(:,[1:7 , 9:13, 15]));
        layoutNum = C(1,8);
       
        %Get z, x, t, y
        z = C(:,1);
        x = C(:,2);
        t = C(:,3);
        y = C(:, 13)+subjHeightMeters;

        %Combs through to check for exact same x

        %Get gaze x, y, z
        gazePosX = C(:, 10);
        gazePosY = C(:, 11);
        gazePosZ = C(:, 12);


        %If the direction is backward, flip the array
        if direcBool == 1
            %yee =  "etner"
            x =  - x;
            z = max(z) - z;
        end

        %Get HUD cue binaries 
        %0 = false, 1 = true
        upHUD = C(:, 4);
        rightHUD = C(:, 5);
        downHUD = C(:, 6);
        leftHUD = C(:, 7);
    
        %Get the differences between adjacent elements of the vector
        zDiffs = diff(z);
        length(zDiffs)
        xDiffs = diff(x);
        %tDiffs = diff(t);
        
        %Distance
        dists = sqrt(xDiffs.^2 + zDiffs.^2);

        %Total distance of the path
        totalDist = sum(dists);
        
        %Calculate cumulative differences for each vector
        zCumuSum = cumsum(abs(z));
        xCumuSum = cumsum(abs(x));
        tCumuSum = cumsum(abs(t));
        
        %Speed calculations (m/s) for each between-frame segment
        distSpeeds = dists.*sampRate;
        xSpeeds = x.*sampRate;
        zSpeeds = z.*sampRate;
        
        %Find max and min values for the x and y axes
        %there's probably a less clunky way to do this
        if(max(z) > maxX)
            maxX = max(z);
        end
        
        if(max(x) > maxY)
            maxY = max(x);
        end
        
        if(min(z) < minX)
            minX = min(z);
        end
        
        if(min(x) < minY)
            minY = min(x);
        end


        %Finding out which trial type it is
        if strcmp(trialType, 'No Cues')
            typeID = 1;
            hasRepeatName(1) = 1;
        elseif strcmp(trialType, 'Collocated')
            typeID = 2;
            hasRepeatName(2) = 1;
        elseif strcmp(trialType, 'Combined')
            typeID = 3;
            hasRepeatName(3) = 1;
        elseif strcmp(trialType, 'HUD')
            typeID = 4;
            hasRepeatName(4) = 1;
        else
            warning(strcat("Unknown Trial Type!!: ", trialType));
            typeID = 5;
        end

        dataSetName = trialType;

        %Plotting
        %%NOTE - X IS FLIPPED BECAUSE THE SIDE-TO-SIDE
        %%TRANSLATIONS ACROSS THE WIDTH OF THE HALLWAY IS FLIPPED
        if (plotThicknessBool)
            fig = plotVariedLineThickness(z, x, t, dists, sampRate, fig, colours(typeID, :));
        else
            plot(z, y, 'LineWidth', 1.25, 'Color', [0.5 0.5 0.5]);%colours(typeID, :));
        end

        %fig = plotSpeedScaledCircles(z, x, t, dists, sampRate, fig, colours(typeID, :), 0, 0.1);

        %Draws arrows per 75 frames
        if direcBool ==1
            quiver(z(1), y(1), z(2)-z(1), y(2)-y(1), 0 , 'Marker', '<', 'Color', colours(typeID, :), 'LineWidth', 1.5);
            quiver(z(end-1), y(end-1), z(end)-z(end-1), y(end)-y(end-1), 0 , 'Marker', '<', 'Color', colours(typeID, :), 'LineWidth', 1.5);
%             for n = 1:75:length(x)-1
%                 quiver( z(n), -x(n), z(n+1)-z(n), -x(n+1)+x(n), 0 , 'Marker', '<', 'Color', colours(typeID, :), 'LineWidth', 1.5);
%             end
        else
            quiver(z(1), y(1), z(2)-z(1), y(2)-y(1), 0 , 'Marker', '>', 'Color', colours(typeID, :), 'LineWidth', 1.5);
            quiver(z(end-1), y(end-1), z(end)-z(end-1), y(end)-y(end-1), 0 , 'Marker', '>', 'Color', colours(typeID, :), 'LineWidth', 1.5);

%             for n = 1:75:length(x)-1
%                 quiver( z(n), -x(n), z(n+1)-z(n), -x(n+1)+x(n), 0 , 'Marker', '>', 'Color', colours(typeID, :), 'LineWidth', 1.5);
%             end
        end


        %This is for gaze vectors
        gazeVectorLengths = gazePosX.^2+gazePosZ.^2;
        maxVecLength = max(gazeVectorLengths)
        %For every x number of frames
%         n = 0;
%         for n= 1:20:length(gazePosX)
%             if gazeVectorLengths(n) == maxVecLength
%                 gazeVectorLengths(n) = 0.001;
%             end
%             quiver(z(n), -x(n), gazePosZ(n), -gazePosX(n), 2.5+gazeVectorLengths(n)/maxVecLength, 'r');%(z(n)+gazePosZ(n)), -(x(n)+gazePosX(n)) );%, sqrt(gazePosX(n)^2+gazePosZ(n)^2));
%         end

        
%For every x number of frames

        arrowLength = 0.5;
        n = 0;
        for n= 1:20:length(gazePosX)
            %quiver(z(n), -x(n), z(n) + arrowLength*cos(gazePosZ(n)), -(x(n) + arrowLength*sin(gazePosX(n))), 'r');
            quiver(z(n), y(n), arrowLength*cos(gazePosZ(n)), -(arrowLength*sin(gazePosX(n))), 'r');
        end

        xlim([minX-0 maxX+0]);
        ylim([0 2.5]);
        ax = gca;
        ax.Clipping = 'off';
        ax.FontName = 'Gill Sans MT';
        ax.FontSize = 10;
        
        %X- and Y-Tick Marks
        set(gca,'XTick', [0:1.5:15], 'YTick', [0:0.5:2.5]);

        %YTick Labels
        %yticklabels(sprintfc('%.2f', [0.85:0.3:2.65])); %Centred around participant's height
        

        %Flip Y-axis direction
        %ax.YDir = 'reverse';

        %Flips Y-Tick labels so that right = positive and left = negative
%         yt = get(gca, 'YTick');
%         set(gca, 'YTickLabel',flip(yt));
        
        %Tight border around the graph
        set(gca,'LooseInset',get(gca,'TightInset'));


        %Maps on Obstacles
        fig = overlayObstacles(fig, layoutNum, 2, subjHeightMeters);
    
        %Surrounding Bars for Indicating where the Hallway is
        borderX = 0:0.1:15; %ceil(maxX);
        borderY1 = -0*ones(length(borderX), 1);
        borderY2 = 2.5*ones(length(borderX), 1); 
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
        t1.FontSize = 14;
        
        %Plotting the START text
        txt = {'START'};
        t1 = text(-0.5, 1, txt);%text(0.25,borderY2(1)+0.25,txt);
        t1.FontName = 'Gill Sans MT';
        t1.FontSize = 12;
        t1.Rotation = 90;
    
        %Plotting name text
        sbjFileName(5) = ' ';
        nameText = strcat(sbjFileName, ' - Layout '," ", num2str(layoutNum), ", " ,directionality);
        t2 = text(0.25, -borderY1(1)-0.5, nameText); %text(0.25, -borderY2(1)+2, nameText);
        t2.FontName = 'Gill Sans MT';
        t2.FontSize = 12;

        %Plotting total distance text (rounded to 2 dps)
        nameText = strcat('Total Distance:  ', num2str(round(totalDist*100)/100), 'm');
        t3 = text(13.75, -borderY1(1)+0.45, nameText); %text(0.25, -borderY2(1)+2, nameText);
        t3.FontName = 'Gill Sans MT';
        t3.FontSize = 8;

        %Plotting total time elapsed (rounded to 2 dps)
        nameText = strcat('Total Time:', " ", num2str(round(t(end)*100)/100), 's');
        t3 = text(13.95, -borderY1(1)+0.30, nameText); %text(0.25, -borderY2(1)+2, nameText);
        t3.FontName = 'Gill Sans MT';
        t3.FontSize = 8;

        %Plotting average velocity elapsed (rounded to 2 dps)
        nameText = strcat('Average Velocity:', " ", num2str(round(totalDist/t(end)*100)/100), 'm/s');
        t3 = text(13.57, -borderY1(1)+0.15, nameText); %text(0.25, -borderY2(1)+2, nameText);
        t3.FontName = 'Gill Sans MT';
        t3.FontSize = 8;
    
        %Maps on HUD Cues on HUD condition trials
        %It has to be here for the vertical because the overlayHUDCues
        %function copies the axes from the original graph
        if(strcmp(trialType, 'HUD')||strcmp(trialType, 'Combined'))
            fig = overlayHUDCues(fig, z, -y, upHUD, downHUD, rightHUD, leftHUD, ax1, 2);
        end

        %Legend
        lgd = legend(string(dataSetName), 'Location', [0.85 0.001 0.02 0.1]);
        lgd.FontSize = 12;

        %Defines folderpath to save the figures to
        folderPath = '../PosFigures/singlePath_Condition/';
        if ~exist(folderPath, 'dir')
            mkdir(folderPath)
        end
 
        %Saves the figure as a .png 
        filePath = strcat('../PosFigures/singlePath_Condition/', sbjFileName, "_", trialType, "_Layout", num2str(layoutNum), directionality);
        saveas(fig, strcat(filePath,'.fig'));
        exportgraphics(fig,strcat(filePath,'.png'),'Resolution',900); %%For really high resolution pngs
        %saveas(fig, strcat(filePath,'.png')); %lower resolution pngs, but fast
    else
        errorMsg = msgbox("Sorry, couldn't find the file you're referring to! Please double-check the participantID and filename", '404filenotfound');
        error("Sorry, couldn't find the file you're referring to! Please double-check the participantID and filename");
    end
end