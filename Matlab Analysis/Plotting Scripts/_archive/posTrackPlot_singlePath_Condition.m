function posTrackPlot_singlePath_Condition(plotThicknessBool, plotTopDown)
%{NOTES: Currently having the script run through everything - may be 
% advantageous to have an option to choose by subj and/or condition. 
% Also, should rename all "trialType" to "trialCondition" 
%}
plotThicknessBool;
plotTopDown; % 1 for top-down, 0 for side-on

close all;

%Set datapath to the PCA folder

datapath = '../PosPCAData/'; %'./Data/PCA/';

%List of Files
% files = dir(datapath); %Finding the PCA csv files in the directory
% files = files(3:end);

listing = dir(datapath);
listing = listing(3:end); 

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

counter = 1;

for s = 1:length(listing); %goes through all folders

    if listing(s).isdir
        
        dirname = listing(s).name;
        disp(dirname);

        typeID = 1;

        % file list
        files = dir([datapath dirname]);

        if isempty(strfind(dirname,'exclude'))
           
            for f = 1:length(files)
            
                if strfind(files(f).name,'csv')
                    disp("Preparing figure for");
                    disp(files(f).name);
 
                    %Opens up a figure window
                    fig = figure(counter);
                    ax1 = axes;
                    grid on;
                    hold on;
                    %Set the scale ratio to be 1
                    set(gca,'DataAspectRatio',[1 1 1], 'color', 'none');%'XTick',[], 'YTick', [])
                    %Sets the size of the graph in pixels
                    set(gcf,'Position',[0, 0, 6400, 300]);%maxX*400,maxY*400]);
                    %Resizes the axes within the figure (as a proportion of the total figure size
                    set(gca,'OuterPosition',[0.03, 0, 0.97, 0.97]);

                    % read in data from csv
                    Table = readtable([datapath dirname '/' files(f).name]);

                    % Name file the same as the input table, e.g. "OA15_22-05-04"
                    sbjFileName = files(f).name(1:13);

                    % Get trial type and layout from table
                    trialType = string(Table{1, 9});
                    disp(trialType);

                    layoutNum = Table{1, 10};
                    disp(layoutNum);

                    % remove non-numerical data
                    Table(:, 9) = []; %Trial Type
                    Table(:, 14) = []; %Note that "Direction" is now in column 14 after shifting
                    % disp(head(Table));

                    % convert to array
                    C = table2array(Table);
                    % disp(C(5,:));
        
                    %Get x, y, z, t

                    x = C(:,1);
                    y = C(:,2);
                    z = C(:,3);
                    t = C(:,4);

                    %Get HUD cue binaries 
                    %0 = false, 1 = true
                    upHUD = C(:, 5);
                    rightHUD = C(:, 6);
                    downHUD = C(:, 7);
                    leftHUD = C(:, 8);
                    
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
                    
                    %Get the differences between adjacent elements of the vector
                    zDiffs = diff(z);
                    xDiffs = diff(x);
                    tDiffs = diff(t);
                    
                    %Distance
                    dists = sqrt(xDiffs.^2 + zDiffs.^2);
                
                    %Total distance of the path
                    totalDist = sum(dists);

                    %The cumuSum and speed calcs were in the R script so I've kept 
                    %them but they don't seem to be useful in trajectory plotting 
                    
                    %Calculate cumulative differences for each vector
                    zCumuSum = cumsum(abs(z));
                    xCumuSum = cumsum(abs(x));
                    tCumuSum = cumsum(abs(t));
                    
                    %Speed calculations (m/s)
                    subjSpeed = dists.*sampRate;
                    xSpeed = x.*sampRate;
                    zSpeed = z.*sampRate;

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
                    %%TRANSLATIONS ACROSS THE WIDTH OF THE HALLWAY IS
                    %%FLIPPED
                   
                    if (plotThicknessBool == true)
                        fig = plotVariedLineThickness(z, x, t, dists, sampRate, fig, colours(typeID, :));
                    else
                        plot(z, -x, 'LineWidth',1.25, 'Color', colours(typeID, :));
                    end
                    
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

                    %Maps on HUD Cues on HUD condition trials
                    if(strcmp(trialType, 'HUD')||strcmp(trialType, 'Combined'))
                        fig = overlayHUDCues(fig, z, x, upHUD, downHUD, rightHUD, leftHUD, ax1, plotTopDown); %1 for horizontal map, 0 for vertical
                    end

                    %Maps on Obstacles
                    fig = overlayObstacles(fig, layoutNum, plotTopDown, 0); % 1.73m is average height of participants
                
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
                    nameText = strcat(sbjFileName, ' - Layout',' ', num2str(layoutNum));
                    t2 = text(0.25, -borderY2(1)-0.5, nameText);
                    t2.FontName = 'Gill Sans MT';
                    t2.FontSize = 12;
                    
                    %Plotting total distance text (rounded to 2 dps)
                    nameText = strcat('Total Distance:  ', num2str(round(totalDist*100)/100), 'm');
                    t3 = text(13.65, -borderY2(1)+0.15, nameText); %text(0.25, -borderY2(1)+2, nameText);
                    t3.FontName = 'Gill Sans MT';
                    t3.FontSize = 8;

                    %Legend
                    lgd = legend(string(dataSetName), 'Location', [0.85 0.1 0.02 0.1]);
                    lgd.FontSize = 12;


                    %Defines folderpath to save the figures to
                    folderPath = '../PosFigures/singlePath_Condition/';
                    if ~exist(folderPath, 'dir')
                        mkdir(folderPath)
                    end
                
                    
                    %Saves the figure as a .png 
                    if (plotTopDown == 1)
                        graphDirection = "_TopDown";
                    elseif (plotTopDown == 0)
                        graphDirection = "_SideOn";
                    end
                       
                    filePath = strcat('../PosFigures/singlePath_Condition/', sbjFileName, "_", trialType, "_Layout", num2str(layoutNum), graphDirection);
                    saveas(fig, strcat(filePath,'.fig'));
                    %exportgraphics(fig,strcat(filePath,'.png'),'Resolution',900); %%For really high resolution pngs
                    saveas(fig, strcat(filePath,'.png'));

                    counter = counter + 1
                else
                    errorMsg = msgbox("Sorry, couldn't find the file you're referring to! Please double-check that you've run export_PCA_alt.m and have set up the folders correctly (check the ReadMe)", '404filenotfound');
                end
            end
        end
    end


end
end
