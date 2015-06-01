function shadedPlot( time, signal, stimTimes, varargin )
%SHADEDPLOT returns a plot of signal with a shaded region representing when
%the stimulus was present.
% INPUTS:       signal:     an n element sequence
%               time:       time over which signal is acquired
%               stimTimes:  a three element array consisting of wait,
%                           duration and delay of a stimulus
%               varargin:   includes 'FaceColor' and RGB triple and
%                           'LineStyle' of the bounded area
% OUTPUTS:      Shaded Plot

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% define the stimulus epoch. A two element array containg the start and end
% times of the stimulus
stimEpoch = [stimTimes(1), stimTimes(1)+stimTimes(2)];


plot(time',signal)
dt = time(2)-time(1);
stimTimesVec = stimTimes(1):dt:stimTimes(1)+stimTimes(2);

hold on;
% get the 'y' limits of the current axis
yLimits = get(gca, 'ylim');

% creat a 'y' vector that will form the upper horizontal boundary of our
% shaded region
ylimVector= yLimits(2)*ones(numel(stimTimesVec),1);
ha = area(stimTimesVec, ylimVector, yLimits(1));

set(ha, 'FaceColor', [.85 .85 .85])
set(ha, 'LineStyle', 'none')
xlim([0 time(end)])
set(gca, 'box','off') 
hold off;
% We now want to reorder the data plot and the area we just made so that
% the signal always appears on top we do this by accessing all lines
% ('children') and flip them
set(gca,'children',flipud(get(gca,'children')))
end

