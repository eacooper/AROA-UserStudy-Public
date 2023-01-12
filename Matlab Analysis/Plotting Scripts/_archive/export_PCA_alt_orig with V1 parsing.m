clear all;
close all;

%Sets directory path to the raw data folder
datapath = '../PosRawData/';%'./Data/raw data/';

% subject directory list
listing = dir([datapath '*OA*' ]);

task = 'posTracking';

%Counter for debugging purposes
counter = 1;
for s = 4:length(listing) %1:length(listing); %goes through all folders
    
    if listing(s).isdir
        
        dirname = listing(s).name;
        
        % file list
        files = dir([datapath dirname '/*.txt']);
        
        % for each file for this subject
        for f = 1:length(files)
            
            % get file name
            d = files(f).name;
            
            % read in data from txt
            fileID = fopen([ datapath dirname '/' files(f).name]);
            
            %From OA4 and onward, there's 4 %s. OA1-3 have 3 %s
            C = textscan(fileID,['%s' '%s' '%s' '%s' repmat('%f',[1 7]) '%s' '%s' repmat('%f',[1 6]) repmat('%s',[1 4])],'Delimiter',';','HeaderLines',2);
            % store position and time information
            x = C{6};
            y = C{7};
            z = C{8};
            t = C{5};
            
            %HUD Information
            upHUD = str2double(strrep(strrep(C{20}, 'False', '0'), 'True', '1'));
            rightHUD = str2double(strrep(strrep(C{21}, 'False', '0'), 'True', '1'));
            downHUD = str2double(strrep(strrep(C{22}, 'False', '0'), 'True', '1'));
            leftHUD = str2double(strrep(strrep(C{23}, 'False', '0'), 'True', '1'));
            
            %Gaze Information -
            % 14-16 is Gaze Direction,
            % 17-19 is Eye Movement
            % 9-11 is Head Rotation Angles
            gazePosX = C{9};
            gazePosY = C{10};
            gazePosZ = C{11};
            
            
            
            %Trial Information
            trialType = C{2};
            trialDirection = C{4};
            
            %Layout number as double
            layoutNum = cell2mat(C{3});
            layoutNum = str2num(layoutNum(:,8));
            
            directionality = cell2mat(C{4});
            %Checks if it's forwards or backwards
            if(strcmp(directionality(1,1), "f"))
                directionality = 0*ones(length(directionality),1);
            else(strcmp(directionality(1,1), "b"))
                directionality = ones(length(directionality),1);;
            end
            
            fclose(fileID);
            
            
            
            %remove the last value from each array because it's a
            %NaN from the "Logging ended at xyz" line at the end
            x = x(1:end-1);
            y = y(1:end-1);
            z = z(1:end-1);
            t = t(1:end-1);
            
            
            
            % find axis of maximal variance
            [coeff,~,~,~,explained,~] = pca([x , z]);
            coeff = coeff(:,1);
            
            theta = atan2( coeff(1), coeff(2) );
            A = [ cos( theta ) sin( theta );
                -sin( theta ) cos( theta );];
            newax = [x , z] * A;
            x = newax(:,1);
            z = newax(:,2);
            
            % make initial t, x and z zero, with increasing values
            %z = abs(z - z(1)); % down hall always positive
            z = z - z(1);
            x = x - x(1);
            t = t - t(1);
            
            % if z is pointing in the wrong direction rotate 180 deg
            if sign(z(end)) == -1
                z = -z;
                x = -x;
            end
            
            %Also store the HUD bools while converting "False" to 0
            %and "True" to 1 and also converting it all into doubles
            
            
            
            %This is what the lines above are doing
            %                     upHUD = C{18};
            %                     upHUD = strrep(upHUD, 'False', '0');
            %                     upHUD = strrep(upHUD, 'True', '1');
            
            
            
            %position-tracking datafiles are made
            newDirname = strcat(dirname(10:13),"_", dirname(1:9));
            sbjFileName = strcat(newDirname, files(f).name(23:end-4))
            folderPath = strcat('../PosPCAData/',newDirname, '/');
            
            if ~exist(folderPath, 'dir')
                mkdir(folderPath)
            end
            csvname = strcat(folderPath, sbjFileName, '_',num2str(task),'_', '.csv');
            %1:end-1 because that's what's done to z, x, and t to
            %remove the "NaN' at the end
            %csvwrite(csvname, [z,x,t, upHUD(1:end-1), rightHUD(1:end-1), downHUD(1:end-1), leftHUD(1:end-1), layoutNum, directionality]);
            
            %The num2cell() is needed because the previous format
            %won't support writing both numbers and strings to the
            %csv file at the same time
            writetable(cell2table([num2cell(z), num2cell(x),num2cell(t), num2cell(upHUD(1:end-1)), num2cell(rightHUD(1:end-1)), num2cell(downHUD(1:end-1)), num2cell(leftHUD(1:end-1)), trialType(1:end-1), num2cell(layoutNum), num2cell(directionality), num2cell(gazePosX(1:end-1)), num2cell(gazePosY(1:end-1)), num2cell(gazePosZ(1:end-1)), trialDirection(1:end-1), num2cell(y)]),csvname,'writevariablenames',0)
            
            
            
            counter = counter +1;
            
        end
        
        
        
    end
    
end