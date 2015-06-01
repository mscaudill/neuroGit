function griddedGratingPlotter(varargin)
%griddedGratingPlotter plots data from a griddedGrating dataMap. Since two
%variables are present in the map (i.e. position and orientation) we fix
%one of the variables and plot with respect to the other.
% INPUTS:  
%            varagin: dataOffset, a mv/pa offset that can be applied to all
%                     data in case it is needed, defaults to 0 mV/pA
%                     fixedStimVariable, either position or orientation can
%                     be fixed. Or user can select all to plot both ori and
%                     positions together
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL EXP LOADER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[loadedExpCell,eExpNames] = multiEexpLoader('wholeCell',{'data','stimulus',...
                                            'behavior','fileInfo',...
                                            'spikeIndices'});
                                    
     % we use the name to document the end figure. We replace underscores
     expName = strrep(eExpNames{1},'_','-');
     
Exp =loadedExpCell{1};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% BUILD AN INPUT PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The input parser will allow the user to enter varaible arguments into the
% function and set defaults if not specified

% construct a parser object (builtin matlab class)
p = inputParser;

% define expected fixedStimVariables
expectedStimVariables = {'position','orientation',...
                         'Position','Orientation','all','All'};
                     
% define the defaultFixedVariable
defaultFixedVariable = 'All';

% add parameter fixedStimVariable & validate it is an expected stimVariable
addParamValue(p, 'fixedStimVariable',defaultFixedVariable,...
    @(x) any(validatestring(x,expectedStimVariables)));

% set default value of dataOffset to be 0 mV/pA
defaultDataOffset = 0;

% add the optional parameter dataOffset
addParamValue(p,'dataOffset',defaultDataOffset,@isnumeric)

% call the input parser method parse
parse(p, varargin{:})
     
% retrieve the variable arguments from the parser inputs
dataOffset = p.Results.dataOffset;
fixedStimVariable = p.Results.fixedStimVariable;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% GET STIMULUS TIMING INFORMATION %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For plotting the signals stored in the map we will need timing
% information and the frame rate at which the data was collected.

% use the first stimulus to get the timing
stimTiming = Exp.stimulus(1,1).Timing;

%use the first file in fileInfo to obtain the sampling rate
samplingFreq = Exp.fileInfo(1,1).samplingFreq;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% CALL EPHYSDATAMAP TO CONSTRUCT MAP OBJ %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dataMap = ePhysDataMap(Exp.data,Exp.stimulus,{'Rows','Columns',...
                                               'Orientation'},...
                                               Exp.behavior,...
                                               Exp.fileInfo,...
                                               Exp.spikeIndices);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% EXTRACT SIGNALS FROM THE MAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We obtain the keys and signals present in the dataMap. Note we are using
