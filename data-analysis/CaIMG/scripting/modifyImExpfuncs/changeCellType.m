function changeCellType(posArray, newCellType)
% changeCellType opens an imExp with Rois and changes the celltypes
% specified in the pos array.
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
% INPUTS:           posArray: a two vector array of positions specifying
%                             the roiSet and the roiNumbers to be changed
%                   newCellType: a string specifying the new cell type to
%                                change to in the cellTypes cell array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD DIR INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%
ImExpDirInformation;
imExpRoiFileLoc = dirInfo.imExpRoiFileLoc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD IMEXP_ROIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call uigetfile (built-in) to select the imExp and get path to file
[imExpName, PathName] = uigetfile(imExpRoiFileLoc,...
                                            'MultiSelect','off');
                                        
% Now perform the loading and open a dialog box to relay to user
loadMsg = msgbox('LOADING IMEXP: Please Wait...');
% now load the imExp using full-file to construct path\fileName
imExp = load(fullfile(PathName,imExpName));
close(loadMsg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%% OBTAIN CELLTYPES CELL ARRAY AND APPLY CHANGES %%%%%%%%%
cellTypes = imExp.cellTypes;

% loop through the pos array and change the cellTypes
for row = 1:size(posArray,1)
    cellTypes{posArray(row,1)}{posArray(row,2)} = newCellType;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%% RESAVE CELL TYPES TO IMEXP STRUCT %%%%%%%%%%%%%%%%%%
imExp.cellTypes = cellTypes;

imExpSaverFunc([], imExpName, imExp, 'roi')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




