function simpleCSArealPlot(roiSetNum, roiNum, userAngle)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2012  Matthew Caudill
%
%this program is free software: you can redistribute it and/or modify
%it under the terms of the gnu general public license as published by
%the free software foundation, either version 3 of the license, or
%at your option) any later version.
%
%this program is distributed in the hope that it will be useful,
%but without any warranty; without even the implied warranty of
%merchantability or fitness for a particular purpose.  see the
%gnu general public license for more details.
%
%you should have received a copy of the gnu general public license
%along with this program.  if not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simpleCSArealPlot approximates the areas below the curve for simple
% center surround data for an roi from an imExp_roi. The roi is specified
% by the roiSetNum and roi number in the roi sets substructure of the
% imExp.
% INPUTS:                           RoiSetNum: index used to idetify the
%                                              stimulus set containing rois
%                                   roiNum:    index used to identify a
%                                              particular roi within a
%                                              roiSet
%                                   :     angles user would like to
%                                              calculate area for. Options
%                                              scalar or string 'all'.
%                                              'all' displays data for all
%                                              angles

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% LOAD SPECIFIC FIELDS FROM IMEXP %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will load the fileInfo, signalMaps and stimulus structures from a user
% selected imExp using uigetfile gui (builtin)
ImExpDirInformation

[imExpName, path] = uigetfile(dirInfo.imExpRoiFileLoc, 'MultiSelect', 'off');
try
    load(fullfile(path,imExpName), 'fileInfo', 'signalMaps',...
                                  'stimulus');
catch 
    % Throw an error if the signal maps are not present in imExp
    errordlg(['FAILED TO LOAD SIGNAL MAPS' char(10),...
                  'CHECK FOR SIGNALS STRUCT IN IMEXP']);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','signalMaps',signalMaps);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% ERROR CHECK THE EXP TYPE %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We check that the experiment is a simple center surround stimulus imExp
if ~(strcmp(stimulus(1,1).Stimulus_Type, 'Simple Center-surround Grating'))
    errordlg('imExp is not a Center-surround Grating exp');
end

if ~isscalar(userAngle) && ~strcmp(userAngle,'all')
    error('simpleCSAreaPlot:InvalidAngle',...
        'Please enter a scalar or all for the userAngle argument')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% CALL THE CS PLOTTER %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a figure to plot subplots of the df/f signal across surround
% orientations

% Create a new figure by getting the number of current figures
numFigs=length(findall(0,'type','figure'));
% create a figure one greater than the number of open figures
hFig = figure(numFigs+1);

% Set up a uicontrol for a super title
uicontrol('Style', 'text', 'String', imExpName, ...
'HorizontalAlignment', 'center', 'Units', 'normalized', ...
'Position', [0 .95 1 .05], 'BackgroundColor', [.8 .8 .8],'FontSize', 16);

csPlotter(signalMaps{roiSetNum}{roiNum}, userAngle, stimulus, fileInfo, hFig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% OBTAIN MEAN + STD OF AREAS  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% obatain the signals of the map for the specified roi. Recall that
% signalMaps{RoiSetNum}{roiNum} contatins a cell array that is numFiles *
% numSurroundConditions in size
if isscalar(userAngle)
    % Check that the user supplied userAngle is a key in the map of this roi
    if isKey(signalMaps{roiSetNum}{roiNum},userAngle)
        allSignals = {signalMaps{roiSetNum}{roiNum}(userAngle)};
    end
    
elseif strcmp(userAngle,'all')
    % if the user has selected to see all angles, then we just get all the
    % signal map values
    allSignals = signalMaps{roiSetNum}{roiNum}.values;
else
    error('simpleCSAreaPlot:InvalidAngle',...
        'User selected userAngle may not be a key in this map')
end

% calculate the start and end frame of the stimulus epoch
startFrame = round(stimulus(1,1).Timing(1)*fileInfo(1,1).imageFrameRate);
endFrame = round((stimulus(1,1).Timing(1) + ...
                  stimulus(1,1).Timing(2))*fileInfo(1,1).imageFrameRate);

% We will no loop throught the angles (i.e. outer index of allSignals).
% Each will return a cell that is numTrials*numConds. We will compute the
% areas under each using cellfun then convert to a matrix and get the mean
% and standard deviations. more explanation to follow
for angle = 1:numel(allSignals)
    % for each angle, we have a cell array of numTrials*numConds. We will
    % use cellfun to compute the areas under each trial/cond
    areas = cellfun(@(x) trapz(x(startFrame:endFrame)),...
                    allSignals{angle}, 'UniformOut',0);
    % we will no convert the areas of the trials,conds to a matrix
    areaMat = cell2mat(areas);
    % compute the mean area across trials (i.e. dim 1)
    meanAreas{angle} = mean(areaMat,1);
    % swap cols so that conds now read center alone. cross1 iso cross2
    % surrAlone
    meanAreas{angle}(:,[3,4]) = meanAreas{angle}(:,[4,3]);
    % and compute the std across trials
    stdDevAreas{angle} = std(areaMat,1);
    stdDevAreas{angle}(:,[3,4]) = stdDevAreas{angle}(:,[4,3]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','meanAreas', meanAreas)
assignin('base','stdDevAreas', stdDevAreas)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a new figure by getting the number of current figures
numFigs=length(findall(0,'type','figure'));
% create a figure one greater than the number of open figures
h2 = figure(numFigs+1);

% Set figure position based on the number of angles to be shown
if strcmp(userAngle,'all')
    set(h2,'position',[1211 143 483 752])
else
    set(h2,'position',[1193 401 483 297])
end

for angle = 1:numel(allSignals)
    % Create subplots only if angles is 'all'
    if strcmp(userAngle,'all')
        subplot(numel(allSignals),1,angle)
    end
    % ignore first col which is center only
    errorbar(meanAreas{angle}(2:end), stdDevAreas{angle}(2:end),...
                '--bo','MarkerEdgeColor','b')
    hold on
    % now plot center only separately
    errorbar(2, meanAreas{angle}(1), stdDevAreas{angle}(1),...
                'or','MarkerEdgeColor','r')
            
    % compute SOI value and print to graph
    soi = ...
        (meanAreas{angle}(2)+ meanAreas{angle}(4))/(2*meanAreas{angle}(3));
    
    title(num2str(soi));
    
    % only set xTicks for lowest axis
    if angle < numel(allSignals)
        set(gca,'XTickLabel','')
    else
        set(gca,'XTick',(1:1:numel(allSignals)-1))
        set(gca,'XTickLabel',{'C1', 'ISO', 'C2', 'SO'})
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

