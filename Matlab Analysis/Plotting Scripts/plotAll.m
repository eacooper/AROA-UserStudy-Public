% Plot all participant data using the PlotByName function.

function plotAll (plotPos, plotRot, plotRotRaw)

% Inputs are bools indicating whether it should plot position,
% rotation, and raw rotation

close all;


%Set datapath to the PCA folder

datapath = '../PosPCADataV3/'; 

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

                    if (plotPos)
                        plotByName(files(f).name, 1, 0);                    
                        plotByName(files(f).name, 0, 0);

                        totalGraphCount = totalGraphCount + 2;
                        directoryCount = directoryCount + 2;
                        
                    end
                    
                    if (plotRot)
                        plotByName(files(f).name, 1, 1);
                        plotByName(files(f).name, 0, 1);

                        totalGraphCount = totalGraphCount + 2;
                        directoryCount = directoryCount + 2;                        
                    end

                    if (plotRotRaw)
                        plotRawRotation(files(f).name);

                        totalGraphCount = totalGraphCount + 1;
                        directoryCount = directoryCount + 1;                        
                    end
                    
                end
             end
        end
        disp(directoryCount + " graphs made.");
    end
end
disp("A grand total of " + totalGraphCount + " graphs made.");