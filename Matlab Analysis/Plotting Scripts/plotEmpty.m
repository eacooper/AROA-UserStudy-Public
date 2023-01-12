%Plots empty layouts

function plotEmpty (layoutNum, isForward, topDown)

% layoutNum = layout to use
% forward = forward if true, backward if false
% topDown -> 1 if top-down graph, 0 if side-on graph

    close all;

    %disp(strcat("Now plotting empty course, layout number ", layoutNum));
    

%% File Setup

    %Opens the file
        %Opens up a figure window
        fig = figure(1);
        ax1 = axes;
        grid on;
        hold on;
        %Set the scale ratio to be 1
        set(gca,'DataAspectRatio',[1 1 1], 'color', 'none');%'XTick',[], 'YTick', [])
        %Sets the size of the graph in pixels
        set(gcf,'Position',[0, 0, 1800, 450]);%maxX*400,maxY*400]);
        %Resizes the axes within the figure (as a proportion of the total figure size
        set(gca,'OuterPosition',[0.02, 0, 0.97, 0.97])
  
    
        %% Plotting
    
        % Top-down plot (aka horizontal)
        if (topDown)

            % Set limits for graph
            minX = 0;
            maxX = 15;
            minY = -0.9;
            maxY = 0.9;
            tick = 0.3;
    
            startHeight = -0.3;
            typeText = "top down";
            heightVal = 0;
            %hudCuesInput = x;
            
            %Plotting the START/END text
            if (isForward)
                txt = {'START'};
            else
                txt = {'END'};
            end
            %t1 = text(-0.55, startHeight, txt);
            t1 = text (0.1, 1.1, txt);
            t1.FontName = 'Gill Sans MT';
            t1.FontSize = 20;
            %t1.Rotation = 90;
    
        else % side-on
           
            % Set limits for graph
            minX = 0;
            maxX = 15;
            minY = 0;
            maxY = 2.5;
            tick = 0.5;
    
            startHeight = 1;
            typeText = "side on";
            heightVal = 1.7;
    
            %Plotting the START/END text
            if (isForward)
                txt = {'START'};
            else
                txt = {'END'};
            end
            %t1 = text(-0.55, startHeight, txt);
            t1 = text (0.1, 2.7, txt);
            t1.FontName = 'Gill Sans MT';
            t1.FontSize = 20;
            %t1.Rotation = 90;            
    
        end
        
        % Set axes parameters
        xlim([minX maxX]);
        ylim([minY maxY]);
        ax = gca;
        ax.Clipping = 'off';
        ax.FontName = 'Gill Sans MT';
        ax.FontSize = 20;
    
        % Tick marks
        set(gca,'XTick', minX:1.5:maxX, 'YTick', minY:tick:maxY);
    
        % Tight border around the graph
        set(gca,'LooseInset',get(gca,'TightInset'));   
    
        %Surrounding Bars for Indicating where the Hallway is
        borderX = 0:0.1:15;
        borderY1 = minY * ones(length(borderX), 1);
        borderY2 = maxY * ones(length(borderX), 1); 
        plot(borderX, borderY1, 'k', 'Linewidth', 3, 'Color', '#737373');
        plot(borderX, borderY2, 'k', 'Linewidth', 3, 'Color', '#737373');
    
        %Plotting the 1m scale marking
        refX = 14:0.1:15;
        refY = (borderY2(1)+0.15)*ones(length(refX), 1);
        plot(refX, refY, 'k', 'Linewidth', 2);
    
        %Plotting the 1m scale text
        txt = {'1m'};
        t1 = text(14.7,refY(1)+0.15,txt);
        t1.FontName = 'Gill Sans MT';
        t1.FontSize = 20;
       
    
        %Plotting name text
        nameText = strcat("Obstacle Course");
        t2 = text(0.25, borderY1(1)-0.5, nameText); 
        t2.FontName = 'Gill Sans MT';
        t2.FontSize = 24;
    
    
        % Overlay obstacles
        fig = overlayObstacles(fig, layoutNum, topDown, heightVal);        

    
        % In graph
        if topDown %Just draw ellipses representing head and shoulders seen from above
            annotation('ellipse', [0.082 0.415 0.01 0.15], 'FaceColor', 'black'); %Shoulders
            annotation('ellipse', [0.08 0.46 0.015 0.06], 'Color', '#888', 'LineWidth', 2, 'FaceColor', 'black'); %head
    
            % Draw arrow and arms to indicate direction
            if (~isForward)
                annotation('ellipse', [0.073 0.41 0.015 0.02], 'FaceColor', 'black');
                annotation('ellipse', [0.073 0.55 0.015 0.02], 'FaceColor', 'black');                   
                annotation('arrow', [0.11 0.08], [0.6 0.6])
            else
                annotation('ellipse', [0.086 0.41 0.015 0.02], 'FaceColor', 'black');
                annotation('ellipse', [0.086 0.55 0.015 0.02], 'FaceColor', 'black');                
                annotation('arrow', [0.08 0.11], [0.6 0.6])
            end
            annotation("textbox", [.06 .4 .3 .3], 'String', 'Top-down', 'FitBoxToText', 'on', 'FontSize', 16, 'LineStyle', 'none');
            %annotation("rectangle", [.07 .725 .055 .18]);
        else % draw a little person
            % head
            annotation('ellipse', [0.075 0.55 0.02 0.08], 'FaceColor', 'black');
            % body
            annotation('ellipse', [0.075 0.35 0.02 0.2], 'FaceColor', 'black');
            % legs
            annotation('rectangle', [0.095 0.181 0.008 0.2], 'FaceColor', 'black', 'Rotation', 15);
            annotation('rectangle', [0.065 0.181 0.008 0.2], 'FaceColor', 'black', 'Rotation', -15);
            % Draw arrow and arm to indicate direction
            if (~isForward)
                annotation('arrow', [0.1 0.07], [0.7 0.7])
                annotation('rectangle', [0.051 0.415 0.008 0.12], 'FaceColor', 'black', 'Rotation', -60);
            else
                annotation('arrow', [0.07 0.1], [0.7 0.7])
                annotation('rectangle', [0.11 0.415 0.008 0.12], 'FaceColor', 'black', 'Rotation', 60);
            end
            annotation("textbox", [.06 .5 .3 .3], 'String', 'Side-on', 'FitBoxToText', 'on', 'FontSize', 16, 'LineStyle', 'none');
            %annotation("rectangle", [.066 .805 .057 .19]);
        end
    
        %% Saving
    
        %Defines folderpath to save the figures to
        folderPath = strcat('../posFiguresV3/Empty Layout');
        
        if ~exist(folderPath, 'dir')
            mkdir(folderPath);
        end

        if (isForward)
            directionString = "Forward";
        else 
            directionString = "Backward";
        end

        if (topDown)
            orientationString = "Top Down";
        else
            orientationString = "Side On";
        end
    
        %Saves the figure as a .png 
        filePath = strcat(folderPath,"/", "Empty Layout ", string(layoutNum), "_", orientationString, "_", directionString);
        
        saveas(fig, strcat(filePath,'.fig'));
        %exportgraphics(fig,strcat(filePath,'.png'),'Resolution',900); %%For really high resolution pngs
        saveas(fig, strcat(filePath,'.png')); %lower resolution pngs, but fast   
    

end

