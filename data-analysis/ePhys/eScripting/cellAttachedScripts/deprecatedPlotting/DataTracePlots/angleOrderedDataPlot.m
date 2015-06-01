function angleOrderedDataPlot(runState, expRunNum, varargin)
%spikePlot creates a plot of filtered data for a given experiment uder the
%running condition parameter
% INPUTS    
%           runState              : integer to seperate trials based on
%                                   running behavior (1 = yes, 0 = No, 
%                                   2= Keep ALL)
%           expRunNum             : tag specifying the trial you wish to
%                                   display (e.g data saved as
%                                   n1orientation_3 has an expRunNum of 3
%                                   bc this is the thrid run of stimuli for
%                                   cell n1
%           varargin
%               downSampleFactor  : for plots (default=4)
%               save:               a logical to determine
%                                   whether to open a save dialog box, 
%                                   defaults to true
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inputParseStruct = inputParser;
% set default values for the options under varargin (saveOption)
defaultSave = true;
defaultDownSampleFactor = 4;

% Add all requried and optional args to the input parser object
addRequired(inputParseStruct,'running',@isnumeric);
addRequired(inputParseStruct,'expRunNum',@isnumeric);
addParamValue(inputParseStruct,'save',defaultSave,@islogical);
addParamValue(inputParseStruct,'downSampleFactor',...
              defaultDownSampleFactor, @isnumeric);

% call the parser
parse(inputParseStruct,runState,expRunNum, varargin{:})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% LOAD FIELDS FROM EXP TO SUBEXP %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We call the function dialogLoadExp to load the specific fields from the
% exp structure. This save considerable computation time becasue the exp
% structure can be very large.
% We need the behavior to evaluate running, the raw data to show filtered
% traces, the stimulus to get the orientation, and the fileInfo to get
% sample rate of the data

subExp = dialogLoadExp('behavior', 'data', 'stimulus', 'fileInfo');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% OBTAIN DATA FROM SUBEXP %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = {subExp.data(expRunNum,:).Voltage};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% OBTAIN RUNNING INFO FROM SUBEXP %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
running = [subExp.behavior(expRunNum,:).Running];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% LOCATE TRIGGERS IN DATA NOT MEETING RUNNINGSTATE COND %%%%%%%%%%
if runState == 0 || runState == 1
    missingTriggs = find(running ~= runState);
else
    % If the user has selected a runState of two then there can be no
    % missing triggs becasue both running and non-running are included
    missingTriggs = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% OBTAIN ANGLES FROM SUBEXP & DETERMINE MISSING ANGLES %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
angles = [subExp.stimulus(expRunNum,:).Orientation];
missingAngles = angles(missingTriggs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% DIALOG WITH USER ABOUT REPLACEMENT OF MISSING ANGLES %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(missingTriggs)
    choice = questdlg(['Angle(s): ',num2str(missingAngles),...
        ' failed to meet the running condition', char(10),...
        ' Should I look for angle(s) in another set of trials?'],...
        'Replace Trigger?',...
        'Yes', 'No', 'Yes');
    % Handle response
    switch choice
        case 'Yes'
            for index=1:numel(missingTriggs)
                data(index) = {findReplacementData(missingTriggs(index))};
            end
            
        case 'No'
            data(missingTriggs) = {[]};
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% SUBFUNCTION TO REPLACE MISSING ANGLES %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If some of the angles contain no data becasue the animal did not meet the
% running condition, we want to provide the user with replacing those data
% triggers with data of the same angle but from a different trial in the
% exp. This subfunction accomplishes this goal by calling oriDataMap to
% find all the data associated with each angle. We then choose the
% replacement from the map
    function [replacedData] =  findReplacementData(missingTrigger)
        % get the angle of the missing trigger
        missingAngle = angles(missingTrigger);
        %construct map object from all data
        DataMap =...
            oriDataMap(runState, subExp.behavior, subExp.data,...
            subExp.stimulus);
        % obtain 
        allData = DataMap(missingAngle);
        if ~isempty(allData)
            % Take the first one from the list
            replacedData = allData{1};
        else
            % In the case where the map contains no data for this angle
            % nothing more can be done and we warn the user that this
            % experiment has no trials with the missing angle data
            Warning(['NO REPLACEMENT DATA COULD BE FOUND' char(10)...
                'MEETING THE RUNNING CONDITION; DATA PLOT WILL BE EMPTY'])
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% SORT DATA BY ANGLE %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~, originalPositions] = sort(angles);
sortedData = data(originalPositions);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% FILTER DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filteredData = cellfun(@(f) IIR_Filter(f,'Elliptic','samplingFreq',...
                       subExp.fileInfo(1,1).samplingFreq, 'type','high',...
                           'cutOffFreq',300, 'passBandRipple', 3,...
                           'stopBandRipple', 40), sortedData,...
                           'UniformOutput', 0);
% convert from cell array to data matrix with each column holding data for
% a unique angle
filteredDataMatrix = cell2mat(filteredData);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

downSampleFactor = inputParseStruct.Results.downSampleFactor;

% We will plot the filtered data sequentially and vertically. We will
% seperate the individual traces by 1.15 X maxDataRange
dataRange = 1.15*max(max(filteredDataMatrix))-min(min(filteredDataMatrix));

for col=1:size(filteredDataMatrix,2)
downedFilteredDataMatrix(:,col) = downsample((dataRange*col)+...
    filteredDataMatrix(:,col),downSampleFactor); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GET TIME INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
samplesPerTrigg = subExp.fileInfo(1,1).samplesPerTrigg;
sampleRate = subExp.fileInfo(1,1).samplingFreq;
Timing = subExp.stimulus(1,1).Timing;

%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT TIME ARRAY %%%%%%%%%%%%%%%%%%%%%%%%%%
% We will need to plot our data against time not samples so we convert our
% samples into time
time = downsample(1/sampleRate:1/sampleRate:samplesPerTrigg/sampleRate,...
                    downSampleFactor);

% define the stimulus epoch. A two element array containg the start and end
% times of the stimulus
stimEpoch = [Timing(1),Timing(1) + Timing(2)];
stimTimes = downsample(stimEpoch(1):1/sampleRate:stimEpoch(2),...
    downSampleFactor);      
        
plot(time,downedFilteredDataMatrix,'k')
axis tight
hold on;



% get the 'y' limits of the current axis
yLimits = get(gca, 'ylim');

% creat a 'y' vector that will form the upper horizontal boundary of our
% shaded region
ylimVector= yLimits(2)*ones(numel(stimTimes),1);
ha = area(stimTimes, ylimVector, yLimits(1));

set(ha, 'FaceColor', [.85 .85 .85])
set(ha, 'LineStyle', 'none')
xlim([0 time(end)])
set(gca, 'box','off') 
hold off;

%%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(gca, ...
  'Box'         , 'off'     , ...
  'TickDir'     , 'out'     , ...
  'TickLength'  , [.02 .02] , ...
  'XMinorTick'  , 'off'     , ...
  'YMinorTick'  , 'off'     , ...
  'YGrid'       , 'off'     , ...
  'XColor'      , [1 1 1],    ...
  'XTick'       , []        , ...
  'YColor'      , [0 0 0],    ...
  'YTick'       , []        , ...
  'YColor'      , [1 1 1]   , ...
  'LineWidth'   , 1             );



% We now want to reorder the data plot and the area we just made so that
% the signal always appears on top we do this by accessing all lines
% ('children') and flip them
set(gca,'children',flipud(get(gca,'children')))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','oridata',filteredData)
                



end

