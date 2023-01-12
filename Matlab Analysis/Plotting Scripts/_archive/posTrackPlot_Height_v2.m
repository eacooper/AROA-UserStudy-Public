function posTrackPlot_Height_v2
% Analogous to the first 2 R scripts in Dr. Cooper's folder
%clear all;
close all;

%Set datapath to the PCA folder

datapath = '../PosPCAData_withY/'; %'./Data/PCA/';

%List of Files
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

for s = 1:length(listing); %goes through all folders
   
    %Opens up a figure window
    fig = figure(s);
    hold on;
    %Set the scale ratio to be 1 and make the axis and tick marks invisible
    set(gca,'DataAspectRatio',[1 1 1], 'visible','off');%'XTick',[], 'YTick', [])

    if listing(s).isdir
        
        dirname = listing(s).name;
        
        %Each condition has an ID number
        typeID = 1;
        %Ordered set of typeID for the legend
        typeIDSet = [];

        
        % file list
        files = dir([datapath dirname]);
        
        %Cell Array for Storing Dataset Names
        for p = 1:length(files)-2
            dataSetNames{p} = '';
        end
        

        if isempty(strfind(dirname,'exclude'))
           
            for f = 1:length(files)
            
                if strfind(files(f).name,'csv')
                    
                    %ARXX_date
                    sbjFileName = files(f).name(1:13);
                    %No cue, collocated, combined, etc. from the filename
                    trialType = files(f).name(15:end-32);
        
                    % read in data from csv, convert from table to array
                    C = table2array(readtable([datapath dirname '/' files(f).name]));
        
                    %Get z, y, x, t
                    z = C(:,1);
                    y = C(:,2);
                    x = C(:,3);
                    t = C(:,4);
                    
                    %Find max and min values for the x and y axes
                    %there's probably a less clunky way to do this
                    if(max(z) > maxX)
                        maxX = max(z);
                    end
                    
                    if(max(y) > maxY)
                        maxY = max(y);
                    end
                    
                    if(min(z) < minX)
                        minX = min(z);
                    end
                    
                    if(min(y) < minY)
                        minY = min(y);
                    end
                    
                    %Get the differences between adjacent elements of the vector
                    zDiffs = diff(z);
                    yDiffs = diff(y);
                    xDiffs = diff(x);
                    tDiffs = diff(t);
                    
                    %Distance
                    dists = sqrt(xDiffs.^2 + zDiffs.^2);

                    %The cumuSum and speed calcs were in the R script so I've kept 
                    %them but they don't seem to be useful in trajectory plotting 
                    
                    %Calculate cumulative differences for each vector
                    zCumuSum = cumsum(abs(z));
                    yCumuSum = cumsum(abs(y));
                    xCumuSum = cumsum(abs(x));
                    tCumuSum = cumsum(abs(t));
                    
                    %Speed calculations (m/s)
                    subjSpeed = dists.*sampRate;
                    xSpeed = x.*sampRate;
                    ySpeed = y.*sampRate;
                    zSpeed = z.*sampRate;

                    %Finding out which trial type it is
                    if strcmp(trialType, 'No Cues')
                        typeID = 1;
                    elseif strcmp(trialType, 'Collocated')
                        typeID = 2;
                    elseif strcmp(trialType, 'Combined')
                        typeID = 3;
                    elseif strcmp(trialType, 'HUD')
                        typeID = 4;
                    else
                        warning(strcat("Unknown Trial Type!!: ", trialType));
                        typeID = 5;
                    end

                    dataSetNames{f-2} = trialType;

                    %Plotting
                    plot(z, y, 'LineWidth',1.25, 'Color', colours(typeID, :));
        
                    xlim([minX-0 maxX+0]);
                   % ylim([-0.8 1.25]);


                    %typeID = typeID + 1;
                else
                    errorMsg = msgbox("Sorry, couldn't find the file you're referring to! Please double-check that you've run export_PCA_alt_withY.m and have set up the folders correctly (check the ReadMe)", '404filenotfound');
                end
            end
        end
    end


    %Sets the size of the graph in pixels
    set(gcf,'position',[0,0,6400, 300]);%maxX*400,maxY*400]);
    %Tight border around the graph
    set(gca,'LooseInset',get(gca,'TightInset'));

    %Checking for Repeat Names
    for p = 1:length(dataSetNames)-1
        if strcmp(dataSetNames(p), dataSetNames(p+1))
            dataSetNames(p) = strcat(dataSetNames(p), ' 1');
            dataSetNames(p+1) = strcat(dataSetNames(p+1), ' 2');
        end
    end

    %Surronding Bars for Indicating where the Hallway is
    borderX = 0:0.1:15; %ceil(maxX);
    borderY1 = -0.9*ones(length(borderX), 1);
    borderY2 = 0.9*ones(length(borderX), 1); 
    plot(borderX, borderY1, 'k', 'Linewidth', 5, 'Color', '#737373');
    plot(borderX, borderY2, 'k', 'Linewidth', 5, 'Color', '#737373');
    
    %Plotting the 1m scale marking
    %refX = ceil(maxX)-2:0.1:ceil(maxX)-1;
    refX = 15:-0.1:14;
    refY = (borderY2(1)+0.15)*ones(length(refX), 1);
    plot(refX, refY, 'k', 'Linewidth', 2);
    
    %Plotting the 1m scale text
    txt = {'1m'};
    %t1 = text(ceil(maxX)-1.3,refY(1)+0.15,txt);
    t1 = text(14.5, refY(1) + 0.15, txt);
    t1.FontName = 'Gill Sans MT';
    t1.FontSize = 14;

    %Plotting Y yardstick
    %refVertY = ceil(maxY) - 2:0.1:ceil(maxY) - 1;
    %refVertY = ceil(maxY):-0.1:(ceil(maxY) - 0.5);
    refVertY = -0.25:.1:.25; %is there a need to base this off of ceil(maxY)?
    refVertX = 15*ones(length(refVertY), 1);
    plot(refVertX, refVertY, 'k', 'Linewidth', 2);

    %Plotting 1m scale text for Y
    txt2 = {'0.5m'};
    t2 = text(15.1, 0.25, txt2);
    t2.FontName = 'Gill Sans MT';
    t2.FontSize = 14;
   
    
    %Plotting the START text
    txt = {'START'};
    t1 = text(0.25,borderY2(1)+0.25,txt);
    t1.FontName = 'Gill Sans MT';
    t1.FontSize = 16;

    %Plotting name text
    sbjFileName(5) = ' ';
    t2 = text(0.25, -borderY2(1)-0.2,sbjFileName + " Height Graph");
    t2.FontName = 'Gill Sans MT';
    t2.FontSize = 12;

    %Legend
    lgd = legend(string(dataSetNames), 'Location', [0.85 0.1 0.02 0.1]);
    lgd.FontSize = 12;

    %Defines folderpath to save the figures to
    folderPath = '../PosFigures_Height_v2/';
    if ~exist(folderPath, 'dir')
        mkdir(folderPath)
    end

    
    %Saves the figure as a .png 
    filePath = strcat('../PosFigures_Height_v2/', sbjFileName);
    saveas(fig, strcat(filePath,'.fig'));
    saveas(fig, strcat(filePath,'.png'));
end

end
