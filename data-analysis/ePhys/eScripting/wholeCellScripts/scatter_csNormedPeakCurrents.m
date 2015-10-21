function scatter_csNormedPeakCurrents(~)
% scatter_csNormed peak currents extracts the peak inhibitory currents from
% a uigetfile listing of analyzed exps and scatter plots the mean cross
% current against the iso-oriented peak current
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
% Load pertinent substructures from a raw experiment and extract from cell
% array.
[loadedExpsCell, ExpNames] = multiEexpLoader('wholeCell', {'metrics'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% OBTAIN THE CS_NORMED_PEAK_CURRENTS %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
normed_peak_currents = cellfun(@(x) x.metrics.csNormedPeakCurrents,...
                                loadedExpsCell, 'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% FORMAT DATA TO PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We have two sets of peak_currents for each cell (potentially) one for
% cntrl trials and one for led trials. If two sets are found then we will
% plot both and otherwise plot only cntrl set

% TO DO: ADD METHODS FOR PLOTTING LED CURRENTS IF PRESENT

% Get the number of peak_current_sets. will be 1 if only cntrl set and two
% if cntrl and led set
num_currents_sets = sum(cellfun(@isempty,normed_peak_currents{1}));

% Get the cntrl sets of peak currents
cntrlSets = cellfun(@(x) x{1}, normed_peak_currents, 'UniformOut', 0);

% if they exist get the led sets of peak currents
if num_currents_sets == 2;
    ledSets = cellfun(@(x) x{2}, normed_peak_currents, 'UniformOut', 0);
end

% Obtain the mean cross current and the isoCurrent for the cntrl sets for
% each cell
cntrl_meanCrossCurrents = cellfun(@(x) (x(2)+x(3))/2, cntrlSets);
cntrl_isoCurrents = cellfun(@(x) x(4), cntrlSets);

% calculate the mean and stds of the cntrl currents across all cells
grandMean_cntrl_cross = mean(cntrl_meanCrossCurrents);
grandSEM_cntrl_cross = std(cntrl_meanCrossCurrents)/...
                            sqrt(numel(cntrl_meanCrossCurrents));
grandMean_cntrl_iso = mean(cntrl_isoCurrents);
grandSEM_cntrl_iso = std(cntrl_isoCurrents)/...
                            sqrt(numel(cntrl_isoCurrents));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hold on
% scatter the cntrl_cross currents and iso currents
scatter(cntrl_meanCrossCurrents,cntrl_isoCurrents,50, 'k')

% add the grand (across cells) cross and iso currents with SEM bars using
% errorbarxy from exchange
scatter(grandMean_cntrl_cross, grandMean_cntrl_iso, 150, 'r','^','fill')
errorbarxy(grandMean_cntrl_cross, grandMean_cntrl_iso, ...
           grandSEM_cntrl_cross, grandSEM_cntrl_iso,[],[],'r^','r')
       
% add a unity reference line
hLine = refline(1,0);

% Add Labels
xlabel('Normalized Peak Cross Current')
ylabel('Normalized Peak Iso Current')
title(['Peak Iso-Oriented Current to Peak Cross-Oriented Charge',char(10),...
        'n = ',num2str(numel(loadedExpsCell))])
hold off
    
% TO DO: ADD METHODS FOR PLOTTING LED CURRENTS IF PRESENT





