function collocated_scene_maker
    clear all; close all;

    %%UPDATE THE README___________________________

    figure1 = figure(1);
    camTools = cameratoolbar(figure1);

    fileName = 'OA05_22-03-11_Collocated_Layout 5_Forward_posTracking_.csv';

     %Datapath
    datapath = '../PosPCAData/';
    sbjFileName = fileName(1:13);

    sampRate = 50; %Sampling Rate
    ptHeight = 1.651; %OA05 was 5'6''

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
    end
    C = table2array(C(:,[1:7 , 9:13, 15]));
    layoutNum = C(1,8);
   
    %Get z, x, t, y
    z = C(:,1);
    x = C(:,2);
    t = C(:,3);
    y = C(:, 13)+ptHeight;

    %Get head rotation x, y, z
    %Get gaze x, y, z
    rotatoX = C(:, 10);
    rotatoY = C(:, 11);
    rotatoZ = C(:, 12);

    %If the direction is backward, flip the array
    if direcBool == 1
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


    % specify come camera properties

    % location in meters
    cam_x = 0;
    cam_y = ptHeight;
    cam_z = 0;
    
    % horizontal and vertical FOV angles (in deg)
    h_fov = 43;
    v_fov = 30;
    
    % specify location for a virtual object
    obj_x = 0;
    obj_y = 0;
    obj_z = 5;

    %Dimensions
    wideWidthX = 0.9;
    wideHeightY = 1.5;
    wideDepthZ = 0.1;

    highWidthX = 1.8;
    highHeightY = 0.1; %
    highDepthZ = 0.1;

    lowWidthX = 1.8;
    lowHeightY = 0.1;
    lowDepthZ = 0.1;

    % get vertex coordinates for unit radius sphere
    [X,Y,Z] = sphere;
    
    % shift sphere out from origin


%     X = X + obj_x;
%     Y = Y + obj_y;
%     Z = Z + obj_z;

