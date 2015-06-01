function multiCellFluorPlotter(figureHandle, signalMaps, roiSets,...
                               stimVariable,stimulus, fileInfo, MIP,...
                               drawMethod)
%MULTICELLFLUORPLOTTER Summary of this function goes here
%   Detailed explanation goes here

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% CREATE A STATE STRUCTURE FOR PASSING VARS BETWEEN FUNCS %%%%%%%%%%%
% We are going to have several functions within this file that need to
% share variables. We therefore create a structure to hold these variable
% and define it as global to all functions that request it.

global mcpState
% The signal maps contains two map objects in a cell array. The first is
% el is all the maps for the non-led condition. The 2 el is the maps for
% all the led trials (note can be empty). The multicellfluorPlotter
% currently only plots non-led data. Therefore we get the first el here.
mcpState.signalMaps = signalMaps{1};
mcpState.roiSets = roiSets;
mcpState.stimVariable = stimVariable;
mcpState.stimulus = stimulus;
mcpState.fileInfo = fileInfo;
mcpState.MIP = MIP;
mcpState.drawMethod = drawMethod;

% initialize the roi to be the first one in the roiSets

% We need to locate the first roi in the SignalMaps. 
roiSetIndices = find(~cellfun(@(x) isempty(x), roiSets));
% The initial roi will be the first one from the first non-empty set
mcpState.currentRoi = [roiSetIndices(1), 1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% DETERMINE MAP DIMS IN SIGNAL MAPS %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We need to determine whether the signalMaps are one-dim (i.e. one
% variable was varied, orientation, contrast, sf etc) or two-dim (i.e. like
% center-surround stimulus) This will determine the layout of the figure
% and the plotting routine we will call to display the signals.
% get the values from the map for the first roi
mapOfRoi1 = mcpState.signalMaps{mcpState.currentRoi(1)}{1}.values;
% now examine whether the first values is a one-dim cell or 2-dim cell by
% looking for the minimum in the size of the first cell
mapSize = size(mapOfRoi1{1});
if numel(mapSize) > 2
    mapDim = numel(mapSize);
    
elseif numel(mapSize) == 2 && mapSize(2) > 1
    mapDim = 2;
    
elseif numel(mapSize) == 2 && mapSize(2) == 1
    mapDim = 1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% SET UP FIGURE/AXES/UICONTROLS %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will create a figure with a position that depends on whether the map
% is 1-dim or 2-dim. 
if mapDim == 1;
    % adjust the incoming figure position and size
    set(figureHandle,'position',[422 530 1190 350]);
    % set the position the imageAxes for displaying rois (normed units)
    imAxesPos = [0.02 .2 .2 .75];
    % set the position of the signal axes for displaying signals
    sigAxesPos = [0.3 .1 .65 .85];
    % set the position of the uicontrols
    nextRoiPos = [.12 .05 .10 .1];
    lastRoiPos = [.02 .05 .10 .1];
    
elseif mapDim == 2;
    % adjust the incoming figure position and size
    set(figureHandle,'position',[ 597 162 1206 726]);
    % set the position the imageAxes for displaying rois (normed units)
    imAxesPos = [0.02 .4 .2 .35];
    % set the position of the signal axes for displaying signals
    sigAxesPos = [0.3 .1 .65 .85];
    % set the position of the uicontrols
    nextRoiPos = [.12 .3 .10 .05];
    lastRoiPos = [.02 .3 .10 .05];
    disp(['The number of parameters varied equals 2.',...
        'Currently multicellfluorPlotter only supports 1-dim data']);
    error('Dimensions not currently supported');
    
elseif mapDim > 2;
    disp(['The number of parameters varied are greater than 2.',...
        'Currently the analysis software only supports 1 and 2-Dim data']);
    error('Dimensions not currently supported');
end

% Create an image axis for the roi drawings and a fluorAxes for the signals
% to be displayed to.
mcpState.hImageAxes = axes('Units', 'normalized','Position',...
                            imAxesPos, 'XTickLabel','',...
                            'YTickLabel','');
        
mcpState.hFluorAxes = axes('Units', 'normalized','Position',...
                            sigAxesPos);

% Create a uicontrols to allow user to cycle through the rois
nextRoi = uicontrol('Style','pushbutton','String', 'Next Roi >>',...
                        'FontSize',12,'FontWeight','bold','Units',...
                        'normalized', 'Position',...
                        nextRoiPos,'Callback',...
                        @nextRoiPush);
                    
lastRoi = uicontrol('Style','pushbutton','String',...
                            '<< Last Roi','FontSize',12,...
                            'FontWeight','bold','Units',...
                            'normalized',...
                            'Position', lastRoiPos ,'Callback',...
                            @lastRoiPush);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% MAKE INITIAL DRAW OF MIP IMAGE/ROIS/SIGNALS %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% When the figure opens we need to immediately draw the maximum intensity
% projection image (2) draw all the rois and highlight the  first one in 
% the roiSets (3) draw the first signal in the signal maps

% Set the current axis to be the image axis and draw the max intensity
% projection to this axis
axes(mcpState.hImageAxes)
imshow(mcpState.MIP, [min(mcpState.MIP(:)),max(mcpState.MIP(:))]);

% call roiPlotter to draw all the rois in the roiSets
for roiSet = 1:numel(mcpState.roiSets)
if ~isempty(mcpState.roiSets{roiSet})
    % if the set is not empty, then we will draw each of the roi polygons
    for roi = 1:numel(mcpState.roiSets{roiSet})
        roiPlotter(mcpState.roiSets{roiSet}{roi}, 'b',...
            mcpState.hImageAxes,drawMethod)
    end
end
end

% hold the image axis and replot the current roi (x,y) pairs in mcpState as
% red
hold(mcpState.hImageAxes, 'on');
plot(mcpState.roiSets{1}{1}(:,1),mcpState.roiSets{1}{1}(:,2),'r',...
    'LineWidth',3)

hold(mcpState.hImageAxes, 'off');

% Now set the current axis as the fluorAxes and plot the current roi's
% signal stored in mcpState.signalMaps
axes(mcpState.hFluorAxes)
% We call the fluorPlotter to generate our plot
fluorPlotter(...
    mcpState.signalMaps{mcpState.currentRoi(1)}{mcpState.currentRoi(2)},...
    mcpState.stimVariable,mcpState.stimulus,mcpState.fileInfo)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% PUSHBUTTON CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% When the user presses the next or last roi we need to:
% 1. update the currentRoi in state using the nestedCellCycler
% 2. redraw the MIP, all rois and current roi
% 3. draw the new signal to the fluorAxes

%%%%%%%%%%%%%%%%%%%%%%%%%%%% NEXT CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nextRoiPush(hObject, eventdata)
global mcpState

% call the nestedCellCycler to determine the next roi in the roiSets and
% update the currentRoi in state
newRoi = nestedCellCycler(mcpState.roiSets,'forward',mcpState.currentRoi);
mcpState.currentRoi = newRoi;

% Set the current axis to be the image axis and display the max intensity
% image
axes(mcpState.hImageAxes)
imshow(mcpState.MIP, [min(mcpState.MIP(:)),max(mcpState.MIP(:))]);

% redraw each of the rois in roiSets using roiPlotter
for roiSet = 1:numel(mcpState.roiSets)
    if ~isempty(mcpState.roiSets{roiSet})
        % if the set is not empty,  we will draw each of the roi polygons
        for roi = 1:numel(mcpState.roiSets{roiSet})
            roiPlotter(mcpState.roiSets{roiSet}{roi}, 'b',...
                mcpState.hImageAxes,mcpState.drawMethod)
        end
    end
end

% hold the MIP/Roi plot and plot the current roi with a heavy red roi
hold(mcpState.hImageAxes, 'on');
plot(...
    mcpState.roiSets{newRoi(1)}{newRoi(2)}(:,1), ...
    mcpState.roiSets{newRoi(1)}{newRoi(2)}(:,2),'r',...
    'LineWidth',3)
hold(mcpState.hImageAxes, 'off');    

% Now switch the active axis to the fluorAxes and call the fluorPlotter to
% update the signal plotted
axes(mcpState.hFluorAxes)

fluorPlotter(mcpState.signalMaps{newRoi(1)}{newRoi(2)},...
        mcpState.stimVariable,mcpState.stimulus,mcpState.fileInfo)

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LAST CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%
function lastRoiPush(hObject,eventdata)
global mcpState

% Call the nestedCellCycler in reverse mode and update the currentRoi in
% state
newRoi = nestedCellCycler(mcpState.roiSets,'reverse',mcpState.currentRoi);
mcpState.currentRoi = newRoi;

% Set the current axis to be the image axis and display the max intensity
% image
axes(mcpState.hImageAxes)
imshow(mcpState.MIP, [min(mcpState.MIP(:)),max(mcpState.MIP(:))]);

% redraw each of the rois in roiSets using roiPlotter
for roiSet = 1:numel(mcpState.roiSets)
    if ~isempty(mcpState.roiSets{roiSet})
        % if the set is not empty,  we will draw each of the roi polygons
        for roi = 1:numel(mcpState.roiSets{roiSet})
            roiPlotter(mcpState.roiSets{roiSet}{roi}, 'b',...
                mcpState.hImageAxes,mcpState.drawMethod)
        end
    end
end

% hold the MIP/Roi plot and plot the current roi with a heavy red roi
hold(mcpState.hImageAxes, 'on');
plot(...
    mcpState.roiSets{newRoi(1)}{newRoi(2)}(:,1), ...
    mcpState.roiSets{newRoi(1)}{newRoi(2)}(:,2),'r',...
    'LineWidth',3)
hold(mcpState.hImageAxes, 'off'); 

% Now switch the active axis to the fluorAxes and call the fluorPlotter to
% update the signal plotted
axes(mcpState.hFluorAxes)

fluorPlotter(...
    mcpState.signalMaps{mcpState.currentRoi(1)}{mcpState.currentRoi(2)},...
    mcpState.stimVariable,mcpState.stimulus,mcpState.fileInfo)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%