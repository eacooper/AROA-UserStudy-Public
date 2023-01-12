%Takes in a path figure, returns the same figure with rotation information
% plotted along the path. Intended to be analagous to plotSpeedScaledCircles.
% Note that this script only plots based on distance, not speed.

function outFig = plotPathRotation(inFig, x, y, z, t, dists, rotX, rotY, rotZ, isBackward, topDown, interval)
    %inFig: figure to update with rotations
    %x, y, z: position data
    %t: time data
    %rotX, rotY, rotZ: rotation data
    %isBackward: 0 = forward, 1 = backward
    %topDown: assumes a top-down graph if true, side-on if false
    %interval: frequency in meters to plot an arrow

    figure(inFig);

    %Set indices at which distance pass interval threshold
    indices = ones(floor(sum(dists)/interval),1);
    %disp("Sum (dists): " + sum(dists) + "; interval: " + interval + "; " + floor(sum(dists)/interval) + " arrows to be drawn.");
    counter = 1;
    cumulDists = cumsum(dists);
    for n = 1:length(dists)
        if cumulDists(n) >= (counter*interval) 
            indices(counter) = n;
            %disp("Counter: " + counter + "; Indices (counter): " + indices(counter));
            counter = counter + 1;
        end
    end


    %% Plotting
    arrowLength = 0.3;
    lineWidth = 1;
    maxHeadSize = 4;
    color = 'red';%[217/255 140/255 179/255];
    if(isBackward)
        backMult = -1;
    else
        backMult = 1;
    end

    if topDown
        for n = 1:length(indices)
            quiver(z(indices(n)), -x(indices(n)), backMult*arrowLength*cosd(rotY(indices(n))), (arrowLength*sind(rotY(indices(n)))), ...
                'Color', color, 'LineWidth', lineWidth, 'MaxHeadSize', maxHeadSize);
            %disp("Quiver has run " + n + " times.");
        end


    else
        for n = 1:length(indices)
            quiver(z(indices(n)), y(indices(n)), backMult*arrowLength*cosd(rotX(indices(n))), -(arrowLength*sind(rotX(indices(n)))), ...
                'Color', color, 'LineWidth', lineWidth, 'MaxHeadSize', maxHeadSize);
        end


    end

    outFig = inFig;

    return;

end