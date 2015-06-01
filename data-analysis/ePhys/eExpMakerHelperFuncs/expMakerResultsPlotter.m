function expMakerResultsPlotter(time, signal, stimTimes, threshold,...
                                filter,spikeTimes, spikeShapes,...
                                meanSpikeShape, stdevSpikeShape)
% expMakerResultsPlotter constructs the plots for the expMaker gui results
% stage.
% INPUTS                    :time, time over which signal is to be plotted
%                           :signal, an n-element sequence of filtered data
%                           :stimTimes, a three element array of stimulus
%                                       times
%                           :threshold, threshold used for spike detection
%                                       to be used to set ylimits of plot
%                           :spikeTimes, an array of spike times for signal
%                           :spikeShapes, a cell array of datapoints for
%                                         each spike in signal
%                           :meanSpikeShape, mean of the spike shapes
%                           :stdevSpikeShape, standard dev. of spike shapes
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

% We have three plots that will be display in the results panel. subplot 1
% will be the signal vs time with the spikes designated by dots. The second
% subplot will be an overlay of all the spikes. The third subplot will be
% the mean wave form + std of the spike shapes for that trace

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% PLOT SIGNAL VS TIME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create an axis and return a handle to the axis (axis positioning is
% specified by left, up, % width of figure, % height of figure
haxes1 = subplot('position', [.1 .5 .85 .45]);
% Plot to the newly created axis both time and signal
plot(haxes1,time,signal)
% set axis properties
set(haxes1, ...
  'FontName'    , 'Helvetica' , ...
  'Box'         , 'off'       , ...
  'TickDir'     , 'in'        , ...
  'TickLength'  , [.01 .01]   , ...
  'XMinorTick'  , 'off'       , ...
  'YMinorTick'  , 'off'       , ...
  'YGrid'       , 'off'       , ...
  'XColor'      , [0 0 0]     , ...
  'YColor'      , [0 0 0]     , ...
  'LineWidth'   , 1             );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hold(haxes1,'on'); % hold the current plot

%%%%%%%%%%%%%%%%%%%%%%%%%% ADD SPIKES TO PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now add the spike times to the plot using the scatter function.
% We will set the vertical placement of the spike dots to be at the
% negative of the threshold (i.e. on the opposite side (vertically) of the
% spikes
if strcmp(filter,'No Filter')
    scatter(spikeTimes,(threshold)*ones(1,numel(spikeTimes)),...
    'r.');
else   
    scatter(spikeTimes,(-threshold*std(signal))*ones(1,numel(spikeTimes)),...
        'r.');
end

%%%%%%%%%%%%%%%%%%%%%%%% SET AXIS LIMITS FOR AXES1 %%%%%%%%%%%%%%%%%%%%%%%%
% now we will set the limits of the plot to reduce white space in the plots
% if the user detected negative going spikes our limits will go from
% min(signal) to one std deviation above the threshold
if threshold < 0
set(gca, 'ylim', [min(signal), -(threshold-1)*std(signal)])
end
% if the user detected positive going spikes, we set the ylims to be from
% negative of threshold + 1 times the std (signal) to max(signal)
if threshold > 0
set(gca, 'ylim', [-(threshold+1)*std(signal), max(signal)])
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%% ADD SHADED STIMULUS EPOCH TO PLOT %%%%%%%%%%%%%%%%%%%
% To construct the background stimulus epoch shaded region we will get the
% ylims from above and the stimulus time. We will make vectors of this and
% construct an area using the area function.

%%%%%%%%%%% SET HORIZONTAL BOUNDS OF SHADED REGION
% Determine the time steps for our stimulus time array
dt = time(2)-time(1);
% now constuct the array
stimTimesArr = stimTimes(1):dt:stimTimes(1)+stimTimes(2);

%%%%%%%%%%% SET VERTICAL BOUNDS OF SHADED REGION
% get the ylims of haxes1
yLimits = get(haxes1, 'ylim');
% construct an array of ylims the same size as the stimTimesArray
ylimVector= yLimits(2)*ones(numel(stimTimesArr),1);
% create the area and return handle
harea1 = area(stimTimesArr, ylimVector, yLimits(1));

% set axis properties of the area
set(harea1, 'FaceColor', [.85 .85 .85],...
            'LineStyle', 'none');
        
% We now want to reorder the data plot and the area we just made so that
% the signal always appears on top we do this by accessing all lines
% ('children') and flip them
set(gca,'children',flipud(get(gca,'children')));
% release the current plot
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% SPIKE SHAPES PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now going to construct the over-layed spike shapes plot
% construct a second axis and position to lower left of figure
haxes2 = subplot('position', [.1 .1 .4 .35]);
% we must first determine whether any spikes are in the signal
if ~isempty(cellfun(@isempty,spikeShapes))
    Shapes = cell2mat(spikeShapes);
    plot(Shapes)
    % set axis properties (xlims. remove tick labes and set ticks  white
    % since of the tick direction is inward
    set(haxes2,'FontName'     , 'Helvetica'               , ...
                'Box'         , 'off'                     , ...
                'TickDir'     , 'in'                      , ...
                'TickLength'  , [.01 .01]                 , ...
                'xlim'        , [0, numel(spikeShapes{1})], ...
                'yticklabel'  , ''                        , ...
                'ycolor'      , [1 1 1]                      );
else cla(haxes2) % if no spikes are present then we will clear the previous 
                 % plot form the axis
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% MEAN SPIKE SHAPES PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we will now construct the mean + std of the spike shapes by making a plot
% in the lower right of the figure
haxes3 = subplot('position', [.55 .1 .4 .35]);
% we again make sure that we have spikes to display
if ~isempty(spikeShapes)
    % we call the function shadedError bar from the matlab file exchange
    shadedErrorBar(1:size(meanSpikeShape,1),meanSpikeShape,...
                                                stdevSpikeShape,'r');

    % set axis properties (xlims. remove tick labes and set ticks white
    % since of the tick direction is inward
    set(haxes3, 'FontName'     , 'Helvetica'               , ...
                'Box'         , 'off'                     , ...
                'TickDir'     , 'in'                      , ...
                'TickLength'  , [.01 .01]                 , ...
                'xlim'        , [0, numel(spikeShapes{1})], ...
                'yticklabel'  , ''                        , ...
                'ycolor'      , [1 1 1]                      );
else cla(haxes3); % If no spikes were there to plot we will clear the axis
                  % of any previous plots
    
end
        
end

