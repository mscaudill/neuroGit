function osiHist(cellTypesofInterest)
% osiCalculator calculates the orientation selectivity index across a
% population of cells using cellTypeofInterest. The osi is calculated using
% the circular variance method 
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
% INPUTS:          cellTypesofInterest: a cell array of cellTypes to
%                                       calculate osis for and
%                                       wishes to plot ('som','pyr')
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
                                'areaMetrics', 'signalMaps'});
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
    
    % obtain the mean areas
    meanAreas{file} = loadedImExps{file}.areaMetrics.meanAreas;
    
    %now call the pattern classifier resturning the cellTypes and
    %responsePatterns for each imExp
    [expCellTypes{file},responsePatterns{file}]=scsPatternClassifier(...
                                                 cellTypeofInterest,...
                                                 cellTypes{file},...
                                                 classification{file});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end% end file load of this cellType;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN MAP KEYS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%obtain the angles that the imExp contains
signalMaps = loadedImExps{1}.signalMaps;
mapKeys = cell2mat(signalMaps{1}{1}.keys);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%  PERFORM CONCATENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to concatenate all the cell types responsePatterns and
% mean areas across all the imExps

allCellTypes = [expCellTypes{:}];

allResponsePatterns = [responsePatterns{:}];

combFileAreas = [meanAreas{:}];

allAreas = [combFileAreas{:}];
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
        respPattern = [2,4];
    case 'som'
        respPattern = [4,5];
        
end

filteredAreas{cellTypeIndex} = csCellArrayFilter(allAreas,allCellTypes,...
                            cellTypeofInterest,...
                            allResponsePatterns,respPattern);    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN AREAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%We will calculate the osi based on either the center responses (pyramidal
%cells) or the iso responses (som cells) so we will get these areas
%depending on the cellTypeofInterest
switch cellTypeofInterest
    case 'pyr'
        AreaofInterest{cellTypeIndex} = cellfun(@(g) cellfun(@(t) t(1),...
                            g), filteredAreas{cellTypeIndex},...
                            'UniformOut',0);
    case 'som'
        AreaofInterest{cellTypeIndex} = cellfun(@(g) cellfun(@(t) t(4),...
                            g), filteredAreas{cellTypeIndex},...
                            'UniformOut',0);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% CALCULATE THE OSI VALUE %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
anglesRads = pi/180*mapKeys;
 
osis{cellTypeIndex} = cellfun(@(x) ...
                        abs(sum((x).*exp(2i*anglesRads)/sum(x))),...
                        AreaofInterest{cellTypeIndex},'UniformOut',1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% OBTAIN THE MEAN AND STD %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
meanOsis(cellTypeIndex) = mean(osis{cellTypeIndex});
stdOsis(cellTypeIndex) = std(osis{cellTypeIndex});
end
%%%%%%%%%%%%%%%%%%%%%% END FOR LOOP OVER CELLTYPES %%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% CONVERT THE OSIS TO MATRIX FORM %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Since the number of cells for each cellType might be different we need to
% find the cellType with the most and then pad the shorter one with NaNs to
% make a rectangular matrix

% get the max number of cells across all cellTypes
maxLength = max(cellfun(@(r) numel(r), osis));

% pad the shorter ones in the cell array with an NaN. We pad the difference
% in lengths and store the results for each cellType to a column in
% filtered gains matrix
for cellIndex = 1:numel(osis)
    osisMat(:,cellIndex) = padarray(osis{cellIndex},...
        [0,maxLength-numel(osis{cellIndex})],NaN,'post')';
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
[hts,ctrs] = hist(osisMat);
bar(ctrs,hts,'hist')

% Get the number of cellTypes
numCellTypes = numel(cellTypesofInterest);

% create a color space (we currently support only two pop colors
colors = {'b','r'};

h = findobj(gca,'Type','patch');
% This gets the patch objects in reverse order (i.e. last one drawn) so we
% reverse colors here
flippedColors = fliplr(colors);
for type = 1:numCellTypes
    set(h(type),'FaceColor',flippedColors{type},'EdgeColor','k')
end


%%%%%%%%%%%%%%%%%%%%%%%%%% Create the PDFs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% obtain the histogramed areas for each cellType
for type = 1:numCellTypes
    cellTypeArea(type) = sum(hts(:,type)*(ctrs(2)-ctrs(1)));
end

% obtain the ordinates to calculate PDF over (min(filtered gains to max
% filtered gains) minus/plus one for a little room
xx = linspace(0,.6,1000);

% Hold the histogram plot and plot PDFs
for type = 1:numCellTypes
    hold on
    plot(xx,cellTypeArea(type)*normpdf(xx,meanOsis(type),...
         stdOsis(type)),colors{type});
end

%remove hold
hold off

% reverse plots so PDFs are on top
chH = get(gca,'Children');
set(gca,'Children',[chH(end);chH(1:end-1)])

% Set axis labels and title
xlabel('CV Index')
ylabel('# Cells')

% Depending on the number of cellTypes the title changes
if numel(cellTypesofInterest) == 2;
title(['Circular Variance (OSI) (', cellTypesofInterest{1}, ') n = ',...
        num2str(numel(osis{1})),...
        ' (',cellTypesofInterest{2},') n= ',...
        num2str(numel(osis{2}))]);
elseif numel(cellTypesofInterest) == 1;
    title(['Circular Variance (OSI) (', osis{1}, ') n = ',...
        num2str(numel(osis{1}))]);

end

assignin('base','meanOsis',meanOsis)
end


