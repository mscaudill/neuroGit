function scs_database = scs_database_creator(cellTypes, responsePatterns)
% creates a database -- an array of structures containing detailed analysis
% of cell responses recorded during calcium imaging across many
% experiments.
% INPUTS:
%                       cellTypeOfInterests; type(s) of cells present in a
%                               new dataBase -- cell array
%                       responsePattern; the pattern(s) of
%                               cells present in the new dataBase Please
%                               see scsIdentifier for pattern to
%                               classification conversion. -- cell array
% OUTPUTS:              dataBaseStruct; an array of structs containing
%                               database entries, with fields:
%                                   date, recordingLocation,
%                                   recordingDepth, cellID, cellType,
%                                   classification, maxAreaAngle, nSigma,
%                                   maxSurroundAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% GET ANALYZED IMEXPS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call the multiexp loader to load analyzed imaging experiments load only
% the cell types and classification fields
[loadedImExps, imExpNames] = multiImExpLoader('analyzed', 'all');
                            
for exp = 1:numel(imExpNames)
    imExp = loadedImExps{exp};
    
    % Construct Name for exp to add to database
    fullName = imExpNames{exp};
    [C, ~] = strsplit(fullName,'_');
    imExpName = [C{2},'_',strrep(C{1},'-','_')];
    
    for roiSet = 1:numel(imExp.rois)
        for roiNum = 1:numel(imExp.rois{roiSet})
            % make sure there is an roi 
            if ~isempty(imExp.rois{roiSet}{roiNum})
                % get the cell type and the classification for this roi
                type = imExp.cellTypes{roiSet}{roiNum};
                % get the classification of this cell
                classif = ...
                 imExp.signalClassification.classification{roiSet}{roiNum};
             
                % see if the response matches the user selected
                % classifications they want for this particular cell type
                switch type
                    case cellTypes{1}
                        % Get the response see identifyScsPattern
                        response = identifyScsPattern(cellTypes{1},...
                                                      classif);
                                                  
                        if ismember(response, responsePatterns{1})
                                    
                            % add structures from imExp
                            scs_database.(imExpName).fileInfo =...
                                imExp.fileInfo;
                            
                            scs_database.(imExpName).encoderOptions =...
                                imExp.encoderOptions;
                            
                            scs_database.(imExpName).stimulus =...
                                imExp.stimulus;
                            
                            scs_database.(imExpName).behavior =...
                                imExp.behavior;
             
                            scs_database.(imExpName).rois =...
                                imExp.rois;
                            
                            scs_database.(imExpName).signalRunState =...
                                imExp.SignalRunState;
             
                            % Add analyzed data for cells with the right
                            % classification
                            
                            scs_database.(imExpName)...
                                .signalMetrics.surroundOriIndex{roiSet,...
                                roiNum} = imExp.signalMetrics...
                                .surroundOriIndex{roiSet}{roiNum};
                        end
                end
            end
        end
    end
end

                                
    
    



end

