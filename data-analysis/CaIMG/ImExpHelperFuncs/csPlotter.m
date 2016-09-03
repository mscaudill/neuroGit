function csPlotter(csSignalMaps, cellType, angles, stimulus, fileInfo,...
                   framesDropped, hfig, roiSet, roiIndex, imExpName)
% CSPlotter plots the center-surround signals (nonLed and Led (if present)
% in the csSignalMaps cell array passed from SignalMaps. Based on the user 
% choice of angles (a number or 'all') csPlotter will return a plot of the 
% individual signals and averages.
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
%%%%%%%%%%%%%%%%%%%%%% DETERMINE IF LED MAPS ARE PRESENT %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We need to determine if an LED map exist. We can do this in several ways.
% We will look at wheter signalMaps{2} (the led map container) is empty. If
% not then we will plot both control and led trials togehter. This
% currently does not give the user the choice of plotting one or the other.
if isempty(csSignalMaps{2}{1})
        % Only a non-led Map is present
        nonLedMap = csSignalMaps{1}{1};
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%% PERFROM CHK OF ANGLE INPUT %%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if strcmp('all',angles) % user has entered 'all' angles
            angles =  cell2mat(nonLedMap.keys);
        elseif isscalar(angles) % case where user entered specific angle
            % nothing to be done
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%% OBTAIN STIMULUS INFORMATION %%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Get the stimulus timing and frame rate
        stimTiming = stimulus(1,1).Timing;
        frameRate = fileInfo(1,1).imageFrameRate;

        % The nonLedMap is keyed on angle with each angle
        % containing a cell array that is number of trials by number of
        % conditions in size
        cell1 = nonLedMap(angles(1));
        % we get the number of conditions by looking at the size of cell1
        % along the second dimension
        numConds = size(cell1,2);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % The nonLedMap is keyed on angle. Each angle contains as
        % values a cell array that is numTrials by numConditions in size.
        % We will loop through the angles in the map and make a matrix over
        % trials where each column will hold an individual trial. Note the
        % end CondMats will be numAngles x conds in size and each cell
        % element will be a matrix of trials for that angle and condition

        % construct a new empty array to hold the trials
        nonLedCondMats = {};
        
        for angleIndex = 1:numel(angles)
            nonLedAngleCell = nonLedMap(angles(angleIndex));
            for cond = 1:numConds
                nonLedCondMats{angleIndex,cond} = ...
                                    cat(2,nonLedAngleCell{:,cond});
            end
        end
        
        % obtain max of all traces for scaling plots
        maxVal = max(max(cellfun(@(r) max(r(:)), nonLedCondMats)));
        minVal = min(min(cellfun(@(r) min(r(:)), nonLedCondMats)));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%% COMPUTE MEANS OF EACH CONDITION %%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % We now want to compute the mean across trials for each condition.
        % This will remove one level of nesting in the arrTrials cell array
        % Loop through the angles
        for angleIndex = 1:numel(angles)
            for cond = 1:numConds
                nonLedCondMeans{angleIndex,cond} = ...
                                   mean(nonLedCondMats{angleIndex,cond},2);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

if ~isempty(csSignalMaps{2}{1}) 
        % Both a nonLed and LedMap are present in signalMaps
        nonLedMap = csSignalMaps{1}{1};
        LedMap = csSignalMaps{2}{1};
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%% PERFROM CHK OF ANGLE INPUT %%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if strcmp('all',angles) % user has entered 'all' angles. The angles
            % will be the same for the led and non-led maps
            angles =  cell2mat(nonLedMap.keys);
        elseif isscalar(angles) % case where user entered specific angle
            angles = angles;
        else
            errordlg('Please enter a valid angle')
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%% OBTAIN STIMULUS INFORMATION %%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Get the stimulus timing and frame rate. The stimulus timing will
        % be taken from the first stimulus shown. Note that timing of led
        % and non-led trials may be different but the number of collected
        % frames will always be the same
        stimTiming = stimulus(1,1).Timing;
        frameRate = fileInfo(1,1).imageFrameRate;

        % The Maps are keyed on angle with each angle
        % containing a cell array that is number of trials by number of
        % conditions in size this will be the same for both maps
        cell1 = nonLedMap(angles(1));
        % we get the number of conditions by looking at the size of cell1
        % along the second dimension
        numConds = size(cell1,2);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % The Maps are keyed on angle. Each angle contains as
        % values a cell array that is numTrials by numConditions in size.
        % We will loop through the angles in the map and make a matrix over
        % trials where each column will hold an individual trial. Note the
        % end CondMats will be numAngles x conds in size and each cell
        % element will be a matrix of trials for that angle and condition

        % construct a new empty array to hold the trials
        nonLedCondMats = {};
        ledCondMats = {};
        
        for angleIndex = 1:numel(angles)
            % For each angle idx get all of the responses across trials and
            % conditions for both the nonLed and LedMaps
            nonLedAngleCell = nonLedMap(angles(angleIndex));
            ledAngleCell = LedMap(angles(angleIndex));
            % for each contition, concatenate all the trials into a single
            % matrix. Trials will be individual cols.
            for cond = 1:numConds
                nonLedCondMats{angleIndex,cond} = ...
                                            cat(2,nonLedAngleCell{:,cond});
                ledCondMats{angleIndex,cond} = ...
                                            cat(2,ledAngleCell{:,cond});
                
                
            end
        end
        
        % obtain max of all traces for scaling plots
        maxNoLed = max(max(cellfun(@(r) max(r(:)), nonLedCondMats)));
        minNoLed = min(min(cellfun(@(r) min(r(:)), nonLedCondMats)));
        maxLed = max(max(cellfun(@(r) max(r(:)), ledCondMats)));
        minLed = min(min(cellfun(@(r) min(r(:)), ledCondMats)));
        % Now get absolute min,max from each map for plotting
        maxVal = max(maxNoLed,maxLed);
        minVal = min(minNoLed,minLed);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%% COMPUTE MEANS OF EACH CONDITION %%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % We now want to compute the mean across trials for each condition
        % for each map. This will remove one level of nesting in the
        % arrTrials cell array Loop through the angles
        for angleIndex = 1:numel(angles)
            for cond = 1:numConds
                nonLedCondMeans{angleIndex,cond} = ...
                                   mean(nonLedCondMats{angleIndex,cond},2);
                               
                ledCondMeans{angleIndex,cond} = ...
                                   mean(ledCondMats{angleIndex,cond},2);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% COMPUTE MAX AREA ANGLE AND NSIGMA %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We want to plot a line for the Nsigma.
[maxAreaAngle, ~, nSigma, ~,~, priorStdMean]=...
scsClassifier(csSignalMaps(1), cellType, 1, 1, stimulus,...
              fileInfo, 17, 2, []);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now will generate a figure with subplots in it that match the number
% of angles and stimulus conditions the user supplied.
% if the user chose to plot all angles, then we need to make a larger
% figure to draw to
if numel(angles) > 1
    set(hfig,'Position',[198, 99, 1549, 879]);
end

if ~isempty(roiSet) && ~isempty(roiIndex)
    Supertitle = [strrep(imExpName,'_','-'), ' ROI:', num2str(roiSet),...
                '-',num2str(roiIndex)];
            
    annotation('textbox', [0 0.9 1 0.1], ...
        'String', Supertitle, ...
        'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'fontWeight', 'Bold')
end

% We will loop through the angles and the conditions and make a subplot of
% the indidual trials, and mean at each condition for each map
for angleIndex = 1:numel(angles)
           
    for cond = 1:numConds
        % create a cell array of condition strings for plotting to title of
        % each plot below
        conditionStrings = {'Center Alone',...
                            num2str(mod(angles(angleIndex)+90,360)),...
                            num2str(mod(angles(angleIndex)-90,360)),...
                            num2str(angles(angleIndex)), 'Surround Alone'};
                        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%% PLOT DATA AND MEANS %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Determine which subplot to plot to
        subplot(numel(angles),numConds,(angleIndex-1)*numConds+cond)
        
        % get the number of frames collected to convert to time
        frames = [1:size(nonLedCondMeans{angleIndex,cond},1)];
        time = frames/frameRate;
        
        % if there is data to plot (i.e. size(time)>1) then plot
        if size(time,2)>1
            % plot the means of the nonLed trials in black
            plot(time,nonLedCondMeans{angleIndex,cond},'Color',[0,0,0],...
                 'LineWidth',2)
             
             hold on
            
            % plot individuial trials in gray
            plot(time,nonLedCondMats{angleIndex,cond},'Color',...
                [205/255,201/255,201/255],...
                'LineWidth',1)
            
            ylim([minVal,maxVal])
            
            if ~isempty(csSignalMaps{2}{1})
                
                hold on
                
                % plot the means of the Led trials in dark green
                plot(time,ledCondMeans{angleIndex,cond},'Color',...
                    [46/255,139/255,87/255],'LineWidth',2)
             
                hold on
                
                % Plot individual led trials in light green
                plot(time,ledCondMats{angleIndex,cond},'Color',...
                    [143/255,188/255,143/255],'LineWidth',1)
            end
            
            hold off
            
            title(['\theta_{C}=', num2str(angles(angleIndex)),' ',...
                ' \theta_{S}= ', conditionStrings{cond}]);
            axis('tight')
            ylim([minVal,maxVal])
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%% PLOT NSIGMA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if angles(angleIndex) == maxAreaAngle
            hold on
            maxSigma = max(nSigma);
            
            % Plot the maxSigma
            plot(time, maxSigma*priorStdMean*ones(1,numel(time)),...
                'color', [255, 80, 80]/255)
            hold on
            text(min(time)+0.2,maxSigma*priorStdMean+0.1,...
                 num2str(maxSigma,3))
            
            hold on
            % Plot the maxSigma-10
            plot(time, (maxSigma-10)*priorStdMean*ones(1,numel(time)),...
                'color', [255, 120, 120]/255)
            hold on

            % Plot the maxSigma-20
            plot(time, (maxSigma-20)*priorStdMean*ones(1,numel(time)),...
                'color', [255, 120, 120]/255)
            
            hold off
        end
            
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%% PLOT THE STIM EPOCHS %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if size(time,2) > 1
            
            % get the visual start and end times. Adiust the stimEpoch back
            % to the left by numFramesDropped/frameRate
            visStart = stimTiming(1)-(numel(framesDropped)/frameRate);
            visEnd = visStart+stimTiming(2);

            hold on
            % create a horizontal vector for the stimulation times
            stimTimesVec = visStart:0.1:visEnd;
            % get the 'y' limits of the current axis
            yLimits = get(gca, 'ylim');
            
            % creat a 'y' vector that will form the upper horizontal
            % boundary of our shaded region
            ylimVector= yLimits(2)*ones(numel(stimTimesVec),1);
            ha = area(stimTimesVec, ylimVector, yLimits(1));
            
            % set the area properties
            set(ha, 'FaceColor', [220 220 220]/255)
            set(ha, 'LineStyle', 'none')
            
            set(gca, 'box','off')
            hold off;
            % We now want to reorder the data plot and the area we just
            % made so that the signal always appears on top we do this by
            % accessing all lines ('children') and flip them
            set(gca,'children',flipud(get(gca,'children'))) 
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end % end conds loop
end % end of angles looo