%     figure; hold on;
%     surf(X-1,Y,Z-1);
%     surf(X,Y,Z);

    %Drawing the obstacles
    %Draws the surfaces of the prisms
    hold on;

    drawHallway();

    %drawWides(1, 2, wideWidthX, wideHeightY, wideDepthZ);
    
    xPos = [-0.9, 0];
    yPos = ptHeight - 0.1016; %4 inches
    zPos = [0:1.5:15];

    %Right now it is layout 5

    %Right wide
    p1 = [0, 0, zPos(2)];%bottom left front
    p2 = [0 + wideWidthX, 0, zPos(2)];%bottom right front
    p3 = [0, 0, zPos(2)+wideDepthZ];%bottom left back
    p4 = [0 + wideWidthX, 0, zPos(2)+wideDepthZ];%bottom right back
    p5 = [0, wideHeightY, zPos(2)];%top left front
    p6 = [0 + wideWidthX, wideHeightY, zPos(2)];%top right front
    p7 = [0, wideHeightY, zPos(2)+wideDepthZ];%top left back
    p8 = [0 + wideWidthX, wideHeightY, zPos(2)+wideDepthZ];%top right back

    drawPrism(p1, p2, p3, p4, p5, p6, p7, p8);

    %Left wide
    p1 = [-0.9, 0, zPos(4)];%bottom left front
    p2 = [-0.9 + wideWidthX, 0, zPos(4)];%bottom right front
    p3 = [-0.9, 0, zPos(4)+wideDepthZ];%bottom left back
    p4 = [-0.9 + wideWidthX, 0, zPos(4)+wideDepthZ];%bottom right back
    p5 = [-0.9, wideHeightY, zPos(4)];%top left front
    p6 = [-0.9 + wideWidthX, wideHeightY, zPos(4)];%top right front
    p7 = [-0.9, wideHeightY, zPos(4)+wideDepthZ];%top left back
    p8 = [-0.9 + wideWidthX, wideHeightY, zPos(4)+wideDepthZ];%top right back
    
    drawPrism(p1, p2, p3, p4, p5, p6, p7, p8);

    %High 1
    p1 = [-0.9, yPos, zPos(6)];%bottom left front
    p2 = [-0.9 + highWidthX, yPos, zPos(6)];%bottom right front
    p3 = [-0.9, yPos, zPos(6)+highDepthZ];%bottom left back
    p4 = [-0.9 + highWidthX, yPos, zPos(6)+highDepthZ];%bottom right back
    p5 = [-0.9, yPos+highHeightY, zPos(6)];%top left front
    p6 = [-0.9 + highWidthX, yPos+highHeightY, zPos(6)];%top right front
    p7 = [-0.9, yPos+highHeightY, zPos(6)+highDepthZ];%top left back
    p8 = [-0.9 + highWidthX, yPos+highHeightY, zPos(6)+highDepthZ];%top right back

    drawPrism(p1, p2, p3, p4, p5, p6, p7, p8);

    %High 2
    p1 = [-0.9, yPos, zPos(9)];%bottom left front
    p2 = [-0.9 + highWidthX, yPos, zPos(9)];%bottom right front
    p3 = [-0.9, yPos, zPos(9)+highDepthZ];%bottom left back
    p4 = [-0.9 + highWidthX, yPos, zPos(9)+highDepthZ];%bottom right back
    p5 = [-0.9, yPos+highHeightY, zPos(9)];%top left front
    p6 = [-0.9 + highWidthX, yPos+highHeightY, zPos(9)];%top right front
    p7 = [-0.9, yPos+highHeightY, zPos(9)+highDepthZ];%top left back
    p8 = [-0.9 + highWidthX, yPos+highHeightY, zPos(9)+highDepthZ];%top right back

    drawPrism(p1, p2, p3, p4, p5, p6, p7, p8);

    %Low 1
    p1 = [-0.9, 0, zPos(8)];%bottom left front
    p2 = [-0.9 + highWidthX, 0, zPos(8)];%bottom right front
    p3 = [-0.9, 0, zPos(8)+highDepthZ];%bottom left back
    p4 = [-0.9 + highWidthX, 0, zPos(8)+highDepthZ];%bottom right back
    p5 = [-0.9, 0+highHeightY, zPos(8)];%top left front
    p6 = [-0.9 + highWidthX, 0+highHeightY, zPos(8)];%top right front
    p7 = [-0.9, 0+highHeightY, zPos(8)+highDepthZ];%top left back
    p8 = [-0.9 + highWidthX, 0+highHeightY, zPos(8)+highDepthZ];%top right back

    drawPrism(p1, p2, p3, p4, p5, p6, p7, p8);

    %Low 2
    p1 = [-0.9, 0, zPos(10)];%bottom left front
    p2 = [-0.9 + highWidthX, 0, zPos(10)];%bottom right front
    p3 = [-0.9, 0, zPos(10)+highDepthZ];%bottom left back
    p4 = [-0.9 + highWidthX, 0, zPos(10)+highDepthZ];%bottom right back
    p5 = [-0.9, 0+highHeightY, zPos(10)];%top left front
    p6 = [-0.9 + highWidthX, 0+highHeightY, zPos(10)];%top right front
    p7 = [-0.9, 0+highHeightY, zPos(10)+highDepthZ];%top left back
    p8 = [-0.9 + highWidthX, 0+highHeightY, zPos(10)+highDepthZ];%top right back

    drawPrism(p1, p2, p3, p4, p5, p6, p7, p8);

    axis equal; axis off;
    xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');

    xlim([-0.9, 0.9]);
    ylim([0, 2.5]);
    zlim([0, 17.5]);
    
    %Sets up the camera/"viewer"
    camva(h_fov); % set camera FOV -- need to figure out how to make this non-square - can just put an occluder
    %camup([0 1 0]); % set so that positive y is up

    campos([cam_x cam_y cam_z]); % specify the location of the camera ==> needs to be position x y z from the datafiles
    camproj('perspective'); % assert perspective projection
    
    %camtarget([0 0 1]); % tell camera to look straight down the z axis

    set(gca, 'XDir','reverse')
    axis vis3d;

    % create the video writer with 1 fps
    writerObj = VideoWriter('withZTarget.avi');
    writerObj.FrameRate = sampRate;
    % set the seconds per image

    % open the video writer
    open(writerObj);

    %First Frame
    campos([x(1) y(1) z(1)]);
    camtarget([0 ptHeight 1000]);
    campan(rotatoX(1), rotatoY(1), 'data');
    frame = getframe(gcf);
    writeVideo(writerObj, frame);

    %Writes in the frames
    for n = 2:length(x)
        campos([x(n) y(n) z(n)]);
        %camtarget([x(n)+atan(rotatoZ(n)), (y(n)+atan(360-rotatoX(n))), z(n)+atan(rotatoY(n))]);
        %camtarget([x(n)+atan(rotatoX(n)), (y(n)-atan(rotatoY(n))), z(n)+atan(rotatoZ(n))]);
        %camroll((rotatoZ(n)-rotatoZ(n-1)));
        %cameratoolbar('SetCoordSys','z','SetMode','pan', rotatoZ(n)-rotatoZ(n-1));
        campan(-(rotatoX(n)-rotatoX(n-1)), (rotatoY(n)-rotatoY(n-1)), 'data'); %I think we found that the x-rotation is actually opposite - positive angle = looking down, etc.
        
        frame = getframe(gcf);
        writeVideo(writerObj, frame);
    end


    % close the writer object
    close(writerObj);
