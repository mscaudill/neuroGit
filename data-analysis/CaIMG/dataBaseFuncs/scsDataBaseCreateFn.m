function scsDataBaseCreateFn(dataBaseOperation,...
                                              cellTypeOfInterest,...
                                              responsePatterns)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DataBaseCreateFn performs three possible dataBaseOperations. 1. creates a 
% new dataBase from a user defined list of analyzed Exps. 2. adds to a 
% pre-existing dataBase array of structs a new entry or 3. removes an entry\
% from a pre existing database array of structs
% INPUTS:               dataBaseOperation; 'new', 'add', 'delete' string
%                               entry specifing what the function will do.
%                       cellTypeOfInterest; type of cells present in a
%                               new dataBase
%                       responsePattern; the pattern(s) of
%                               cells present in the new dataBase Please
%                               see scsIdentifier for pattern to
%                               classification conversion.
% OUTPUTS:              dataBaseStruct; an array of structs containing
%                               database entries, with fields:
%                                   date, recordingLocation,
%                                   recordingDepth, cellID, cellType,
%                                   classification, maxAreaAngle, nSigma,
%                                   maxSurroundAngle
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
%%%%%%%%%%%%%%%%%%% OBTAIN ALL THE REPSONSE CLASSES %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We call the function responsePatternToClassification. It takes a
% response pattern (please see identify scsPattern) and converts it to a
% set of arrays of responses (ex response 4 is arrays where [1
% (0,1),(0,1),(0,1),0) condition is met
classificationsOfInterest =...
    responsePatternToClassification(responsePatterns);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create a the dataBaseStruct
dataBaseStruct = struct();

switch dataBaseOperation
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'new' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % If the user request a new dataBaseStruct we start by calling
        % multiImExpLoader with analyzed option calling the fields
        % (cellTypes, imagingDepth, signalClassification). This function
        % creates a cell of loaded imExps_analyzed
        [loadedImExps, imExpNames] = multiImExpLoader('analyzed',...
                                {'cellTypes',...
                                'signalClassification'});
                            
        % Loop through the loadedImExps
        for exp = 1:numel(loadedImExps)
            
            %%%%%%%%%%%%%% RESTRUCTURE CELLTYPES/CLASS/ROIPAIRS %%%%%%%%%%%
            % concatenate all the cellTypes into a cell array
            cellTypes = [loadedImExps{exp}.cellTypes{:}];
            
            % concatenate all the classifications into a cell array
            classifications =...
                [loadedImExps{exp}.signalClassification.classification{:}];

            % call roiPairCreator to construct the pairs of (RoiSet,RoiNum)
            indexMatrix = roiPairCreator(...
                loadedImExps{exp}.signalClassification.classification);
            
            %convert the index matrix into a cell of roi pairs 
            roiPairs = mat2cell(indexMatrix,ones(1,...
                                size(indexMatrix,1)),2)';
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            
            %%%%%%%%%%%%%%%% EXTRACT DATA TO ADD TO DATABASE %%%%%%%%%%%%%%
            % Now loop through each roiSet,RoiNum and determine if
            % 1. The classification of this roi response matches the users
            %    classifications of interest
            % 2. The cellType matches the useres cellType of Interest
            % If 1 & 2, then add to dataBase: date, recordingSite,
            %    classification, roiId, maxAreaAngle. maxSurroundAngle,
            %    nSigma
           for roiPair = 1:numel(roiPairs)
               if any(cellfun(@(x) isequal(x,classifications{roiPair}),...
                       classificationsOfInterest)) && strcmp(...
                            cellTypes{roiPair},cellTypeOfInterest)
                        
                        % get the exp date and recording site by splitting
                        % the filename of the imExp
                        nameParts = strsplit(imExpNames{exp},'_');
                        
                        recordingDate = nameParts{1};
                        recordingSite = nameParts{2};
                        
                        % get the roiSet/Pair,  maxAreaAngle, nSigma,
                        % maxSurroundAngle
                        roiSet = roiPairs{roiPair}(1);
                        roiNum = roiPairs{roiPair}(2);
                        
                        classification =...
                            loadedImExps{exp...
                            }.signalClassification.classification{roiSet...
                            }{roiNum};
                        
                        maxAreaAngle = loadedImExps{exp...
                            }.signalClassification.maxAreaAngle{...
                            roiSet}{roiNum};
                        
                        maxSurroundAngle = loadedImExps{exp...
                            }.signalClassification.maxSurroundAngle{...
                            roiSet}{roiNum};
                        
                        nSigma = loadedImExps{exp...
                            }.signalClassification.nSigma{...
                            roiSet}{roiNum};
                        
                        %%%%%%%%%%%%%%% ADD TO DATABASE STRUCT %%%%%%%%%%%%
                        dataBaseStruct(exp...
                            ).roi(roiSet, roiNum).recordingDate =...
                            recordingDate;
                        
                        dataBaseStruct(exp...
                            ).roi(roiSet, roiNum).recordingSite =...
                            recordingSite;
                        
                        dataBaseStruct(exp...
                            ).roi(roiSet, roiNum).classification =...
                            classification;
                        
                        dataBaseStruct(exp...
                            ).roi(roiSet, roiNum).maxAreaAngle = ...
                            maxAreaAngle;
                        
                        dataBaseStruct(exp...
                            ).roi(roiSet, roiNum).maxSurroundAngle = ...
                            maxSurroundAngle;
                        
                        dataBaseStruct(exp...
                            ).roi(roiSet, roiNum).nSigma = nSigma;
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               end
           end
        end
        assignin('base', 'dataBaseStruct',dataBaseStruct)
        
        %%%%%%%%%%%%%%%%%%%%%%%%% SAVE DATABASE STRUCTURE %%%%%%%%%%%%%%%%%
        defaultSaveName = [datestr(now,29),'_scsDB_',cellTypeOfInterest,...
                           '_RespPatterns_',...
                           strrep(num2str(responsePatterns),'  ','-')];
        % call saveDataBase function
        saveDataBase(dataBaseStruct,defaultSaveName)
        disp(['DataBase Save Completed at ',datestr(now)])  
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    case 'add' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%% LOAD DATABASE AND ANALYZED IMEXP %%%%%%%%%%%%%%%%%%
        % We start by opening a pre-existing dataBase and an analyzed imExp
        % to add to the dataBase
        
        ImExpDirInformation;
        
        [dataBaseName, dataBasePath] =uigetfile(dirInfo.dataBaseFileLoc,...
                                                'MultiSelect','off');
                                            
        % load a pre-existing database struct
        load(fullfile(dataBasePath,dataBaseName));
        
        %Obtain the dataBaseSize
        dataBaseSize = size(dataBaseStruct,2);
        
        % open a single analyzedImExp
        [imExpName, PathName] = uigetfile(dirInfo.imExpAnalyzedFileLoc,...
                                            'MultiSelect','off');
        
        % now load the imExp using full-file to construct path\fileName
        imExp = load(fullfile(PathName,imExpName),'cellTypes',...
                                'signalClassification');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                                        
        %%%%%%%%%%%%%% RESTRUCTURE CELLTYPES/CLASS/ROIPAIRS %%%%%%%%%%%%%%%
        % concatenate all the cellTypes into a cell array
        cellTypes = [imExp.cellTypes{:}];
            
        % concatenate all the classifications into a cell array
        classifications =...
            [imExp.signalClassification.classification{:}];
        
        % call roiPairCreator to construct the pairs of (RoiSet,RoiNum)
        indexMatrix = roiPairCreator(...
            imExp.signalClassification.classification);
        
        %convert the index matrix into a cell of roi pairs
        roiPairs = mat2cell(indexMatrix,ones(1,...
            size(indexMatrix,1)),2)';
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%% EXTRACT DATA TO ADD TO DATABASE %%%%%%%%%%%%%%%%%%
        % Now loop through each roiSet,RoiNum and determine if
        % 1. The classification of this roi response matches the users
        %    classifications of interest
        % 2. The cellType matches the useres cellType of Interest
        % If 1 & 2, then add to dataBase: date, recordingSite,
        %    classification, roiId, maxAreaAngle. maxSurroundAngle, nSigma
        for roiPair = 1:numel(roiPairs)
            if any(cellfun(@(x) isequal(x,classifications{roiPair}),...
                    classificationsOfInterest)) && strcmp(...
                    cellTypes{roiPair},cellTypeOfInterest)
                
                % get the exp date and recording site by splitting
                % the filename of the imExp
                nameParts = strsplit(imExpName,'_');
                
                recordingDate = nameParts{1};
                recordingSite = nameParts{2};
                
                % get the roiSet/Pair,  maxAreaAngle, nSigma,
                % maxSurroundAngle
                roiSet = roiPairs{roiPair}(1);
                roiNum = roiPairs{roiPair}(2);
                
                classification =...
                    imExp.signalClassification.classification{...
                    roiSet}{roiNum};
                
                maxAreaAngle =...
                    imExp.signalClassification.maxAreaAngle{...
                    roiSet}{roiNum};
                
                maxSurroundAngle = ...
                    imExp.signalClassification.maxSurroundAngle{...
                    roiSet}{roiNum};
                
                nSigma =...
                    imExp.signalClassification.nSigma{...
                    roiSet}{roiNum};
                
            %%%%%%%%%%%%%%% ADD TO DATABASE STRUCT %%%%%%%%%%%%%%%%%%%%%%%%
            dataBaseStruct(dataBaseSize+1).roi(roiSet, roiNum).recordingDate...
                = recordingDate;
            
            dataBaseStruct(dataBaseSize+1).roi(roiSet,...
                roiNum).recordingSite = recordingSite;
            
            dataBaseStruct(dataBaseSize+1).roi(roiSet,...
                roiNum).classification = classification;
            
            dataBaseStruct(dataBaseSize+1).roi(roiSet,...
                roiNum).maxAreaAngle = maxAreaAngle;
            
            dataBaseStruct(dataBaseSize+1).roi(roiSet,...
                roiNum).maxSurroundAngle = maxSurroundAngle;
            
            dataBaseStruct(dataBaseSize+1).roi(roiSet,...
                roiNum).nSigma = nSigma;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%% SAVE DATABASE %%%%%%%%%%%%%%%%%%%%%%%%%%%
        assignin('base', 'dataBaseStruct',dataBaseStruct)
        saveDataBase(dataBaseStruct,dataBaseName)
        disp(['DataBase Save Completed at ',datestr(now)]) 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 'remove' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % load pre-existing struct
        % ask user to specify date, recording location and roiSet/roiNum
        % pair
        % locate this entry in the structure and remove it
        % add to a removal log
        % save struct with loaded struct name
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

end

