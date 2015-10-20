function expSaverFunc( stimFileNames, ExpName, electroExp,...
                        electroExpType, expStage, varargin)
%expSaverFunc saves an electroRxp structure to a directory uniquely defined
% by the ExpType, and the stage of processing (raw, analyzed)
% INPUTS:                   stimFileNames: list of stimulus fileNames for
%                                           constructing name of the eEXP
%                           ExpName: a string (can be '') if the ExpName 
%                                    has already been created
%                           electroExp: the exp strucutre obj to be saved
%                           electroExpType: string matching one of
%                                       {'whole-cell', 'cell-attached',
%                                        'not specified'}
%                           expStage: string matching one of {'raw',
%                                                           'analyzed',''}
%                           varagin: string matching one of
%                                    {'Vclamp','Iclamp'}
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
%%%%%%%%%%%%%%%%%%%%%% LOAD DIRECTORY INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We first determine the specific directory where we will save the eExp to
% called targetLoc.

% Get Dir information
electroExpDirInformation

% Use a switch case statement to determine file save locations
switch electroExpType
    
    case 'cell-attached'
        
        if strcmp(expStage,'raw')
            % set target as cell attached raw
            expTargetLoc = eDirInfo.cellAttElectroExpRawFileLoc;
        
        elseif strcmp(expStage,'analyzed')
            % set target as cell-attached analyzed
            expTargetLoc = eDirInfo.cellAttElectroExpAnalyzedFileLoc;
        
        else 
            % else set to cell-attached root dir
            expTargetLoc = eDirInfo.cellAttachedElectroExpFileLoc;
        end
        
    case 'whole-cell'
        
        if strcmp(expStage, 'raw') && strcmp(varargin{1},'Vclamp')
            % set target as whole-cell raw vclamp
            expTargetLoc = eDirInfo.wholeCellElectroExpVclampRawFileLoc;
            
        elseif strcmp(expStage, 'raw') && strcmp(varargin{1},'Iclamp')
            % set target as whole-cell raw Iclamp
            expTargetLoc = eDirInfo.wholeCellElectroExpIclampRawFileLoc;
            
        elseif strcmp(expStage, 'analyzed') && strcmp(varargin{1},'Vclamp')
            % set target as whole-cell analyzed Vclamp
            expTargetLoc = ...
                eDirInfo.wholeCellElectroExpVclampAnalyzedFileLoc;
            
        elseif strcmp(expStage, 'analyzed') && strcmp(varargin{1},'Iclamp')
            % set target as whole-cell analyzed Iclamp
            expTargetLoc = ...
                eDirInfo.wholeCellElectroExpIclampAnalyzedFileLoc;
        
        else
            % set target as whole-cell root dir
            expTargetLoc = eDirInfo.wholeCellElectroExpFileLoc;
        end
        
    case 'not specified'
        % if the user has not specified cell-att or whole cell then we
        % default save to rootDir
        esxpTargetLoc = eDirInfo.rootDirLoc;
        
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CONSTRUCT DEFAULT NAME FOR EXP %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Depending on whether the expStage is raw or analyzed we will give the
% eExp a diffeent designation appending the name.

switch expStage
    case 'raw'
        % split the stimFileName on the underscores returning an allStrings
        % cell array
        allStrings = regexp(stimFileNames{1},'_', 'split');
        % obtain the date
        date = allStrings{2};
        % obtain the location and expType identifier
        locExpType = allStrings{3};

        defaultName =...
            [expTargetLoc,date,'_',locExpType,'_','electroExp','.mat'];
    
    case 'analyzed'
        % For an exp that has been created previously, it should arrive
        % with a name already. We will use that name if supplied and
        % otherwise construct a new name
        
        if ~isempty(ExpName)
            % split the ExpName on the underscores
            allStrings = regexp(ExpName,'_', 'split');
            assignin('base','allStrings',allStrings)
            % obtain the date
            date = allStrings{1};
            % obtain the location and expType identifier
            locExpType = allStrings{2};
        
            defaultName = [expTargetLoc, date,'_', locExpType, '_',...
                'electroExp_Analyzed', '.mat'];
        else
            
        % If for some reason the name has not been supplied we will default
        % to constructing our own. The use can change this in the uiput
        % file dialog if they wish. We will relay to the user that this is
        % happening
        disp(['User provided an anlayzed eExp but supplied no name, ',...
            'Creating a new name'])
        
        allStrings = regexp(stimFileNames{1},'_', 'split');
        % obtain the date
        date = allStrings{2};
        % obtain the location and expType identifier
        locExpType = allStrings{3};

        defaultName =...
            [expTargetLoc,date,'_',locExpType,'_',...
                                        'electroExp_Analyzed','.mat'];
        end
 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% CONSTRUCT PATH AND FILE NAME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[fileName,pathName] = uiputfile(expTargetLoc,'Save As',defaultName);
file = fullfile(pathName,fileName);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(fileName) && ischar(pathName) 
    save(file, '-struct', 'electroExp');
else
    warndlg('WARNING: EXPERIMENT NOT SAVED')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

