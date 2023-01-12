clear;
close all;

singleOrMulti = questdlg('Do you want to graph multiple position path plots, single position path plots, or height plots?','Type of Plot?????','Multiple','Single', 'Height', 'Height');

switch singleOrMulti
    case 'Multiple'
        lineThickness = questdlg('Do you want the graph lines to have speed-dependent varying thickness?','Line Thickness?????', 'Yes', 'No', 'No');
        switch lineThickness
            case 'Yes'
                posTrackPlot_multiPath_Subject(1);
            case 'No'
                posTrackPlot_multiPath_Subject(0);
        end
        
        endMsg = msgbox('All done! Congrats', 'yay');

    case 'Single'
%         allOrOne = questdlg('Do you want to graph all datafiles or a specific one?','How Many Plot?????', 'A specific one', 'All of them', 'All of them');
%         switch allOrOne
%             case 'A specific one'
% 
%             case 'All of them'
%                 
%         end



        popUpWindow = figure(1);

        bg = uibuttongroup('Visible','off',...
                  'Position',[0 0 1 1],...
                  'SelectionChangedFcn',@bselection);

        oneOrAllString = uicontrol(popUpWindow, 'Style','text', 'String', 'Do you want to graph all datafiles or a specific one?',  'Position',[10 375 250 30], 'HandleVisibility','off');
        
        allGraph = uicontrol(bg,'Style','radiobutton', 'String', 'All of them',  'Position',[10 350 100 30], 'HandleVisibility','off');
        justONe = uicontrol(bg,'Style','radiobutton', 'String', 'One specific one',  'Position',[250 350 100 30], 'HandleVisibility','off');
        
        bg.Visible = 'on';
        justONe.Value;

        plotThicknessBool = uicontrol(bg,'Style','checkbox', 'String', 'Check this if you want the graph lines to have speed-dependent varying thickness',  'Position',[10 300 450 30], 'HandleVisibility','off');
        
        filenameString1 = uicontrol(popUpWindow, 'Style','text', 'String', 'If you selected to plot from a single file, enter the filename below',  'Position',[10 250 315 30], 'HandleVisibility','off');       
        filenameString2 = uicontrol(popUpWindow, 'Style','text', 'String', 'Ex. AR03_12-01-21_Combined_Layout 4_posTracking_.csv',  'Position',[10 230 300 30], 'HandleVisibility','off');

        filenameEditBox = uicontrol(popUpWindow, 'Style','edit', 'Position',[10 200 300 30], 'HandleVisibility','off');

        goButton = uicontrol(popUpWindow, 'Style','pushbutton', 'String', 'Graph!', 'Position',[10 100 300 30], 'HandleVisibility','off', 'Callback', {@startButtonPushed, bg, plotThicknessBool, filenameEditBox});

        %waitMsg = msgbox('Wait a bit while the graph(s) load up!', 'wait pls');
    case 'Height'
        posTrackPlot_Height_v2;
end


    function startButtonPushed(src,event, bg, plotThicknessBool, filenameEditBox)
        if strcmp(bg.SelectedObject.String, 'One specific one')
            posTrackPlot_singlePath_Condition_byName(filenameEditBox.String, plotThicknessBool.Value);
        else%if strcmp(bg.SelectedObject.String, 'All of them')
            %yee = plotThicknessBool.Value
            posTrackPlot_singlePath_Condition(plotThicknessBool.Value);
            %yee = plotThicknessBool.Value
        end

        endMsg = msgbox('All done! Congrats', 'yay');
    end  

    function bselection(source,event)
       disp(['Previous: ' event.OldValue.String]);
       disp(['Current: ' event.NewValue.String]);
       disp('------------------');
    end