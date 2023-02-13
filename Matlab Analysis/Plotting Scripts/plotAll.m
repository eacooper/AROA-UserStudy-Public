% Plot all participant data using the PlotByName function.

function plotAll ()

% Plots paths for all data

close all;


%Set datapath to the Processed Data folder
datapath = '../Processed Data/'; 

listing = dir(datapath);
listing = listing(3:end); %Seems to skip past two files that are only labeled as "." and ".."

disp("Length of listing: " + length(listing));

totalGraphCount = 0;

% Iterate through all folders in the data path.

for s = 1:length(listing)
    if listing(s).isdir

        dirname = listing(s).name;
        disp("Directory name: " + dirname);
        directoryCount = 0;


        %file list
        files = dir([datapath dirname]);
        %disp(length(files) + " files found.");

        if ~contains(dirname,'exclude')

             for f = 1:length(files)
                 %disp(files(f).name);
            
                if strfind(files(f).name,'csv')
                    %disp("Preparing figure for " + files(f).name);

                    plotByName(files(f).name, 1);                    
                    plotByName(files(f).name, 0);

                    totalGraphCount = totalGraphCount + 2;
                    directoryCount = directoryCount + 2;
                    
                end
             end
        end
        disp(directoryCount + " graphs made for " + dirname);
    end
end
disp("A grand total of " + totalGraphCount + " graphs made.");