% the methods of the MapN class written by D Young on the file exchange.
keySet = keys(dataMap);
assignin('base','keys',keySet)
% Signals will be a cell of cells where each inner cell contains a set of
% arrays for that key
signals = values(dataMap);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% RESHAPE THE SIGNALS INTO A MATRIX FOR PLOTTING %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Signals contains a cell array of cells where each inner cell contains
% arrays corresponding to each trial for that condition. For example if you
% ran 9 positions and 8 angles and 18 trials then signals{1} is cell array
% containing 18 arrays. The {1} signifies condition 1. This condition would
% be the first position and the first angle. signals{2} is the first
% position and the second angle. Thus positions change slowest (i.e. they
% are the outer key in the dataMap. We will convert the arrays for each
% condition (i.e. a particular position/orientation pair) and make them
% into matrices where data points are along rows and trials are along
% columns. We do this using a nested cell function
signalMatrices = cellfun(@(trial) cat(2,trial{1:end}),...
                        cellfun(@(cond) cond, signals,...
                        'UniformOut',0), 'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% COMPUTE THE MEAN SIGNAL FOR EACH COND %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We use cell fun over the conditions to compute the mean across columns
meanSignals = cellfun(@(cond) mean(cond,2), signalMatrices,...
                        'UniformOut',0)';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For plotting, we need to know the number of positions and angles shown to
% know how many subplots we will have.
%get the number of positions
numPos = numel(unique((cellfun(@(x) x{1}, keySet))));
% get the number of angles
numAngles = numel(unique(cellfun(@(x) x{2},keySet)));

% We also need a time vector to plot our mV/pA against
time = (1:numel(meanSignals{1}))/samplingFreq;

% Mean signals is a 1 x numConds cell array containing the means signal for
% that condition across trials (ex. condiont 3 is position 1, orientation
% 90 if eight angles and 9 positions were run). We now convert meanSignals
% into a numAngles x numPositions cell array using reshape.
meanSignals = reshape(meanSignals,numAngles,numPos);
assignin('base','meanSignals',meanSignals)
% We also need the number of rows and columns shown so we can determine
% where each subplot should go
%get the num of rows and columns from the stimulus struct
numRows = max([Exp.stimulus(:,:).Rows]);
numCols = max([Exp.stimulus(:,:).Columns]);

% obtain the min and max vales of the mean signals across all positions and
% all angles using cellfun and then double max since it returns a matrix
maxMeanSignal = max(max( cellfun(@max, meanSignals)));
minMeanSignal = min(min( cellfun(@min, meanSignals)));


%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT STIMULUS EPOCHS %%%%%%%%%%%%%%%%%%%%%%%%%%
% To construct the stimulus epochs we will need to make two horizontal and
% two vertical boundaries to create our shaded box.

%Get the start time of the epoch
epochStart = stimTiming(1);

% epoch ends are just epoch starts plus duration
epochEnd = epochStart + stimTiming(2);

% package the starts and ends into a matrix column1 are starts, col2 is
% ends
stimEpoch = [epochStart, epochEnd]; 

% now take the 2-el array and make a vector  
xVals = linspace(epochStart,epochEnd,100);

% get the ylims . This will be the upper horizontal
% boundary
yLimits = [minMeanSignal,maxMeanSignal];

% now create the upper horizontal boundary of our area
yVals = (yLimits(1))*ones(1,numel(xVals));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% open a new figure
numFigs=length(findall(0,'type','figure'));
figure(numFigs+1)

if any(strcmp(fixedStimVariable,{'all','All'}))
        % If the user defaults to all positions and orientations, then we
        % loop through the positions (cols of meanSignals) and for each
        % position construct a set of subscripts [x,y] and call subplot
        
        set(gcf,'position', [435,250,1211,640]);
        % create a supertitle for the subplots
        annotation('textbox', [0 0.9 1 0.1], ...
                   'String', [expName, ' n = ',...
                   num2str(size(signalMatrices{1},2)),' trials'], ...
                    'EdgeColor', 'none', ...
                    'HorizontalAlignment', 'center')
        % Loop over the positions
        for pos = 1:size(meanSignals,2)
            % create a subscripts set using ind2sub (builtin)
            [x,y] = ind2sub([numRows,numCols],pos);
            % transpose the subscripts (since subplot does not obey row
            % major rule) and construct a transposed position
            transPos = sub2ind([numRows,numCols],y,x);
            % call subplot to plot to the transposed position
            subplot(numRows,numCols,transPos)
            % plot the pos signal to the transposed subplot position from
            % above Ensure that all the axis are the same scale
            hl = plot(time,[meanSignals{:,pos}]);
            % we will set the last color to be orange since 8 angles
            % repeats a color
            set(hl(end),'Color',[1,102/255,0]);
            
            % Ensure that all the axis are the same scale
            set(gca,'ylim',[minMeanSignal-.1, maxMeanSignal+.1]);
            set(gca,'xlim',[0,max(time)]);
            
            % create a legend for the subplot over angles
            % first get all the angles from the keySet ( they are the
            % second elements
            angles = unique(cellfun(@(x) x{2}, keySet));
            % convert the angles array to a cell of strings
            angleStrs = cellfun(@(x) num2str(x), num2cell(angles),...
                                'UniformOut',0);
            
            hold on
            % call the area function to make our shaded plot
            ha = area(xVals, yVals, yLimits(2));
    
            % set the area properties
            set(ha, 'FaceColor', [.85 .85 .85])
            set(ha, 'LineStyle', 'none')
    
            hold off;
            
            % set the box of the axis off
            set(gca, 'box','off')

            % set the order of the plots to reverse
            set(gca,'children',flipud(get(gca,'children')))
            
        end
        
        % create legend for this subplot
        legHandle = legend(hl,angleStrs);
            
        newPosition = [.92 0.5 0.05 0.05];
        newUnits = 'normalized';
        set(legHandle,'Position', newPosition,'Units', newUnits);
        
            
end

