%Plots basic rotation data for a given file

function plotRawRotation (fileName)

% fileName = posPCA CSV file to use. e.g. char("OA10_22-04-11_Collocated_Layout 6_Forward_posTracking.csv")


    close all;

    %Establish data path
    datapath = '../PosPCADataV3/';
    sbjFileName = fileName(1:13);
    participantID = fileName(1:4);

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
        ax1 = axes;
        grid on;
        hold on;
        %Set the scale ratio to be 1
        %set(gca,'DataAspectRatio',[1 1 1], 'color', 'none');%'XTick',[], 'YTick', [])
        %Sets the size of the graph in pixels
        %set(gcf,'Position',[0, 0, 1800, 450]);%maxX*400,maxY*400]);
        %Resizes the axes within the figure (as a proportion of the total figure size
        %set(gca,'OuterPosition',[0.02, 0, 0.97, 0.97])

        % read in data from csv
        pData = readtable([datapath sbjFileName '/' fileName]);

            
        % Get trial type and layout from table
        trialType = string(pData.TrialType(1));
        layoutNum = pData.LayoutNumber(1);

        % Get core data
%         x = pData.X;
%         y = pData.Y + subjHeightMeters;
%         z = pData.Z;
        t = pData.Time;
        %upHUD = pData.UpHUD;
        %rightHUD = pData.RightHUD;
        %downHUD = pData.DownHUD;
        %leftHUD = pData.LeftHUD;
        rotationX = pData.RotationX;
        rotationY = pData.RotationY;
        rotationZ = pData.RotationZ;

%         direction = pData.Direction(1);

%         if (direction == "Backward")
%             x = -x;
%             z = max(z) - z;
%         end

%         rotXDiffs = atan2(sin((diff(rotationX))*pi/180),cos((diff(rotationX))*pi/180))*180/pi;
%         rotYDiffs = atan2(sin((diff(rotationY))*pi/180),cos((diff(rotationY))*pi/180))*180/pi;
%         rotZDiffs = atan2(sin((diff(rotationZ))*pi/180),cos((diff(rotationZ))*pi/180))*180/pi;
        %disp("Length of t: " + length(t));
        %disp("Length of rotationX: " + length(rotationX));
        %disp("Length of rotxDiffs: " + length(rotXDiffs));

%         rotXDiffs(end + 1) = 0;
%         rotYDiffs(end + 1) = 0;
%         rotZDiffs(end + 1) = 0;

        % Stop flipping between 0 and 360
        for n = 1:length(rotationZ)
            if rotationX(n) > 100
                rotationX(n) = rotationX(n) - 360;
            elseif rotationX(n) < -100
                rotationX(n) = rotationX(n) + 360;
            end

            if rotationY(n) > 100
                rotationY(n) = rotationY(n) - 360;
            elseif rotationY(n) < -100
                rotationY(n) = rotationY(n) + 360;
            end

            if rotationZ(n) > 100
                rotationZ(n) = rotationZ(n) - 360;
            elseif rotationZ(n) < -100
                rotationZ(n) = rotationZ(n) + 360;
            end            
        end

        %% Plotting

        %Plot rotation
        plot(t, rotationX, "Color", colour1);
        plot(t, rotationY, "Color", colour2);
        plot(t, rotationZ, "Color", colour3);
        
        %Plot rotation differences
        %plot(t, rotXDiffs, "Color", colour1);
        %plot(t, rotYDiffs, "Color", colour2);
        %plot(t, rotZDiffs, "Color", colour3);

        %Plot title
        sbjFileName(5) = ' ';
        nameText = strcat(sbjFileName, ", ", trialType, ", Layout ", num2str(layoutNum), ", " ,pData.Direction(1), ", Basic Rotation");
        %t2 = text(0,0, nameText); 
        %annotation('textbox', [0 0.5 0.3 0.3], 'String', nameText, 'FitBoxToText', 'on');
        %t2.FontName = 'Gill Sans MT';
        %t2.FontSize = 12;
        title(nameText);

        %Plot legend
        legend('rotationX','rotationY','rotationZ', "location", "southeast");

        %% Saving

        %Defines folderpath to save the figures to
        folderPath = strcat('../posFigures/', participantID,'/Raw Rotation');
        
        if ~exist(folderPath, 'dir')
            mkdir(folderPath);
        end

        %Saves the figure as a .png 
        filePath = strcat(folderPath,"/", sbjFileName, "_", trialType, "_Layout", num2str(layoutNum), "_", pData.Direction(1), "_Raw Rotation");
        saveas(fig, strcat(filePath,'.fig'));
        %exportgraphics(fig,strcat(filePath,'.png'),'Resolution',900); %%For really high resolution pngs
        saveas(fig, strcat(filePath,'.png')); %lower resolution pngs, but fast   

        disp("Raw Rotation graph saved to " + filePath);

    else 
        disp("File not found.")
    end
end