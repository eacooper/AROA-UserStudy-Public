% Adds circles at consistent intervals along the participant's path.
% Originally this adjusted size or color of circles according to speed, but
% since then has been adjusted to plot consistent circles at simple
% intervals. Thus, much of this code can be removed.

function outFig = plotSpeedScaledCircles(z, x, t, dists, sampRate, inFig, colour, byTimeOrDist, intervalSecOrM)
        % z, x, t: location and time logs
        % dists: distances between each entry
        % sampRate: frequency of sampling (default 50 for 50 hz)
        % inFig: input figure to draw on
        % colour: color to use
        % byTimeOrDist: 0 = time, 1 = dist
        % intervalSecOrM: every however many second or meters each circle should be plotted
        % Eg. 1, 1 here would be per every 1m; 0, 2 would be every 2s
        
        indices = 0;
        if byTimeOrDist ==1 %For distance interval
            n = 0;
            %This is where the indices go into
            %There's as many indices as the number of times the interval goes
            %into the total distance travelled
            indices= ones(floor(sum(dists)/intervalSecOrM),1);
            counter = 1;
            %Cumulative distance array
            cumulDists = cumsum(dists);
            while n < length(dists)
                n = n+1;
                if cumulDists(n)>=(counter*intervalSecOrM)
                    indices(counter) = n;
                    counter = counter+1;
                end
            end
        elseif byTimeOrDist == 0 %For time intervals
            n = 0;
            %This is where the indices go into
            %There's as many indices as the number of times the interval goes
            %into the total time elapsed
            indices= ones(floor(t(end)/intervalSecOrM),1);
            counter = 1;
            while n < length(t)
                n = n+1;
                if t(n)>=(counter*intervalSecOrM)
                    indices(counter) = n;
                    counter = counter+1;
                end
            end
        end


        distsNonZero = dists;
%         for n = 2:length(distsNonZero)
%             if distsNonZero(n)== 0
%                 distsNonZero(n) = distsNonZero(n-1);
%             end
%         end

        %Speeds
        distsNonZeroSpeeds = distsNonZero.*sampRate;
        
        maxSpeed = max(distsNonZeroSpeeds);
        minSpeed = min(distsNonZeroSpeeds);
        speedRange = max(distsNonZeroSpeeds) - min(distsNonZeroSpeeds);

        figure(inFig);

%|||||||||||||||||||||||||||||||||||COLOUR ONLY|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
        %How much faster the speed at the current frame is than the minimum speed as a decimal 
        % (current speed minus the minSpeed divided by the range of speeds)
%         speed2Colour = abs(log10((distsNonZeroSpeeds-minSpeed)/speedRange)); %log base 20
%         colourBySpeed = zeros(length(speed2Colour), 3);
% 
%         for n = 1:length(speed2Colour)
%             colourBySpeed(n,:) = [1-speed2Colour(n), 0, speed2Colour(n)]; %Colour more blue when fast, more red when slow
%         end
% 
%         scatter(z(indices), -x(indices), 12, colourBySpeed, 'filled');
%|||||||||||||||||||||||||||||||||||COLOUR ONLY|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
%_________________________________________________________________________________________________________________________________

%|||||||||||||||||||||||||||||||||||SIZE + TRANSPARENCY|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
        %Vary 10 to 50 for diameter
        %speed2Diameter = 10+50*abs(log10((distsNonZeroSpeeds(indices)-minSpeed)/speedRange)); %log base 20
        %speed2Diameter = (max(speed2Diameter)+1)-speed2Diameter
        %speed2Opacity = 0.8+0.2*abs(1-log10((distsNonZeroSpeeds(indices)-minSpeed)/speedRange));
%         indices
% 
%         lengthZ = length(z)
%         lengthDia = length(speed2Diameter)
%        scatter(z(indices), -x(indices), speed2Diameter, [217/255 140/255 179/255], 'filled');%, 'MarkerFaceAlpha',  'flat', 'AlphaData', speed2Opacity);
        scatter(z(indices), -x(indices), 30, [217/255 140/255 179/255], 'filled');%, 'MarkerFaceAlpha',  'flat', 'AlphaData', speed2Opacity);

%|||||||||||||||||||||||||||||||||||SIZE ONLY|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

%_________________________________________________________________________________________________________________________________

%|||||||||||||||||||||||||||||||||||SIZE AND COLOUR|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

%         speed2Diameter = 10+30*abs(log10((distsNonZeroSpeeds-minSpeed)/speedRange));
%         speed2Colour = abs(log10((distsNonZeroSpeeds-minSpeed)/speedRange)); %log base 20
%         colourBySpeed = zeros(length(speed2Colour), 3);
% 
%         for n = 1:length(speed2Colour)
%             colourBySpeed(n,:) = [1-speed2Colour(n), 0, speed2Colour(n)]; %Colour more blue when fast, more red when slow
%         end
% 
%         scatter(z(indices), -x(indices), speed2Diameter, colourBySpeed(indices,:), 'filled');
% %|||||||||||||||||||||||||||||||||||SIZE AND COLOUR|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
% %_________________________________________________________________________________________________________________________________
        outFig = inFig;

        return;
end