end 

function drawPrism = drawPrism(p1, p2, p3, p4, p5, p6, p7, p8)

    x = [p1(1), p2(1), p4(1), p3(1)];
    y = [p1(2), p2(2), p4(2), p3(2)];
    z = [p1(3), p2(3), p4(3), p3(3)];
    fill3(x, y, z, 3, 'FaceAlpha', 0.6); %bottom face

    x = [p5(1), p6(1), p8(1), p7(1)];
    y = [p5(2), p6(2), p8(2), p7(2)];
    z = [p5(3), p6(3), p8(3), p7(3)];
    fill3(x, y, z, 3, 'FaceAlpha', 0.6); %top side

    x = [p1(1), p2(1), p6(1), p5(1)];
    y = [p1(2), p2(2), p6(2), p5(2)];
    z = [p1(3), p2(3), p6(3), p5(3)];
    fill3(x, y, z, 3, 'FaceAlpha', 0.6); %front face
    
    x = [p3(1), p4(1), p8(1), p7(1)];
    y = [p3(2), p4(2), p8(2), p7(2)];
    z = [p3(3), p4(3), p8(3), p7(3)];
    fill3(x, y, z, 3, 'FaceAlpha', 0.6); %back face

    x = [p2(1), p4(1), p8(1), p6(1)];
    y = [p2(2), p4(2), p8(2), p6(2)];
    z = [p2(3), p4(3), p8(3), p6(3)];
    fill3(x, y, z, 3, 'FaceAlpha', 0.6); %right face

    x = [p1(1), p3(1), p7(1), p5(1)];
    y = [p1(2), p3(2), p7(2), p5(2)];
    z = [p1(3), p3(3), p7(3), p5(3)];
    fill3(x, y, z, 3, 'FaceAlpha', 0.6); %left face

    
end

function drawHallway = drawHallway()

    hold on;
    p1 = [-0.9, 0, 0];%bottom left front
    p2 = [0.9, 0, 0];%bottom right front
    p3 = [-0.9, 0, 17.5];%bottom left back
    p4 = [0.9, 0, 17.5];%bottom right back
    p5 = [-0.9, 2.5, 0];%top left front
    p6 = [0.9, 2.5, 0];%top right front
    p7 = [-0.9, 2.5, 17.5];%top left back
    p8 = [0.9, 2.5, 17.5];%top right back

    x = [p1(1), p2(1), p4(1), p3(1)];
    y = [p1(2), p2(2), p4(2), p3(2)];
    z = [p1(3), p2(3), p4(3), p3(3)];
    fill3(x, y, z, [0.75, 0.75, 0.75]); %floor

    x = [p5(1), p6(1), p8(1), p7(1)];
    y = [p5(2), p6(2), p8(2), p7(2)];
    z = [p5(3), p6(3), p8(3), p7(3)];
    fill3(x, y, z, [1, 1, 1], 'FaceAlpha', 0.6); %top side

    x = [p1(1), p2(1), p6(1), p5(1)];
    y = [p1(2), p2(2), p6(2), p5(2)];
    z = [p1(3), p2(3), p6(3), p5(3)];
    fill3(x, y, z, [1, 1, 1], 'FaceAlpha', 0); %front face
    
    x = [p3(1), p4(1), p8(1), p7(1)];
    y = [p3(2), p4(2), p8(2), p7(2)];
    z = [p3(3), p4(3), p8(3), p7(3)];
    fill3(x, y, z, [1, 1, 1], 'FaceAlpha', 0.6); %back face

    x = [p2(1), p4(1), p8(1), p6(1)];
    y = [p2(2), p4(2), p8(2), p6(2)];
    z = [p2(3), p4(3), p8(3), p6(3)];
    fill3(x, y, z, [1, 1, 1], 'FaceAlpha', 0.6); %right face

    x = [p1(1), p3(1), p7(1), p5(1)];
    y = [p1(2), p3(2), p7(2), p5(2)];
    z = [p1(3), p3(3), p7(3), p5(3)];
    fill3(x, y, z, [1, 1, 1], 'FaceAlpha', 0.6); %left face

end

