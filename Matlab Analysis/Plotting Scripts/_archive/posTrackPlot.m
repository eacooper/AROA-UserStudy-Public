
% Analogous to the first 2 R scripts in Dr. Cooper's folder
clear all;
close all;

%Set datapath to the PCA folder

datapath = '../PosPCAData/'; %'./Data/PCA/';

%Graph type: put either "multiPath-Subj" or "singlePath-Condition"
graphType = "multiPath-Subj";
%%%%%UNDER CONSTRUCTION TO SEE IF SWITCH CASE OR HAVING SEPARATE SCRIPTS IS BETTER%%%%%

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

switch graphType
    case "multiPath-Subj"
        for s = 1:length(listing); %goes through all folders
   
            %Opens up a figure window
            fig = figure(s);
            hold on;
            %Set the scale ratio to be 1 and make the axis and tick marks invisible
            set(gca,'DataAspectRatio',[1 1 1], 'visible','off');%'XTick',[], 'YTick', [])
        
            if listing(s).isdir
                
                dirname = listing(s).name;
        
                typeID = 1;
                typeIDSet = [];
        
                
                % file list
                files = dir([datapath dirname]);
                
                %Cell Array for Storing Dataset Names
                for p = 1:length(files)-2
                    dataSetNames{p} = '';
                end
                
                hasRepeatName = [0 0 0 0];
        
                if isempty(strfind(dirname,'exclude'))
                   
                    for f = 1:length(files)
                    
                        if strfind(files(f).name,'csv')
                            
                            %ARXX_date
                            sbjFileName = files(f).name(1:13);
                            %No cue, collocated, combined, etc. from the filename
                            trialType = files(f).name(15:end-32);
                
                            % read in data from csv, convert from table to array
                            C = table2array(readtable([datapath dirname '/' files(f).name]));
                
                            %Get z, x, t
                            z = C(:,1);
                            x = C(:,2);
                            t = C(:,3);
                            
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
        
                            dataSetNames{f-2} = trialType;
        
                            %Plotting
                            plot(z, x, 'LineWidth',1.25, 'Color', colours(typeID, :));
                
                            xlim([minX-0 maxX+0]);
                           % ylim([-0.8 1.25]);
        
        
                            %typeID = typeID + 1;
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
            refX = ceil(maxX)-2:0.1:ceil(maxX)-1;
            refY = (borderY2(1)+0.15)*ones(length(refX), 1);
            plot(refX, refY, 'k', 'Linewidth', 2);
            
            %Plotting the 1m scale text
            txt = {'1m'};
            t1 = text(ceil(maxX)-1.3,refY(1)+0.15,txt);
            t1.FontName = 'Gill Sans MT';
            t1.FontSize = 14;
            
            %Plotting the START text
            txt = {'START'};
            t1 = text(0.25,borderY2(1)+0.25,txt);
            t1.FontName = 'Gill Sans MT';
            t1.FontSize = 16;
        
            %Plotting name text
            sbjFileName(5) = ' ';
            t2 = text(0.25, -borderY2(1)-0.2,sbjFileName);
            t2.FontName = 'Gill Sans MT';
            t2.FontSize = 12;
        
            %Legend
            lgd = legend(string(dataSetNames), 'Location', [0.85 0.1 0.02 0.1]);
            lgd.FontSize = 12;
            
        
            %Defines folderpath to save the figures to
            folderPath = '../PosFigures/';
            if ~exist(folderPath, 'dir')
                mkdir(folderPath)
            end
        
            
            %Saves the figure as a .png 
            filePath = strcat('../PosFigures/', sbjFileName);
            saveas(fig, strcat(filePath,'.fig'));
            saveas(fig, strcat(filePath,'.png'));
        end

    case "singlePath-Condition"
    otherwise
end
% for f = 1:length(files);
% 
%     if true % listing(s).isdir
% 
%         if strfind(files(f).name,'csv')
%             
%            %TODO - Need to reformat when the naming convention for files has been set
%             sbjFileName = files(f).name(1:end-4);
% 
%             % read in data from csv, convert from table to array
%             C = table2array(readtable([datapath '/' files(f).name]));
% 
%             %Get z, x, t
%             z = C(:,1);
%             x = C(:,2);
%             t = C(:,3);
%             
%             %Find max and min values for the x and y axes
%             %there's probably a less clunky way to do this
%             if(max(z) > maxX)
%                 maxX = max(z);
%             end
%             
%             if(max(x) > maxY)
%                 maxY = max(x);
%             end
%             
%             if(min(z) < minX)
%                 minX = min(z);
%             end
%             
%             if(min(x) < minY)
%                 minY = min(x);
%             end
%             
%             %Get the differences between adjacent elements of the vector
%             zDiffs = diff(z);
%             xDiffs = diff(x);
%             tDiffs = diff(t);
%             
%             %Distance
%             dists = sqrt(xDiffs.^2 + zDiffs.^2);
%             
%             
%             %The cumuSum and speed calcs were in the R script so I've kept 
%             %them but they don't seem to be useful in trajectory plotting 
%             
%             %Calculate cumulative differences for each vector
%             zCumuSum = cumsum(abs(z));
%             xCumuSum = cumsum(abs(x));
%             tCumuSum = cumsum(abs(t));
%             
%             %Speed calculations (m/s)
%             subjSpeed = dists.*sampRate;
%             xSpeed = x.*sampRate;
%             zSpeed = z.*sampRate;
% 
%             %Plotting
%             plot(z, x, 'LineWidth',1.25, 'Color', colours(f, :));
% 
%             xlim([minX-0 maxX+0]);
%             ylim([-0.8 1.25]);
% 
%             %Sets the size of the graph in pixels
%             set(gcf,'position',[0,0,maxX*400,maxY*400]);
%             %Tight border around the graph
%             set(gca,'LooseInset',get(gca,'TightInset'));
%             
%         end
%     end
% end
