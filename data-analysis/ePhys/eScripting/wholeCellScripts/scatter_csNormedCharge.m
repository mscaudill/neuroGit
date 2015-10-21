function scatter_csNormedCharge(~)
% scatter_csNormedCharge extracts the normalized inhibitory charge from a
% listing of cells provided via uigetfile and scatters the mean cross
% charge against the iso-oriented charge
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
%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN THE CS_NORMED_CHARGES %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
normed_charges = cellfun(@(x) x.metrics.csNormedCharges,...
                                loadedExpsCell, 'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% FORMAT DATA TO PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We have two sets of normed_charges for each cell (potentially) one for
% cntrl trials and one for led trials. If two sets are found then we will
% plot both and otherwise plot only cntrl set

% TO DO: ADD METHODS FOR PLOTTING LED CHARGES IF PRESENT

% Get the number of charge_sets. will be 1 if only cntrl set and two
% if cntrl and led set
num_charge_sets = sum(cellfun(@isempty,normed_charges{1}));

% Get the cntrl sets of charges
cntrlSets = cellfun(@(x) x{1}, normed_charges, 'UniformOut', 0);

% if they exist get the led sets of charges
if num_charge_sets == 2;
    ledSets = cellfun(@(x) x{2}, normed_charges, 'UniformOut', 0);
end

% obtain the mean cross charge and the iso charge
cntrl_meanCrossCharge = cellfun(@(x) (x(2)+x(3))/2, cntrlSets);
cntrl_isoCharge = cellfun(@(x) x(4), cntrlSets);

% calculate the mean and stds of the cntrl charges across all cells
grandMean_cntrl_cross = mean(cntrl_meanCrossCharge);
grandSEM_cntrl_cross = std(cntrl_meanCrossCharge)/...
                            sqrt(numel(cntrl_meanCrossCharge));
grandMean_cntrl_iso = mean(cntrl_isoCharge);
grandSEM_cntrl_iso = std(cntrl_isoCharge)/...
                            sqrt(numel(cntrl_isoCharge));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hold on
% scatter the cntrl_cross charges and iso charges
scatter(cntrl_meanCrossCharge,cntrl_isoCharge,50, 'k')

% add the grand (across cells) cross and iso charge with SEM bars using
% errorbarxy from exchange
scatter(grandMean_cntrl_cross, grandMean_cntrl_iso, 150, 'r','^','fill')
errorbarxy(grandMean_cntrl_cross, grandMean_cntrl_iso, ...
           grandSEM_cntrl_cross, grandSEM_cntrl_iso,[],[],'r^','r')
       
% add a unity reference line
hLine = refline(1,0);

% Add Labels
xlabel('Normalized Cross Charge')
ylabel('Normalized Iso Charge')
title(['Iso-Oriented Charge to Cross-Oriented Charge',char(10),...
        'n = ',num2str(numel(loadedExpsCell))])
hold off
    
% TO DO: ADD METHODS FOR PLOTTING LED CHARGES IF PRESENT
end

