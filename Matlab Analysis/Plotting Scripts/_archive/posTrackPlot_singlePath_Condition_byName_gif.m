
function posTrackPlot_singlePath_Condition_byName_gif(fileName, plotThicknessBool)

    close all;
    %If this bool is true, then it plots the path with line thickness
    %varying with speed. If false, then it's a constant line

%||||||||||||||||||||||||||CHANGE AFTER DEBUGGING||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    fileName = 'OA04_22-03-09_Combined_Layout 8_Forward_posTracking_.csv';
    plotThicknessBool = false;
%||||||||||||||||||||||||||CHANGE AFTER DEBUGGING||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

    %Datapath
    datapath = '../PosPCAData/';
    sbjFileName = fileName(1:13);
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

        % read in data from csv, convert from table to array
        C = readtable([datapath sbjFileName '/' fileName]);
        trialType = string(table2array(C(1, 8)));
        directionality = string(table2array(C(1,14)));
        if strcmp(directionality, "Forward")
            direcBool = 0;
        elseif strcmp(directionality, "Backward")
            direcBool = 1;
        end
        C = table2array(C(:,[1:7 , 9:13]));
        layoutNum = C(1,8);
       
        %Get z, x, t
        z = C(:,1);
        x = C(:,2);
        t = C(:,3);


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

        distsNonZero = dists;
        for n = 2:length(distsNonZero)
            if distsNonZero(n)== 0
                distsNonZero(n) = distsNonZero(n-1);
            end
        end

        %Speeds
        distsNonZeroSpeeds = distsNonZero.*sampRate;

        minSpeed = min(distsNonZeroSpeeds);
        maxSpeed = max(distsNonZeroSpeeds);
    
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

        %Defines folderpath to save the figures to
        folderPath = '../PosFigures/singlePath_Condition/';
        if ~exist(folderPath, 'dir')
            mkdir(folderPath)
        end
    
        %Saves the figure as a .png 
        filePath = strcat('../PosFigures/singlePath_Condition/', sbjFileName, "_", trialType, "_Layout", num2str(layoutNum), directionality,"HD");
        %saveas(fig, strcat(filePath,'.fig'));
        %exportgraphics(fig,strcat(filePath,'.png'),'Resolution',900); %%For really high resolution pngs
        %saveas(fig, strcat(filePath,'.png')); %lower resolution pngs, but fast

        %Gif Parameters
        gifCounter = 1;
        gifNumFrames = 300;
        endBuffer = 25; %Number of frames the completed graph will hold for at the end
        delayTimeS = 0.02; %Number of seconds of delay between frames
        gifIncrement = floor(length(x)/gifNumFrames); %One gif frame per this many datapoints
        filename = strcat(filePath,'.gif')
        addpath('./export_fig/');
%             gif('tester.gif', 'Resolution', 200);

        fig = figure(1);

        for gifCounter = 1:gifNumFrames+endBuffer
             indices = (1:gifCounter*gifIncrement);
             if gifCounter >= gifNumFrames
                 indices = (1:length(x)-1);
             end
