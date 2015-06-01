function [ incompleteDataFileNames, incompleteDataFileIndices ] =...
                            checkNumTriggs(PathName, dataFileNames,...
                                          dataFileType)
%checkNumTriggs examines all the dataFiles the user has loaded in the
%ExpMaker gui and checks the number of triggers in each file to identify
%files that are missing triggers. Currently we will ignore these files
%altogether. Missing triggers should be a rare event. If this occurs across
%multiple data files over several experiments change the triggering section
%of the stimulation code so that the pulses are longer and easier for the
%daq to identify.
% INPUTS:           pathName, path to dataFile locations
%                   dataFileName, cell of dataFileNames passed from gui
%                   dataFileType, either daq or abf
% OUTPUTS:          incompleteDataFileNames, cell of fileNames with missing
%                   triggers
%                   incompleteDataFileIndices, indices of missing triggers
%                   in the dataFileNames cell array

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% MAIN LOOP OVER DATAFILENAMES %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for name = 1:numel(dataFileNames)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% OBTAIN DATAFLE INFO FOR DAQ OR ABF FILE TYPES %%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % The user may be attempting to identify missing triggers in either daq or
    % abf files so we use a switch to handle these cases
    switch dataFileType
        
        case 'daq'
            % In the daq file type case we call daqinfo to get the number
            % of triggers for this file. Use the info option so that only
            % the header (and not the actual data) is loaded.
            daqInfo = daqread([PathName,dataFileNames{name}],'info');
            
            %obtain the number of triggers for this file
            numTriggers(name) = daqInfo.ObjInfo.TriggersExecuted;
        
        case 'abf'
            % In the abf fileType we call the abfload function with the
            % header only option ('info')
            [~,~,Info] = abfload([PathName,dataFileNames{name}], 'info');
            numTriggers(name) = Info.lActualEpisodes;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% IDENTIFY THE DATA FILES WITH MISSING TRIGGERS %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To identify the files with the missing triggers we will calculate the
% maximum of numTriggers and assume that this is how many triggers there
% was supposed to be and compare each element of numTriggers with this
% value
incompleteDataFileIndices  = find(numTriggers < max(numTriggers));

% now obtain the incomplete dataFileNames
incompleteDataFileNames = {dataFileNames{incompleteDataFileIndices}};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

