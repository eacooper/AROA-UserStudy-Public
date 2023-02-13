% This script removes repeated position measurements and performs a
% PCA (Principal Components Analysis)-based alignment of trajectory data, 
% then saves it all out to a CSV.

clear all;
close all;

% Sets directory path to the raw data folder.
% Should have folders for each participant, each containing a text file per
% trial. (One forward, one backward.)
datapath = '../Raw Data/';


% Subject directory list
listing = dir([datapath '*OA*' ]);
disp("Listing: ");
disp(listing);

%Counter for debugging purposes
for s = 1:length(listing) % Goes through all folders
    
    if listing(s).isdir
        
        dirname = listing(s).name;
        disp("Directory name:");
        disp(dirname);

        % File list
        files = dir([datapath dirname '/*.txt']);
        
        % For each file for this subject
        for f = 1:length(files)
            
            % Get file name
            d = files(f).name;
            disp("Now converting file:");
            disp(d);
           
            % Read in data from txt
            fileID = fopen([ datapath dirname '/' files(f).name]);
          
            C = textscan(fileID,['%s' '%s' '%s' '%s' repmat('%f',[1 7]) '%s' '%s' repmat('%f',[1 6]) repmat('%s',[1 4])],'Delimiter',';','HeaderLines',1);

            % Store position and time information
            x = C{6};
            y = C{7};
            z = C{8};
            t = C{5};

            
            disp("Number of entries in raw time log:");
            disp(length(t));
            
            % Heads-Up Information
            upHUD       = str2double(strrep(strrep(C{20}, 'False', '0'), 'True', '1'));
            rightHUD    = str2double(strrep(strrep(C{21}, 'False', '0'), 'True', '1'));
            downHUD     = str2double(strrep(strrep(C{22}, 'False', '0'), 'True', '1'));
            leftHUD     = str2double(strrep(strrep(C{23}, 'False', '0'), 'True', '1'));
            
            %Gaze Information -
            % 14-16 is Gaze Direction,
            % 17-19 is Eye Movement
            % 9-11 is Head Rotation Angles
            rotationX = C{9};
            rotationY = C{10};
            rotationZ = C{11};
            
            %Trial Information
            trialType = C{2};
            trialDirection = C{4};
            
            %Layout number as double
            layoutNum = cell2mat(C{3});
            layoutNum = str2num(layoutNum(:,8));
            
            fclose(fileID);
            

            %Assume last line is "Logging ended at ____" and remove it            
            x = x(1:end-1);
            y = y(1:end-1);
            z = z(1:end-1);
            t = t(1:end-1);
            

            % Find axis of maximal variance
            [coeff,~,~,~,explained,~] = pca([x , z]);
            coeff = coeff(:,1);
            
            % align z with this axis
            theta = atan2( coeff(1), coeff(2) );
            A = [ cos( theta ) sin( theta );
                -sin( theta ) cos( theta );];
            newax = [x , z] * A;
            x = newax(:,1);
            z = newax(:,2);
            
            % Make initial t, x, y, and z zero, with increasing values
            z = z - z(1);
            x = x - x(1);
            y = y - y(1);
            t = t - t(1);

            % Set initial rotation to 0,0,0
            rotationX = rotationX - rotationX(1);
            rotationY = rotationY - rotationY(1);
            rotationZ = rotationZ - rotationZ(1);
            
            % If z is pointing in the wrong direction rotate 180 deg
            if sign(z(end)) == -1
                z = -z;
                x = -x;
            end

            %Remove duplicates
            duplicateIndices = [];
            for n = 1:1:length(x)
                if n ~= 1
                    if (x(n) == x(n-1))
                        duplicateIndices = [duplicateIndices, n];
                    end
                end
            end
            disp("Duplicates found: " + length(duplicateIndices))
            
            for n = length(duplicateIndices):-1:1
                target = duplicateIndices(n);
                x(target) = [];
                y(target) = [];
                z(target) = [];
                t(target) = [];
                upHUD(target) = [];
                downHUD(target) = [];
                leftHUD(target) = [];
                rightHUD(target) = [];                
                rotationX(target) = [];                
                rotationY(target) = [];                
                rotationZ(target) = [];      
            end

            % Delete all data after z = 15 meters
            exceedCounter = 0;
            formerMaxZ = max(z);
            for n = length(z):-1:1
                %disp(n + "/" + length(z) + " " + z(n));
                if (z(n) > 15)
                    x(n) = [];
                    y(n) = [];
                    z(n) = [];
                    t(n) = [];
                    upHUD(n) = [];
                    downHUD(n) = [];
                    leftHUD(n) = [];
                    rightHUD(n) = [];                
                    rotationX(n) = [];                
                    rotationY(n) = [];                
                    rotationZ(n) = [];      
                    exceedCounter = exceedCounter + 1;
                end
            end
            disp(exceedCounter + " entries removed. Max Z changed from " + formerMaxZ + " to " + max(z));
            
            % If this is OA07 No Cues Backward or OA11 No Cues Backward,
            % there was a glitch in the tracking, so use zeros instead.
            badFile1 = '2022-03-30_04-47-36-PM_No Cues_Layout 1_Backward.txt';
            badFile2 = '2022-04-20_12-42-41-PM_No Cues_Layout 5_Backward.txt';
            if strcmp(files(f).name,badFile1) || strcmp(files(f).name, badFile2)
                disp("Bad file encountered, using zeros.");
               for n = 1:length(x)
                    x(n) = 0;
                    y(n) = 0;
                    z(n) = 0;
                    t(n) = 0;
                    upHUD(n) = 0;
                    downHUD(n) = 0;
                    leftHUD(n) = 0;
                    rightHUD(n) = 0;                
                    rotationX(n) = 0;                
                    rotationY(n) = 0;                
                    rotationZ(n) = 0;   
               end
            end

            % Position-tracking datafiles are made
            newDirname = strcat(dirname(10:13),"_", dirname(1:9));
            sbjFileName = strcat(newDirname, files(f).name(23:end-4));

            folderPath = strcat('../Processed Data/',newDirname, '/');

            
            if ~exist(folderPath, 'dir')
                mkdir(folderPath)
            end
            
            csvname = strcat(folderPath, sbjFileName, '.csv');
   
            % The num2cell() is needed because the previous format
            % won't support writing both numbers and strings to the
            % csv file at the same time
            disp("Writing table: ");
            disp(csvname);
            
            posPCATable = cell2table([num2cell(x), num2cell(y), num2cell(z), num2cell(t), ...
                num2cell(upHUD(1:length(x))), num2cell(rightHUD(1:length(x))), ...
                num2cell(downHUD(1:length(x))), num2cell(leftHUD(1:length(x))), ...
                trialType(1:length(x)), num2cell(layoutNum(1:length(x))), ...
                num2cell(rotationX(1:length(x))), ...
                num2cell(rotationY(1:length(x))), num2cell(rotationZ(1:length(x))), ...
                trialDirection(1:length(x))], ...
                "VariableNames", ["X" "Y" "Z" "Time" "Up HUD" "Right HUD" "Down HUD" "Left HUD" ...
                "Trial Type" "Layout Number" "Rotation X" "Rotation Y" "Rotation Z" ...
                "Direction"]);
            writetable(posPCATable,csvname,'WriteVariableNames',1);
            disp(" ");
             
        end
        
    end
    
end