%             if gifCounter == 1
%                 indices = (1:gifCounter*gifIncrement);
%             else
%                 indices = ((gifCounter-1)*gifIncrement:gifCounter*gifIncrement);
%             end
            ax1 = axes;
            grid on;
            hold on;
            %Set the scale ratio to be 1
            set(gca,'DataAspectRatio',[1 1 1], 'color', 'none');%'XTick',[], 'YTick', [])
            %Sets the size of the graph in pixels
            set(gcf,'Position',[0, 0, 6400, 300],'color','w');%maxX*400,maxY*400]);
            %Resizes the axes within the figure (as a proportion of the total figure size
            set(gca,'OuterPosition',[0.02, 0, 0.97, 0.97]);


            xlim([minX-0 maxX+0]);
            ylim([-0.9 0.9]);
            ax = gca;
            ax.Clipping = 'off';
            ax.FontName = 'Gill Sans MT';
            ax.FontSize = 10;
            
            %X- and Y-Tick Marks
            set(gca,'XTick', [0:1.5:15], 'YTick', [-0.9:0.3:0.9]);
    
            %Flip Y-axis direction
            %ax.YDir = 'reverse';
    
            %Flips Y-Tick labels so that right = positive and left = negative
            yt = get(gca, 'YTick');
            set(gca, 'YTickLabel',flip(yt));
            
            %Tight border around the graph
            set(gca,'LooseInset',get(gca,'TightInset'));

            %fig = figure(gifCounter);

              %Plotting: NOTE - X IS FLIPPED BECAUSE THE SIDE-TO-SIDE TRANSLATIONS ACROSS THE WIDTH OF THE HALLWAY IS FLIPPED
            if (plotThicknessBool)
                %fig = plotVariedLineThickness(z(indices), x(indices), t(indices), dists(indices), sampRate, fig, colours(typeID, :));
            else
                plot(z(indices), -x(indices), 'LineWidth', 1.25, 'Color', [0.5 0.5 0.5]);%colours(typeID, :));
            end

            fig = plotSpeedScaledCircles_gif(z(indices), x(indices), t(indices), dists(indices), sampRate, fig, colours(typeID, :), 0, 0.1, maxSpeed, minSpeed);

            %Maps on HUD Cues on HUD condition trials
            if(strcmp(trialType, 'HUD')||strcmp(trialType, 'Combined'))
                fig = overlayHUDCues(fig, z(indices), x(indices), upHUD(indices), downHUD(indices), rightHUD(indices), leftHUD(indices), ax1, 1);
            end
            
            %Maps on Obstacles
            fig = overlayObstacles(fig, layoutNum,1, 0);
    
             %Surrounding Bars for Indicating where the Hallway is
            borderX = 0:0.1:15; %ceil(maxX);
            borderY1 = -0.9*ones(length(borderX), 1);
            borderY2 = 0.9*ones(length(borderX), 1); 
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
            t1 = text(-0.6, -0.3, txt);%text(0.25,borderY2(1)+0.25,txt);
            t1.FontName = 'Gill Sans MT';
            t1.FontSize = 12;
            t1.Rotation = 90;
        
            %Plotting name text
            sbjFileName(5) = ' ';
            nameText = strcat(sbjFileName, ' - Layout '," ", num2str(layoutNum), ", " ,directionality);
            t2 = text(0.25, -borderY2(1)-0.5, nameText); %text(0.25, -borderY2(1)+2, nameText);
            t2.FontName = 'Gill Sans MT';
            t2.FontSize = 12;
    
            %Plotting total distance text (rounded to 2 dps)
            nameText = strcat('Total Distance:  ', num2str(round(totalDist*100)/100), 'm');
            t3 = text(13.75, -borderY2(1)+0.15, nameText); %text(0.25, -borderY2(1)+2, nameText);
            t3.FontName = 'Gill Sans MT';
            t3.FontSize = 8;
    
            %Plotting total time elapsed (rounded to 2 dps)
            nameText = strcat('Total Time:', " ", num2str(round(t(end)*100)/100), 's');
            t3 = text(13.95, -borderY2(1)+0.30, nameText); %text(0.25, -borderY2(1)+2, nameText);
            t3.FontName = 'Gill Sans MT';
            t3.FontSize = 8;
        
            %Legend
            lgd = legend(string(dataSetName), 'Location', [0.85 0.1 0.02 0.1]);
            lgd.FontSize = 12;
            
            refreshdata;
            drawnow; 
            % Capture the plot as an image 
            frame = getframe(fig); 
            im = frame2im(frame); 
            [imind,cm] = rgb2ind(im,256); 

            % Write to the GIF File 
            if gifCounter == 1
                imwrite(imind,cm,filename,'gif', 'Loopcount',inf); 
            else
                imwrite(imind,cm,filename,'gif','WriteMode','append', 'DelayTime', delayTimeS); 
            end

            clf(fig);
            
%            
            %gif;
        end

    else
        errorMsg = msgbox("Sorry, couldn't find the file you're referring to! Please double-check the participantID and filename", '404filenotfound');
        error("Sorry, couldn't find the file you're referring to! Please double-check the participantID and filename");
    end
end