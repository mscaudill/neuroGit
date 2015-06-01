function [loadedImExps, imExpNames] = multiImExpLoader(imExpType, fieldsToLoad)
% multiImExps loader loads an imExp from a directory specified by the
% imExpType and loads only specified fields.
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
% INPUTS:          imExpType: can be raw, roi, or analyzed, determines the
%                             load directory
%                  fields to load: cell array of fields to load from the
%                                  imExp. Can also be set to the 'all' to
%                                  load all fields
%
% OUTPUTS:         NONE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% OBTAIN FILE AND PATHNAMES %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We first tell uigetfile where it can find imExp_analyzed files
ImExpDirInformation

switch imExpType
    case 'raw'
        % Now we obtain the fileNames of the imExps and the path
        % information (note we allow multiple imExp selections)
        [imExpNames, path] = uigetfile(dirInfo.imExpRawFileLoc,...
                                'MultiSelect', 'on');
    case 'roi'
        % Now we obtain the fileNames of the imExps and the path
        % information (note we allow multiple imExp selections)
        [imExpNames, path] = uigetfile(dirInfo.imExpRoiFileLoc,...
                                'MultiSelect', 'on');
    case 'analyzed'
        % Now we obtain the fileNames of the imExps and the path
        % information (note we allow multiple imExp selections)
        [imExpNames, path] = uigetfile(dirInfo.imExpAnalyzedFileLoc,...
                                'MultiSelect', 'on');
end

% if the user selects only onefile we recast imExpNames as a cell
if ischar(imExpNames)
    imExpNames = {imExpNames};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PERFOM LOADING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for file = 1:numel(imExpNames)
    % We now load the 'fieldsToLoad' from the imExp
    if strcmp(fieldsToLoad, 'all')
        try
           loadedImExps{file} =  load(fullfile(path,imExpNames{file}));
        catch
            % Throw an error if Classifications are not present in imExp
            errordlg(['LOADING FAILURE FILE #',num2str(file)]);
        end
        
    else
        try
           loadedImExps{file} = ...
               load(fullfile(path,imExpNames{file}),fieldsToLoad{:});
        catch
            % Throw an error if Classifications are not present in imExp
            errordlg(['LOADING FAILURE FILE #',num2str(file)]);
        end
    end
end

