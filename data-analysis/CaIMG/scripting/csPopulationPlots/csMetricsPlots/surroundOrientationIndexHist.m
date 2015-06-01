function surroundOrientationIndexHist(cellTypesofInterest)
% surroundOrientationIndexHist determines the soi of all cells matching
% cellTypeofInterest and makes a histogram of soi values.
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
loadedImExps = multiImExpLoader('analyzed',{'cellTypes',...
                                'signalClassification',...
                                'signalMetrics'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% EXTRACT CLASSIFICATION, AREAS, & RESPONSE TYPES %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for file=1:numel(loadedImExps)
    % obtain the cellTypes
    cellTypes{file} = loadedImExps{file}.cellTypes;
    
    % obtain the classification
    classification{file} = ...
        loadedImExps{file}.signalClassification.classification;
    
    % obtain the sois of all cells
    sois{file} = loadedImExps{file}.signalMetrics.surroundOriIndex;
    
    
    %now call the pattern classifier resturning the cellTypes and
    %responsePatterns for each imExp
    [expCellTypes{file},responsePatterns{file}]=scsPatternClassifier(...
                                                 cellTypeofInterest,...
                                                 cellTypes{file},...
                                                 classification{file});
end % end file load of this cellType;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%  PERFORM CONCATENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to concatenate all the cell types responsePatterns and
% gains across all the roiSets

allCellTypes = [expCellTypes{:}];

allResponsePatterns = [responsePatterns{:}];

% combine sois across exps
combFileSois = [sois{:}];
% combine sois across roiSets
allSois = [combFileSois{:}];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% FILTER BY CELL TYPE & RESPONSE TYPE %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% call the function csCellArrayFilter and return the filtered results (note
% we pass along the cellTypeofInterest and keep only responsePatterns
% consistent with the cellTypeofInterest
switch cellTypeofInterest
    case 'pyr'
        respPattern = [3,4];
    case 'som'
        respPattern = [4,5];
end
filteredSois{cellTypeIndex} = cell2mat(csCellArrayFilter(allSois,...
                                    allCellTypes,...
                                    cellTypeofInterest,...
                                    allResponsePatterns,respPattern));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% REMOVE ABBERRANT SOI CELLS %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the abs(soi)>1 this means that either <c1,c2> or I are negative and we
% will ignore these cells (use logical indexing) ( we actually allow a
% little negative (i.e. 1.2 instead of one. This removes 4 cells)
filteredSois{cellTypeIndex}(abs(filteredSois{cellTypeIndex})>1.2)=[];

%assignin('base','filteredSois',filteredSois)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% OBTAIN THE MEAN AND STD %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
meanSois(cellTypeIndex) = mean(filteredSois{cellTypeIndex})
stdSois(cellTypeIndex) = std(filteredSois{cellTypeIndex})
end
%%%%%%%%%%%%%%%%%%%%%% END FOR LOOP OVER CELLTYPES %%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% CONVERT THE FILTERED SIS TO MATRIX FORM %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Since the number of cells for each cellType might be different we need to
% find the cellType with the most and then pad the shorter one with NaNs to
% make a rectangular matrix

% get the max number of cells across all cellTypes
maxLength = max(cellfun(@(r) numel(r), filteredSois));

% pad the shorter ones in the cell array with an NaN. We pad the difference
% in lengths and store the results for each cellType to a column in
% filtered gains matrix
for cellIndex = 1:numel(filteredSois)
    filteredSoisMat(:,cellIndex) = padarray(filteredSois{cellIndex},...
        [0,maxLength-numel(filteredSois{cellIndex})],NaN,'post')';
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
[hts,ctrs] = hist(filteredSoisMat);

bar(ctrs,hts,'hist')

% Get the number of cellTypes
numCellTypes = numel(cellTypesofInterest);

% create a color space (we currently support only two pop colors
colors = {'b','r'};

if numCellTypes>1
    h = findobj(gca,'Type','patch');
    % This gets the patch objects in reverse order (i.e. last one drawn) so we
    % reverse colors here
    flippedColors = fliplr(colors);
    for type = 1:numCellTypes
        set(h(type),'FaceColor',flippedColors{type},'EdgeColor','k')
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%% Create the PDFs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% obtain the histogramed areas for each cellType
if numCellTypes >1
    for type = 1:numCellTypes
        cellTypeArea(type) = sum(hts(:,type)*(ctrs(2)-ctrs(1)));
    end
else
    cellTypeArea(1) = sum(hts*(ctrs(2)-ctrs(1)));
end

% obtain the ordinates to calculate PDF over (min(filtered gains to max
% filtered gains) minus/plus one for a little room
xx = linspace(min(min(filteredSoisMat))-1,max(max(filteredSoisMat))+1,1000);

% Hold the histogram plot and plot PDFs
for type = 1:numCellTypes
    hold on
    plot(xx,cellTypeArea(type)*normpdf(xx,meanSois(type),...
         stdSois(type)),colors{type});
end

%remove hold
hold off

% reverse plots so PDFs are on top
chH = get(gca,'Children');
set(gca,'Children',[chH(end);chH(1:end-1)])

% Set axis labels and title
xlabel('Surround Modulation Index')
ylabel('# Cells')

% Depending on the number of cellTypes the title changes
if numel(cellTypesofInterest) == 2;
title(['Surround Modualation Index (', cellTypesofInterest{1}, ') n = ',...
        num2str(numel(filteredSois{1})),...
        ' (',cellTypesofInterest{2},') n= ',...
        num2str(numel(filteredSois{2}))]);
elseif numel(cellTypesofInterest) == 1;
    title(['Surround Modualation Index (', cellTypesofInterest{1}, ') n = ',...
        num2str(numel(filteredSois{1}))]);

end

end

