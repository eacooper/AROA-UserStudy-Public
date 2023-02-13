% Adds circles at consistent time intervals along the participant's path.

function outFig = overlayCircles(z, x, t, inFig, interval)
        % z, x, t: location and time logs
        % dists: distances between each entry
        % inFig: input figure to draw on
        % interval: every however many second each circle should be plotted
        % Eg. 0.5 = plot every 0.5 seconds
        
        n = 0;
        %This is where the indices go into
        %There's as many indices as the number of times the interval goes
        %into the total time elapsed
        indices= ones(floor(t(end)/interval),1);
        counter = 1;
        while n < length(t)
            n = n+1;
            if t(n)>=(counter*interval)
                indices(counter) = n;
                counter = counter+1;
            end
        end

        figure(inFig);

        scatter(z(indices), -x(indices), 30, [217/255 140/255 179/255], 'filled');
        outFig = inFig;

        return;
end

