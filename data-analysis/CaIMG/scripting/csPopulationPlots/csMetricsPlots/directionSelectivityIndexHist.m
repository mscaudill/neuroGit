function directionSelectivityIndexHist(cellTypeofInterest)
% directionSelectivityIndexHist calculates the direction selectivity for
% cells matching cellTypeof Interest and histograms these values
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
%
% INPUTS:          cellTypeofInterest: the cell type the user
%                                      wishes to plot ('pv', 'pyr', 'gad2')
%
% OUTPUTS:         NONE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL MULTIIMEXPLOADER %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We need the cell types from each imExp_analyzed and the signalMetrics
% structure which contains the surround for each cell. We also
% need the signal classification becasue we are only interest in cells with
% a center response
loadedImExps = multiImExpLoader('analyzed',{'cellTypes',...
                                'signalClassification', 'signalMetrics'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% EXTRACT CLASSIFICATION, GAINS, AND CELLTYPES %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for file=1:numel(loadedImExps)
    % obtain the cellTypes
    cellTypes{file} = loadedImExps{file}.cellTypes;
    
    % obtain the classification
    classification{file} = ...
        loadedImExps{file}.signalClassification.classification;
    
    % obtain the mean areas
    gains{file} = loadedImExps{file}.signalMetrics.surroundGains;
    
    %now call the pattern classifier resturning the cellTypes and
    %responsePatterns for each imExp
    [expCellTypes{file},responsePatterns{file}]=scsPatternClassifier(...
                                                 cellTypes{file},...
                                                 classification{file});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%  PERFORM CONCATENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to concatenate all the cell types responsePatterns and
% gains across all the roiSets

allCellTypes = [expCellTypes{:}];

allResponsePatterns = [responsePatterns{:}];

combFileGains = [gains{:}];

allGains = [combFileGains{:}];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% FILTER BY CELL TYPE & RESPONSE TYPE %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the function csCellArrayFilter and return the filtered results (note
% we pass along the cellTypeofInterest and keep only responsePattern 4
filteredGains = csCellArrayFilter(allGains,allCellTypes,...
                                    cellTypeofInterest,...
                                    allResponsePatterns,[4]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% CALCULATE THE DSI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The direction selectivity index will be calculated as:
% (crossGainPref-crossGainNonPref)/crossPref. This is
% equivalent to (crossAreaPref-crossAreaNonPref)/crossAreaPref
% since the gain is the area divided by the centerArea.

dsi = cellfun(@(t) (max(t(2:3))-min(t(2:3)))/(max(t(2:3))), filteredGains);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% PLOT WITH A SCALED PDF %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1)

[hts,ctrs] = hist(dsi);
bar(ctrs,hts,'hist')

centersDiff = (ctrs(2)-ctrs(1));

dsiAreas = sum(hts(:)) * centersDiff;

xx = linspace(ctrs(1)-centersDiff,ctrs(end)+centersDiff);

hold on;
plot(xx,dsiAreas*normpdf(xx,mean(dsi),std(dsi)),'r-')
hold off;

title(['Direction Selectivity Index n = ', num2str(numel(dsi)), ...
    ' mean = ', num2str(mean(dsi))]);
end

