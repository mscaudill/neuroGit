function oneDimFiringRatePlot(eExp, varargin)
% oneDimFiringRatePlot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2013  Matthew Caudill
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
if isempty(eExp)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%% LOAD DIR INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We load the electroExpDirInformation structure
    electroExpDirInformation;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD EEXP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We will no open a dialog box to obtain the eExp name and location
    % using uigetfile (built-in)
    
    % call uigetfile to obtain the eExpName and its filePath
    [eExpName, PathName] = uigetfile(eDirInfo.electroExpRawFileLoc,...
        'MultiSelect','off');
    
    % We will now load an electroExp. display a wait message during the loading
    loadMsg = msgbox('LOADING SELECTED EXP: Please Wait...');
    
    % now load the eExp using full-file to construct path\fileName.
    eExp = load(fullfile(PathName,eExpName),'spikeIndices', 'stimulus',...
        'behavior','fileInfo');
    
    close(loadMsg)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% BUILD AN INPUT PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The input parser will allow us to designate default values for the input
% arguments in a keyword,value manner. It provides flexibility to the user
% in customizing this function to suit their purposes

% construct a parser object (builtin matlab class)
p = inputParser;

addRequired(p,'eExp');

%%%%%%%%%%%%%%%%%%%%%%%% AUTO LOCATE STIMVARIABLE %%%%%%%%%%%%%%%%%%%%%%%%% 
% attempt to identify the stimVariable for the eExp. We have left the
% stimVariable as an optional input so we need to see if we can auto
% determine the stimulus parameter that was varied
% Start by getting the stimulus fieldnames
stimFields = fieldnames(eExp.stimulus);

% use cellfun to count the number of unique stimulus values for each
% fieldname
numStimValues = cellfun(@(r) numel(unique([eExp.stimulus(:,:).(r)])),...
                        stimFields);
                    
% Locate where numStimValues > 1 and extract these names from fieldnames
possibleVariables = stimFields(numStimValues > 1);

% remove culprits that are not stimVariables (stimulus_type, and timing)
vars = setdiff(possibleVariables,{'Stimulus_Type','Timing'});

if length(vars) == 1
    posStimVariable = vars{1};
else
    errordlg('Could not determine th stimulus variable: Please Provide')
end
% add stimVariable to parse object p
defaultStimVariable = posStimVariable;
addParamValue(p, 'stimVariable', defaultStimVariable,@isstring)

%%%%%%%%%%%%%%%%%%%% ADD RUNSTATE TO PARSE OBJ %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set the default runState of interest to 2 (meaning we don't consider
% running)
defaultRunState = 2;
%add the runningState to the params
addParamValue(p, 'runState', defaultRunState,@isnumeric)

%%%%%%%%%%%%%%%%%%%%%%%%%%% ADD LED TO PARSE OBJ %%%%%%%%%%%%%%%%%%%%%%%%%%
% now add the LED condition that we want in the map, defaults to no LED
defaultLedCond = false;
addParamValue(p, 'ledCond', defaultLedCond, @islogical)

%%%%%%%%%%%%%%%%%%%%%%%%%%%% ADD BINWIDTH TO PARSE OBJ %%%%%%%%%%%%%%%%%%%%
% We will set the binWidth to 1/20th of the time (in secs) of the a single
% trial (for a stimulus recorded for 3.9 secs the bin width will be .195 s.
defaultBinWidth = eExp.fileInfo(1,1).samplesPerTrigg/...
                  (20*eExp.fileInfo(1,1).samplingFreq);
addParamValue(p, 'binWidth', defaultBinWidth, @isscalar)

% call the input parser method parse
parse(p,eExp, varargin{:})

% finally retrieve the variable arguments from the parsed inputs
stimVariable = p.Results.stimVariable;
runState = p.Results.runState;
ledCond = p.Results.ledCond;
binWidth = p.Results.binWidth;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CALL ONEDIM SPIKE TIMES MAP %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call oneDimSpikeTimesMap to create a spike map
spikeMap = oneDimSpikeTimesMap(eExp.spikeIndices, eExp.stimulus,...
                               stimVariable, eExp.behavior,...
                               eExp.fileInfo, 'runState',runState,...
                               'ledCond',ledCond);
                           assignin('base','spikeMap',spikeMap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% COUNT SPIKES IN EACH BIN & CONVERT TO RATE %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the total time the data was collected over using the fileInfo
% structure
trialTime = eExp.fileInfo(1,1).samplesPerTrigg/...
                        eExp.fileInfo(1,1).samplingFreq;
% Construct a vector of bins to calculate the firing rate during
binVector = (0:binWidth:trialTime);

% Use histc to count the number of spikes in each bin and convert to a
% matrix for each angle in the map values using a nested cellfun
spikeCounts = cellfun(@(x)...
         cell2mat(cellfun(@(y) histc(y,binVector), x, 'UniformOut',0)'),...
         spikeMap.values, 'UniformOut',0);
assignin('base','spikeCounts',spikeCounts)
% Calculate the max number of spikes in the mean for each angle and divide
% by the binWidth to get a rate
maxVal = max(cellfun(@(r) max(mean(r,1)), spikeCounts))/binWidth;

% Calculate the mean rates from spike counts
meanSpikeRates = cellfun(@(a) mean(a,1)/binWidth, spikeCounts,...
                            'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                        
                       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Open a figure and create a plot
% ask for number of open figures (returns [] if none)
fh=findobj(0,'type','figure');
% Create a figure
if isempty(fh)
    hfig = figure(1);
else hfig = figure(fh+1);
end


set(hfig,'Position',[201 641 1438 193]);

for stimVal = 1:numel(meanSpikeRates)
    subplot(1,numel(meanSpikeRates),stimVal)
    plot(binVector,meanSpikeRates{stimVal},'k','lineWidth',2);
    ylim([0,maxVal+1])
    xlim([0, trialTime-binWidth])
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%% PLOT THE STIM EPOCHS %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %if size(time,2) > 1
            
            % get the visual start and end times
            visStart = eExp.stimulus(1,1).Timing(1);
            visEnd = eExp.stimulus(1,1).Timing(1)+eExp.stimulus(1,1).Timing(2);

            hold on
            % create a horizontal vector for the stimulation times
            stimTimesVec = visStart:0.1:visEnd;
            % get the 'y' limits of the current axis
            yLimits = get(gca, 'ylim');
            
            % creat a 'y' vector that will form the upper horizontal
            % boundary of our shaded region
            ylimVector= yLimits(2)*ones(numel(stimTimesVec),1);
            ha = area(stimTimesVec, ylimVector, yLimits(1));
            
            % set the area properties
            set(ha, 'FaceColor', [.85 .85 .85])
            set(ha, 'LineStyle', 'none')
            
            set(gca, 'box','off')
            hold off;
            % We now want to reorder the data plot and the area we just
            % made so that the signal always appears on top we do this by
            % accessing all lines ('children') and flip them
            set(gca,'children',flipud(get(gca,'children'))) 
        %end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
end

