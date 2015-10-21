function scatter_csNormedF1Amplitude(~)
% scatter_csNormedF1Amplitude extracts the normalized F1 amplitude from a
% listing of cells provided via uigetfile and scatters the mean cross
% F1 Ampl against the iso-oriented F1 ampl
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
%%%%%%%%%%%%%%%%%%%%% OBTAIN THE CS_NORMED_AMPLITUDES %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
normed_amps = cellfun(@(x) x.metrics.csNormedF1Amplitudes,...
                                loadedExpsCell, 'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% FORMAT DATA TO PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We have two sets of normed_amplitudes for each cell (potentially) one for
% cntrl trials and one for led trials. If two sets are found then we will
% plot both and otherwise plot only cntrl set

% TO DO: ADD METHODS FOR PLOTTING LED Amplitude IF PRESENT

% Get the number of amplitude sets. will be 1 if only cntrl set and two
% if cntrl and led set
num_amp_sets = sum(cellfun(@isempty,normed_amps{1}));

% Get the cntrl sets of amplitudes
cntrlSets = cellfun(@(x) x{1}, normed_amps, 'UniformOut', 0);

% if they exist get the led sets of amplitudes
if num_amp_sets == 2;
    ledSets = cellfun(@(x) x{2}, normed_amps, 'UniformOut', 0);
end

% obtain the mean cross amplitudes and the iso amplitude
cntrl_meanCrossAmp = cellfun(@(x) (x(2)+x(3))/2, cntrlSets);
cntrl_isoAmp = cellfun(@(x) x(4), cntrlSets);

% calculate the mean and stds of the cntrl charges across all cells
grandMean_cntrl_cross = mean(cntrl_meanCrossAmp);
grandSEM_cntrl_cross = std(cntrl_meanCrossAmp)/...
                            sqrt(numel(cntrl_meanCrossAmp));
grandMean_cntrl_iso = mean(cntrl_isoAmp);
grandSEM_cntrl_iso = std(cntrl_isoAmp)/...
                            sqrt(numel(cntrl_isoAmp));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hold on
% scatter the cntrl_cross charges and iso charges
scatter(cntrl_meanCrossAmp,cntrl_isoAmp,50, 'k')

% add the grand (across cells) cross and iso amp with SEM bars using
% errorbarxy from exchange
scatter(grandMean_cntrl_cross, grandMean_cntrl_iso, 150, 'r','^','fill')
errorbarxy(grandMean_cntrl_cross, grandMean_cntrl_iso, ...
           grandSEM_cntrl_cross, grandSEM_cntrl_iso,[],[],'r^','r')
       
% add a unity reference line
hLine = refline(1,0);

% Add Labels
xlabel('Normalized Cross F1 Amplitude')
ylabel('Normalized Iso F1 Amplitude')
title(['Iso-Oriented F1 Amplitude to Cross-Oriented F1 Amplitude',char(10),...
        'n = ',num2str(numel(loadedExpsCell))])
hold off
    
% TO DO: ADD METHODS FOR PLOTTING LED CHARGES IF PRESENT

       
end

