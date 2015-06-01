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
function accumFluorPlot(stimFileNum, roiNum)
% accumFluorPlot approximates the area below the signal map curve of
% center/surround data for an roi specified by stimFileNum, roiNum.
% INPUTS:                   
%                           stimFileNum:  index of the stimulus file in the
%                                         imExp (used as 1st index to
%                                         identify specific roi)
%                           roiNum:       index of the roi number drawn
%                                         on a tiffImage associated with
%                                         stimFileNum

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% LOAD SPECIFIC VARS FROM IMEXP %%%%%%%%%%%%%%%%%%%%%%
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% ERROR CHECK THE EXP TYPE %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now check that the experiment is a center surround stimulus imExp and
% retrieve the center orientation
if any(strcmp({stimulus(:,:).Stimulus_Type}, 'Center-surround Grating'))
    centerAngle = stimulus(1,1).Center_Orientation;
else
    errordlg('imExp is not a Center-surround Grating exp');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% CALL THE FLUOR PLOTTER %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a figure to plot subplots of the df/f signal and the signal area
% across surround orientations
hFig = figure;
% Set up a uicontrol for a super title
uicontrol('Style', 'text', 'String', imExpName, ...
'HorizontalAlignment', 'center', 'Units', 'normalized', ...
'Position', [0 .9 1 .05], 'BackgroundColor', [.8 .8 .8],'FontSize', 16);

% We will make a subplot plot of the fluorescent signals first calling the
% fluorPlotter
subplot(2,1,1)
fluorPlotter(signalMaps{stimFileNum}{roiNum},...
             'Surround_Orientation', stimulus, fileInfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% OBTAIN MAP VALUES AND KEYS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% obatain the signals of the map for the specified roi
allSignals = signalMaps{stimFileNum}{roiNum}.values;
% obtain all the surround angles of the map
surroundAngles = cell2mat(signalMaps{stimFileNum}{roiNum}.keys);
% Set the blank condiditon
surroundAngles(end) = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% CONVERT SIGNAL CELLS TO MATRICES %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now convert the signals cell array containing signals for all
% trials into a set of matrices, where each matrix will contain the signals
% for each trial columnwise. 
signalMatrices = cellfun(@(y) cell2mat(y), allSignals, 'UniformOut', 0);

% Retrieve the center only mean siganls
centerSigs = signalMatrices{end};

signalMatrices(end) = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% COMPUTE THE AREA BELOW EACH MEAN SIGNAL %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here we will compute the area below each trial of the signal matrices for
% each cell

% calculate the start and end frame of the stimulus epoch
startFrame = round(stimulus(1,1).Timing(1)*fileInfo(1,1).imageFrameRate);
endFrame = round((stimulus(1,1).Timing(1) + ...
                  stimulus(1,1).Timing(2))*fileInfo(1,1).imageFrameRate);
              
signalAreas = cellfun(@(r) trapz(r(startFrame:endFrame,:)),...
                      signalMatrices, 'UniformOut', 0);
                  
% compute the mean of signalAreas
meanSignalAreas = cellfun(@(e) mean(e,2), signalAreas);
% compute the standard deviation of the signal area
stdSignalAreas = cellfun(@(t) std(t), signalAreas);

% compute the areas below the center only signals
centerAreas = trapz(centerSigs(startFrame:endFrame,:));
% compute the mean of the center only areas
meanCenterArea = mean(centerAreas);
% compute the standard deviation of the center only responses
stdDevCenterAreas = std(centerAreas);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% SHIFT THE CENTER RESPONSE AND ANGLES %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now shift the signals and the angles so that the center +
% isoorientation are always at or near center of our plot

% shift the angles and the signals
%Locate the centerAngle index
index = find(surroundAngles==centerAngle);
% locate the center index of all angles
centerIndex = round(numel(surroundAngles)/2);
% circular shift the index to the center index for the angles
angles = circshift(surroundAngles, [0,centerIndex-index]);
% Do the same for the mean signals and the stdSignals
sMeanSignalAreas = circshift(meanSignalAreas, [0,centerIndex-index]);
sStdSignalAreas =  circshift(stdSignalAreas, [0,centerIndex-index]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,1,2)
errorbar(sMeanSignalAreas, sStdSignalAreas, '--k')
% Construct a cell of strings that will be the surround angles
% convert angles array to a cell of angles
anglesCell = num2cell(angles);
% use cellfun to convert each angle to a string
anglesCellStr = cellfun(@(t) num2str(t), anglesCell, 'UniformOut', 0);
% set the xTick labels and xTicks
set(gca,'XTick',(1:1:numel(anglesCellStr)))
set(gca,'XTickLabel',anglesCellStr)
% Set axis labels
xlabel('Surround Orientation Angle', 'FontSize', 14)
ylabel('Accumulated DF/F','FontSize', 14)

% Now plot the single point for the center only response
hold on
errorbar(centerIndex,meanCenterArea, stdDevCenterAreas,'or',...
            'MarkerEdgeColor','r', 'MarkerFaceColor','r')
% set figure to a nice position
set(gcf,'Position',[485 100 960 630])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% output the vector [center, cross1, cross2, iso1, iso2] to the screen
[meanCenterArea ,sMeanSignalAreas(1), sMeanSignalAreas(3),...
    sMeanSignalAreas(2), sMeanSignalAreas(4)]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVING FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

expTargetLoc ='G:\data\Figures\RoughFigs\CaImaging\ArealSuppressionPlots\';

defaultName = [expTargetLoc, imExpName(1:end-14),...
    '_' 'arealSupp','_',num2str(stimFileNum),'-',num2str(roiNum),'.fig'];

% Use uiputfile to allow user to save to a directory of their choice
% suggesting the default name as the save name (note they can overide with
% their own name if they wish)
[fileName,pathName] = uiputfile(expTargetLoc,'Save As',defaultName);

file = fullfile(pathName,fileName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(fileName) && ischar(pathName)
    saveas(gcf, file, 'fig');
else
    warndlg('WARNING: FIGURE NOT SAVED')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

