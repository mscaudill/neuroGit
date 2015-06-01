function spikeRaster( spikeMapObj, varargin )
%UNTITLED Summary of this function goes here
%  spikeRaster plots the spike times for all the trials in the value fields
%  of SpikeMapObj. It plots a unique subplot for each key of spikeMapObj.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
inputParse = inputParser;

% Set the default values for varargin
defaultTickHeight = 0.2;
defaultTickSpacing = 0.5;
defaultTickColor = 'k';
defaultStimTiming = [ 1 2 1];

% Add all requried and optional args to the input parser object
addRequired(inputParse,'spikeMapObj',@isobject);
addParamValue(inputParse,'tickHeight',defaultTickHeight,@isnumeric);
addParamValue(inputParse,'tickSpacing',defaultTickSpacing,@isnumeric);
addParamValue(inputParse,'tickColor',defaultTickColor,@isstr);
addParamValue(inputParse,'stimTiming',defaultStimTiming,@isvector);

%call the parser
parse(inputParse,spikeMapObj,varargin{:})

% obtain parser results
spikeMapObj = inputParse.Results.spikeMapObj;
tickHeight = inputParse.Results.tickHeight;
tickSpacing = inputParse.Results.tickSpacing;
tickColor = inputParse.Results.tickColor;
stimTiming = inputParse.Results.stimTiming;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mapKeys = cell2mat(spikeMapObj.keys);
hSub = tight_subplot(1,numel(mapKeys));
for keyIndex = 1:numel(mapKeys)
    axes(hSub(keyIndex))
    spikeArrays = spikeMapObj(mapKeys(keyIndex));
    for array = 1:numel(spikeArrays)
        plot([spikeArrays{array}; spikeArrays{array}],...
             [(array-1)*...
             (tickSpacing+tickHeight)+zeros(size(spikeArrays{array}));...
             ((array-1)*(tickSpacing)+ array*(tickHeight))*ones(size(spikeArrays{array}))],...
             'Color',tickColor)
         xlim([0,4])
         hold on
    end
    % get the visual start and end times
            visStart = 1;
            visEnd = 3;

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
end

end

