function smi_scatter_arch()
%generates a scatter plot of the surround modulation index with and without
%an LED shown for pyramidal cells.
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
%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL MULTIIMEXPLOADER %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
loadedImExps = multiImExpLoader('analyzed',{'fileInfo','cellTypes',...
                                'stimulus',...
                                'signalClassification','rois'...
                                'signalMetrics', 'areaMetrics'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

angles = unique([loadedImExps{1}.stimulus(1,:).Center_Orientation]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% EXTRACT CLASSIFICATION, AREAS, & RESPONSE TYPES %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for file = 1:numel(loadedImExps)
    disp(loadedImExps{file}.fileInfo(1,1).stimFileName)
    rois = loadedImExps{file}.rois;
    for roiSet=1:numel(rois)
        
        if ~isempty(rois{roiSet})

            for roiNum=1:numel(rois{roiSet})
                
                % get the cellType
                cellType = loadedImExps{file}.cellTypes{roiSet}{roiNum};
                if ~strcmp(cellType,'pyr')
                    continue
                end
                
                % get the classification and response pattern
                classification =...
                    loadedImExps{file}.signalClassification...
                    .classification{roiSet}{roiNum};
                
                response_pattern = identifyScsPattern('pyr', ...
                                                       classification);
                
                if ~ismember(response_pattern,[3,4])
                    continue
                end
                
                % get the maxArea Angle and index
                max_area_angle = ...
                    loadedImExps{file}.signalClassification...
                    .maxAreaAngle{roiSet}{roiNum};
                
                angleIndex = find(max_area_angle == angles);
                
                % get the mean areas and check iso < max(crosses)
                mean_areas = ...
                    loadedImExps{file}.areaMetrics...
                    .meanAreas{roiSet}{roiNum}{angleIndex};
                
                if mean_areas(4) > max(mean_areas(2:3))
                    continue
                end
                
                % we need to require that crosses are close to C0 to be cs
                % modulated like
                if max(mean_areas(2:3)) < 0.7*mean_areas(1)
                    continue
                end
                
                % add a smi threshold
                smi = loadedImExps{file}.signalMetrics...
                    .surroundOriIndex{roiSet}{roiNum};
                
                if smi < 0.141 % corresponds to cross 33% larger than iso
                    continue
                end
                
                
                
                % get the smi and smi_led
                smis{file}{roiSet}{roiNum} =...
                    loadedImExps{file}.signalMetrics...
                    .surroundOriIndex{roiSet}{roiNum};
                
                smis_led{file}{roiSet}{roiNum} =...
                    loadedImExps{file}.signalMetrics...
                    .surroundOriIndex_led{roiSet}{roiNum};
                
                % Display the cell being processed
                disp(['Adding file : RoiSet : RoiNum  ',...
                    num2str(file),' : ', num2str(roiSet),...
                    ' : ' num2str(roiNum),'*****', ' SMIS ',...
                    num2str(smis{file}{roiSet}{roiNum}),' : ', ...
                    num2str(smis_led{file}{roiSet}{roiNum})])
                
                %if passes above test add to arrays for plotting and keep
                % track of expName and roiSet and roiNum
            end
        end
    end
end

smis = [smis{:}];
smis = [smis{:}];
smis = squeeze([smis{:}]);

mean_smi = mean(smis);
sem_smi = std(smis)./sqrt(numel(smis));

smis_led = [smis_led{:}];
smis_led = [smis_led{:}];
smis_led = squeeze([smis_led{:}]);

mean_smi_led=mean(smis_led);
sem_smi_led = std(smis_led)./sqrt(numel(smis_led));

hold on
scatter(smis,smis_led, 50, 'b')

scatter(mean_smi, mean_smi_led, 150, 'b', '^','fill')

errorbarxy(mean_smi, mean_smi_led,...
        sem_smi, sem_smi_led,[],[],...
        'r','r')

xlabel('SMI CNTRL')
ylabel('SMI LED')
refline(1,0)

assignin('base','smis',smis)
assignin('base','smis_led',smis_led)
end

