% Sum intervals of a certain type across all participants.

function sumIntervals (intervalType, outlierThreshold, numBins) 

% intervalType = variable name (e.g. "x", "t", "distance")
% outlierThreshold = value to use as a cutoff. Anything over this value will
% be added to a separate OutlierText document
% numBins = number of bins to use in the histogram representing intervals.

close all;

%Set datapath to the PCA folder

datapath = '../PosPCADataV3/'; 

listing = dir(datapath);
listing = listing(3:end); %Seems to skip past two files that are only labeled as "." and ".."

%disp("Length of listing: " + length(listing));


totalDiffCount = 0;
totalDiffs = [];
outlierText = "Outlier threshold of " + outlierThreshold;
outlierCount = 0;

for s = 1:length(listing)
    if listing(s).isdir && listing(s).name ~= "OA21_22-06-15"  % Exclude testing data.

        dirname = listing(s).name;
        %disp("Directory name: " + dirname);


        % File list
        files = dir([datapath dirname]);
        %disp(length(files) + " files found.");

        if ~contains(dirname,'exclude')

             for f = 1:length(files)
            
                 %For each file, run CalcIntervals. 
                if strfind(files(f).name,'csv')
                    %disp("Preparing figure for " + files(f).name);
                    totalDiffCount = totalDiffCount + 1;
                    fileDiffs = calcIntervals(files(f).name, intervalType, 0);
                    %disp("For file " + files(f).name + ", found " + length(fileDiffs) + " intervals.");

                    for  n = 1:length(fileDiffs)
                        % Check for unusually long intervals and add them
                        % to the Outlier Text file.
                        if (abs(fileDiffs(n)) > outlierThreshold)
                            outlierMention = "Interval of " + fileDiffs(n) + " found at index " + n + " in file " + files(f).name;
                            outlierText = outlierText + newline + outlierMention;
                            outlierCount = outlierCount + 1;
                            disp(outlierMention);
                        else
                            % Add non-outliers to one large totalDiffs
                            % structure.
                            totalDiffs = [totalDiffs, fileDiffs(n)];
                        end
                    end
                    
                end
             end
        end
    end
end
disp("A grand total of " + totalDiffCount + " file intervals counted.");
disp("Average value: " + mean(totalDiffs));

% Calculate the average value of the non-outlier intervals.
outlierText = outlierText + newline + "Average value: " + mean(totalDiffs);

% Draw a histogram.
fig = histogram(totalDiffs, NumBins = numBins);
legend(intervalType);
annotation("textbox", [0.7 0.7 0.1 0.1], "String", outlierCount + " outliers" + newline + "(Threshold: " + outlierThreshold + ")", "FitBoxToText","on");

%% Saving

%Defines folderpath to save the figures to
folderPath = strcat('../Interval Summaries/');

if ~exist(folderPath, 'dir')
    mkdir(folderPath);
end

%Saves the figure as a .png and .fig
filePath = strcat(folderPath,"/", intervalType);
saveas(fig, strcat(filePath,'.fig'));
%exportgraphics(fig,strcat(filePath,'.png'),'Resolution',900); %%For really high resolution pngs
saveas(fig, strcat(filePath,'.png')); %lower resolution pngs, but fast   
writelines(outlierText, strcat(filePath, '.txt'));

end