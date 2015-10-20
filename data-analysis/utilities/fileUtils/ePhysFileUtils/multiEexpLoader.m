function [loadedEexps, eExpNames] = multiEexpLoader(eExpType, fieldsToLoad )
% multiEexpLoader loads an eExp from a directory specified by the
% eExpType and loads only specified fields.
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
% INPUTS:               eExpType:     can be raw or analyzed and determines 
%                                     the load directory
%                       fieldsToLoad: cell array of fieldnames to load from
%                                     the eExp
% OUTPUTS:              loadedEexps:  a cell array of load eExps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% OBTAIN FILE AND PATHNAMES %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We first tell uigetfile where it can find eExp files
electroExpDirInformation

switch eExpType
    case 'raw'
        % Now we obtain the fileNames of the imExps and the path
        % information (note we allow multiple imExp selections)
        [eExpNames, path] = uigetfile(eDirInfo.electroExpRawFileLoc,...
                                'PLEASE SELECT eEXP','MultiSelect', 'on');
                            
   case 'analyzed'
        % Now we obtain the fileNames of the imExps and the path
        % information (note we allow multiple imExp selections)
        [eExpNames, path] = uigetfile(...
                                eDirInfo.electroExpAnalyzedFileLoc,...
                                'PLEASE SELECT eEXP_ANALYZED',...
                                'MultiSelect', 'on');
                            
    case 'wholeCell'
        % Now we obtain the fileNames of the imExps and the path
        % information (note we allow multiple imExp selections)
        [eExpNames, path] = uigetfile(...
                                eDirInfo.wholeCellElectroExpFileLoc,...
                                'PLEASE SELECT eEXP_ANALYZED',...
                                'MultiSelect', 'on');
end

% if the user selects only onefile we recast imExpNames as a cell
if ischar(eExpNames)
    eExpNames = {eExpNames};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PERFOM LOADING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform loading in a try/catch and return back fileNames of ones that
% failed to load
for file = 1:numel(eExpNames)
    try
        % We now load the 'fieldsToLoad' from the eExp
        loadedEexps{file} = load(fullfile(path,eExpNames{file}),...
                           fieldsToLoad{:});
    catch
       errordlg(['LOADING FAILURE FILE ',eExpNames{file}]) 
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

