function csPlotterDep(csMapObj, angles, stimulus, fileInfo, hfig)
% csPlotter plots the signals stored in the csMapObj returned from csMap.m.
% Based on the user choice of anlges (a number or 'all') csPlotter will
% return a plot of the individual signals and averages.
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
%%%%%%%%%%%%%%%%%%%%%% PERFROM CHK OF ANGLE INPUT %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(angles)
    angles =  cell2mat(csMapObj.keys);
elseif isscalar(angles)
    angles = angles;
else
    errordlg('Please enter a valid angle')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% OBTAIN STIMULUS INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%
% Get the stimulus timing and frame rate
stimTiming = stimulus(1,1).Timing;
frameRate = fileInfo(1,1).imageFrameRate;

% The incoming csMapObj is keyed on angle with each angle containing a cell
% array that is number of trials by number of conditions in size
cell1 = csMapObj(angles(1));
% we get the number of conditions by looking at the size of cell1 along the
% second dimension
numConds = size(cell1,2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% The incoming csMapObj is keyed on angle. Each angle contains as values a
% cell array that is numTrials by numConditions in size. We will loop
% through the angles in the map and make a matrix over trials where each
% column will hold an individual trial. Note the end CondMats will be
% numAngles x conds in size and each cell element will be a matrix of
% trials for that angle and condition

% construct a new empty array to hold the trials
condMats = {};

for angleIndex = 1:numel(angles)
    angleCell = csMapObj(angles(angleIndex));
    for cond = 1:numConds
        condMats{angleIndex,cond} = cat(2,angleCell{:,cond});
    end
end

% obtain max of all traces for scaling plots
maxVal = max(max(cellfun(@(r) max(r(:)), condMats)));
minVal = min(min(cellfun(@(r) min(r(:)), condMats)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% COMPUTE MEANS OF EACH CONDITION %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now want to compute the mean across trials for each condition. This
% will remove one level of nesting in the arrTrials cell array
% Loop through the angles
for angleIndex = 1:numel(angles)
    for cond = 1:numConds
        condMeans{angleIndex,cond} = mean(condMats{angleIndex,cond},2);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

% We will loop through the angles and the conditions and make a subplot of
% the indidual trials, and mean at each condition
for angleIndex = 1:numel(angles)
    for cond = 1:numConds
        % create a cell array of condition strings for plotting to title of each
        % plot below
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
        frames = [1:size(condMeans{angleIndex,cond},1)];
        time = frames/frameRate;
        
        % if there is data to plot (i.e. size(time)>1) then plot
        if size(time,2)>1
            % plot the means
            plot(time,condMeans{angleIndex,cond},'Color',[0,0,0],...
                 'LineWidth',2)
          
            hold on
            
            plot(time,condMats{angleIndex,cond},'Color',[.5,.5,1],...
                'LineWidth',1)
            
            hold off
            %title(['\theta_{C}=', num2str(angles(angleIndex)),' ',...
                %' \theta_{S}= ', conditionStrings{cond}]);
            axis('tight')
            ylim([minVal,maxVal])
            %tickVals = minVal:(maxVal-minVal)/2:maxVal;
            %set(gca,'YTick',tickVals)
            %set(gca,'YTickLabel',[num2str(minVal),'|',num2str(maxVal)])

        else
            plot(condMeans{angleIndex,cond})
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%% PLOT THE STIM EPOCHS %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if size(time,2) > 1
            
            % get the visual start and end times
            visStart = stimTiming(1);
            visEnd = stimTiming(1)+stimTiming(2);

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
            set(ha, 'FaceColor', [.85 .85 .85])
            set(ha, 'LineStyle', 'none')
            
            set(gca, 'box','off')
            hold off;
            % We now want to reorder the data plot and the area we just
            % made so that the signal always appears on top we do this by
            % accessing all lines ('children') and flip them
            set(gca,'children',flipud(get(gca,'children'))) 
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end % end of conds loop
end % end of angles loop


end

