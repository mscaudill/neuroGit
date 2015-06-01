function caGriddedGratingPlotter( trialNumToPlot )
%caGriddedGratingPlotter plots single trials of cell attached data in
%response to griddedGrating stimuli. We plot only single trials since in
%this case we are interested in viewing the spikes. We aslo annotate the
%plot with the number of spikes occurring at each position. We assume that
%only one angle was run becasue full-field gratings were first used to map
%the orientation tuning of the cell.
% INPUTS:
%               
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
[loadedExpCell,eExpNames] = multiEexpLoader('raw',{'data','stimulus',...
                                            'behavior','fileInfo',...
                                            'filterOptions',...
                                            'spikeIndices'});
                                    
     % we use the name to document the end figure. We replace underscores
     expName = strrep(eExpNames{1},'_','-');
     
Exp =loadedExpCell{1};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','Exp',Exp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% GET STIMULUS TIMING INFORMATION %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For plotting the signals stored in the map we will need timing
% information and the frame rate at which the data was collected.

% use the first stimulus to get the timing
stimTiming = Exp.stimulus(1,1).Timing;

%use the first file in fileInfo to obtain the sampling rate
samplingFreq = Exp.fileInfo(1,1).samplingFreq;

time = 0:1/samplingFreq:((numel(Exp.data(1,1).Electrode)-1)/samplingFreq);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% CALL EPHYSDATAMAP TO CONSTRUCT MAP OBJ %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dataMap = ePhysDataMap(Exp.data,Exp.stimulus,{'Rows','Columns',...
                                               'Orientation'},...
                                               Exp.behavior,...
                                               Exp.fileInfo,...
                                               Exp.spikeIndices,...
                                               'removeSpikes',false);
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
assignin('base','signals',signals)
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
assignin('base','signalMatrices',signalMatrices)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% FILTER DATA WITH OPTIONS FROM EXPMAKER %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call the IIR filter with the filter options present in the eExp
filteredSignals = cellfun(@(x) IIR_Filter(x, Exp.filterOptions.filter,...
                            samplingFreq,'type','high','cutOffFreq',300,'order',5),...
                            signalMatrices,'UniformOut',0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract the trial of interest
signalOfInterest = cellfun(@(x) x(:,trialNumToPlot),...
                            filteredSignals,'UniformOut',0);
                        
signalOfInterest = cell2mat(signalOfInterest);

% open a new figure
numFigs=length(findall(0,'type','figure'));
figure(numFigs+1)

% We also need the number of rows and columns shown so we can determine
% where each subplot should go
%get the num of rows and columns from the stimulus struct
numRows = max([Exp.stimulus(:,:).Rows]);
numCols = max([Exp.stimulus(:,:).Columns]);

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
yLimits = [min(signalOfInterest(:)),max(signalOfInterest(:))];

% now create the upper horizontal boundary of our area
yVals = (yLimits(1))*ones(1,numel(xVals));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for pos = 1:size(signalOfInterest,2)
            % create a subscripts set using ind2sub (builtin)
            [x,y] = ind2sub([numRows,numCols],pos);
            % transpose the subscripts (since subplot does not obey row
            % major rule) and construct a transposed position
            transPos = sub2ind([numRows,numCols],y,x);
            % call subplot to plot to the transposed position
            subplot(numRows,numCols,transPos)
            % plot the pos signal to the transposed subplot position from
            % above Ensure that all the axis are the same scale
            hl = plot(time,[signalOfInterest(:,pos)]);
            
            % Ensure that all the axis are the same scale
            set(gca,'ylim',[yLimits(1)-.1, yLimits(2)+.1]);

            set(gca,'xlim',[0,max(time)]);
            
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

end

