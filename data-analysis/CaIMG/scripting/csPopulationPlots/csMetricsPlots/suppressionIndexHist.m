function suppressionIndexHist(cellTypesofInterest)
% suppressionIndexHist histograms the suppresssion indices for all cells
% matching cellTypeof Interest.
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
% INPUTS:          cellTypesofInterest: a cell array of cell types
%                                      wishes to plot {'pyr', 'som'}
%
% OUTPUTS:         NONE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% MAIN LOOP OVER CELLTYPES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for cellTypeIndex = 1:numel(cellTypesofInterest)
    cellTypeofInterest = cellTypesofInterest{cellTypeIndex};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL MULTIIMEXPLOADER %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We need the cell types from each imExp_analyzed and the signalMetrics
% structure which contains the suppression index for each cell. We also
% need the signal classification becasue we are only interest in cells with
% a center response
loadedImExps = multiImExpLoader('analyzed',{'cellTypes',...
                                'signalClassification', 'signalMetrics'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% EXTRACT CLASSIFICATION, SI, AND CELLTYPES %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for file=1:numel(loadedImExps)
    % obtain the cellTypes
    cellTypes{file} = loadedImExps{file}.cellTypes;
    
    % obtain the classification
    classification{file} = ...
        loadedImExps{file}.signalClassification.classification;
    
    % obtain the mean areas
    suppIndex{file} = loadedImExps{file}.signalMetrics.suppressionIndex;
    
    %now call the pattern classifier resturning the cellTypes and
    %responsePatterns for each imExp
    [expCellTypes{file},responsePatterns{file}]=scsPatternClassifier(...
                                                    cellTypeofInterest,...
                                                    cellTypes{file},...
                                                    classification{file});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end % end file load of this cellType;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%  PERFORM CONCATENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to concatenate all the cell types responsePatterns and
% suppIndex across all the roiSets

allCellTypes = [expCellTypes{:}];

allResponsePatterns = [responsePatterns{:}];

combFileSuppIndices = [suppIndex{:}];

allSuppIndices = [combFileSuppIndices{:}];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% FILTER BY CELL TYPE & RESPONSE TYPE %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the function csCellArrayFilter and return the filtered results (note
% we pass along the cellTypeofInterest and keep only responsePattern 4
% call the function csCellArrayFilter and return the filtered results (note
% we pass along the cellTypeofInterest and keep only responsePatterns
% consistent with the cellTypeofInterest
switch cellTypeofInterest
    case 'pyr'
        respPattern = 4;
    case 'som'
        respPattern = 5;
end
filteredSIs{cellTypeIndex} = cell2mat(csCellArrayFilter(allSuppIndices,...
                                    allCellTypes,...
                                    cellTypeofInterest,...
                                    allResponsePatterns,respPattern));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','filteredSIs',filteredSIs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN MEANS AND STDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
meanSIs(cellTypeIndex) = mean(filteredSIs{cellTypeIndex})
stdSIs(cellTypeIndex) = std(filteredSIs{cellTypeIndex});
end
%%%%%%%%%%%%%%%%%%%%%% END FOR LOOP OVER CELLTYPES %%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% CONVERT THE FILTERED SIS TO MATRIX FORM %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Since the number of cells for each cellType might be different we need to
% find the cellType with the most and then pad the shorter one with NaNs to
% make a rectangular matrix

% get the max number of cells across all cellTypes
maxLength = max(cellfun(@(r) numel(r), filteredSIs));

% pad the shorter ones in the cell array with an NaN. We pad the difference
% in lengths and store the results for each cellType to a column in
% filtered gains matrix
for cellIndex = 1:numel(filteredSIs)
    filteredSIsMat(:,cellIndex) = padarray(filteredSIs{cellIndex},...
        [0,maxLength-numel(filteredSIs{cellIndex})],NaN,'post')';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open a figure and create a histogram plot
% ask for number of open figures (returns [] if none)
fh=findobj(0,'type','figure');
% Create a figure
if isempty(fh)
    figure(1)
else figure(fh+1)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% Create the histogram %%%%%%%%%%%%%%%%%%%%%%%%%%
[hts,ctrs] = hist(filteredSIsMat);
bar(ctrs,hts,'hist')

%%%%%%%%%%%%%%%%%%%%%%%%%% Create the PDFs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the number of cellTypes
numCellTypes = numel(cellTypesofInterest);

% obtain the histogramed areas for each cellType
if numCellTypes == 1
    cellTypeArea(1) = sum(hts(1,:)*(ctrs(2)-ctrs(1)));
else
    for type = 1:numCellTypes
        cellTypeArea(type) = sum(hts(:,type)*(ctrs(2)-ctrs(1)));
    end
end

% obtain the ordinates to calculate PDF over (min(filtered gains to max
% filtered gains) minus/plus one for a little room
xx = linspace(min(min(filteredSIsMat))-1,max(max(filteredSIsMat))+1);

% create a color space (we currently support only two pop colors
colors = {'b','r'};

% Hold the histogram plot and plot PDFs
for type = 1:numCellTypes
    hold on
    plot(xx,cellTypeArea(type)*normpdf(xx,meanSIs(type),...
         stdSIs(type)),colors{type});
end

%remove hold
hold off

% reverse plots so PDFs are on top
chH = get(gca,'Children');
set(gca,'Children',[chH(end);chH(1:end-1)])

% Set axis labels and title
xlabel('Surround Suppression Index')
ylabel('# Cells')

% Depending on the number of cellTypes the title changes
if numel(cellTypesofInterest) == 2;
title(['Surround Suppression Index (', cellTypesofInterest{1}, ') n = ',...
        num2str(numel(filteredSIs{1})),...
        ' (',cellTypesofInterest{2},') n= ',...
        num2str(numel(filteredSIs{2}))]);
elseif numel(cellTypesofInterest) == 1;
    title(['Surround Suppression Index (', cellTypesofInterest{1}, ') n = ',...
        num2str(numel(filteredSIs{1}))]);

end