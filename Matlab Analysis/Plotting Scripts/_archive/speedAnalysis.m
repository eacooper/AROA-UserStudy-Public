% Calculate when each participant is slowed to below a certain speed.
% Creates a plot showing slowdown by participant by trial.

function speedAnalysis ()

    close all;
    
    %Set datapath to the PCA folder
    datapath = '../PosPCADataV2/'; 
    
    listing = dir(datapath);
    listing = listing(3:end); %Seems to skip past two files that are only labeled as "." and ".."
    
    for s = 1:length(listing)
        if listing(s).isdir && listing(s).name ~= "OA21_22-06-15"
            dirname = listing(s).name;
            files = dir([datapath dirname]);
    
            if ~contains(dirname,'exclude')
    
                 for f = 1:length(files)
                
                    if strfind(files(f).name,'csv')
                            sbjFileName = files(f).name(1:13);
                            participantID = files(f).name(1:4);

    
    
                    end
                 end
            end
        end
    end
end