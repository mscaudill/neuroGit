function [ signalMaps, plotterType ] = SignalMapper( imExp, stimVariable,...
                                         roiSets, currentRoi, chNumber,...
                                         runState, Led, neuropilRatio)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2012  Matthew Caudill
%
%this program is free software: you can redistribute it and/or modify
%it under the terms of the gnu general public license as published by
%the free software foundation, either version 3 of the license, or
%at your option) any later version.

%this program is distributed in the hope that it will be useful,
%but without any warranty; without even the implied warranty of
%merchantability or fitness for a particular purpose.  see the
%gnu general public license for more details.

%you should have received a copy of the gnu general public license
%along with this program.  if not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Signal mapper is a wrapper function for fluorMap and csMap allowing the
% user to call either map depending on the stimulus input variable. It also
% sperates trials based on the led condition and returns a map object for
% each of the conditions (on/off) for each roi
%
% INPUTS:               imExp:        an imExp Structure
%                       stimVariable: parameter(s) varied in imExp
%                       signalCh:     image data channel
%                       roiSets:      cell array of rois passed from the
%                                     imExpanalyzer
%                       runState:     0,1,2 specifying to filter results to
%                                     nonrunning, running or both 
%                                     respectively. This is passed to the
%                                     mapper 
%                       Led:          a two-el cell array with the first
%                                     element being a boolean (led on = 
%                                     true, off = false) and the second 
%                                     element being a string 'odd'      
%                                     or 'even' since led trials could 
%                                     potential be on odd or even trials
% OUTPUTS:              signalMaps:   a one or two-el cell array (depending
%                                     on the led condition) containing 
%                                     cells with maps of signals for each 
%                                     roi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if Led{1} == true
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%% DETERMINE IF THE LED WAS USED IN THIS EXP %%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % If the user has selected the led option {true,'odd'|'even'} then
    % we need to check that the led was actually shown in the imExp.
    % This is stored in the stimulus struct Check to make sure that the
    % LED was shown (i.e. is present in stimulus structure)
    ledPresence = isfield(imExp.stimulus,'Led');
    if ledPresence == 0;
        % If the user has selected to seperate based on LED trials and
        % the stimulus structure does not confirm that an led was shown
        % then we throw a warning and set the led option to not true
        msgbox(['COULD NO CONFIRM LED SHOWN:', char(10),...
            'OVER-RIDING AND SETTING LED OPTION TO NOT SHOWN.'])
        Led = {false, 'even'};
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% SWITCH CASE FOR LED %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch Led{1}
    
    case true
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%% SPLIT IMEXP  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % If the LED was shown we will split the imExp into two
        % substructures measuring numTrials x numConds. For example if the
        % original imExp meaured 10 trials x 40 conditions the two subExps
        % will be 10 trials x 20 conditions each.
        
        % First get the fields of the imExp that we will extract alternate
        % trials from. These are currently, the stimulus, the behavior, the
        % corrected stacks and the stack extremas. However behavior may not
        % be there if the user selected to ignore behavior in the imExp
        % Maker so we test whether this field is in the imExp
        
        if isfield(imExp,'behavior');
            fieldsToAlternate = {'stimulus','behavior','correctedStacks',...
                                'stackExtremas'};
        else
            fieldsToAlternate = {'stimulus','correctedStacks',...
                                'stackExtremas'};
        end
        
        % create a cell to hold the structures we will pull alternate
        % trials from
        alternatingStructs = cellfun(@(z) imExp.(z), fieldsToAlternate,...
            'UniformOut',0);
        
        % The led could be shown on odd or even trials, we use the user
        % input to get the correct trials
        if strcmp(Led{2},'odd')
            % loop through alternating structs and get alternate trials
            ledSubStructs = cellfun(@(x) x(:,1:2:end), ...
                                alternatingStructs, 'uniformOut',0);
                            
            nonLedSubStructs = cellfun(@(x) x(:,2:2:end),...
                                   alternatingStructs,...
                                   'uniformOut',0);
                               
        elseif strcmp(Led{2},'even')
            % loop through alternating structs and get alternate trials
            ledSubStructs = cellfun(@(x) x(:,2:2:end), ...
                                alternatingStructs, 'uniformOut',0);
                            
            nonLedSubStructs = cellfun(@(x) x(:,1:2:end),...
                                   alternatingStructs,...
                                   'uniformOut',0);
        end
        
                               
        % create an ledExp and a non ledExp by copy and replace the
        % alternating fields with the ones we just calculated above
        ledExp = imExp;
        ledExp.stimulus = ...
            ledSubStructs{strcmp(fieldsToAlternate,'stimulus')};
        
        % as before behavior may not be in the imExp and so we check
        if isfield(imExp,'behavior');
            ledExp.behavior =...
                ledSubStructs{strcmp(fieldsToAlternate,'behavior')};
        end
        
        ledExp.correctedStacks =...
            ledSubStructs{strcmp(fieldsToAlternate,'correctedStacks')};
        ledExp.stackExtremas =...
            ledSubStructs{strcmp(fieldsToAlternate,'stackExtremas')};
        
        % Do the same for a nonLedExp using nonLed trials calculated above
        nonLedExp = imExp;
        nonLedExp.stimulus = ...
            nonLedSubStructs{strcmp(fieldsToAlternate,'stimulus')};
        
        if isfield(imExp,'behavior');
            nonLedExp.behavior =...
                nonLedSubStructs{strcmp(fieldsToAlternate,'behavior')};
        end
         
        nonLedExp.correctedStacks =...
            nonLedSubStructs{strcmp(fieldsToAlternate,'correctedStacks')};
        nonLedExp.stackExtremas =...
            nonLedSubStructs{strcmp(fieldsToAlternate,'stackExtremas')};
        
        assignin('base','nonLedExp',nonLedExp)
        assignin('base', 'ledExp', ledExp)
        
    case false
        % nothing to do here
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% CREATE SIGNAL MAPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the Led was shown then we need to compute two maps for each roi, an
% ledMap and a nonLedMap. Otherwise a single map is all that is calculated

% We start by defining what stimuli are two dimensional. Currently only the
% simple center surround stimulus is two dimensional (i.e. this requires a
% a special mapper the csMap)
twoDimStimuli = {'Simple Center/Surround'};

% now we will switch the led case. If true then we call the appropriate map
% twice for each roi
switch Led{1}
    case true % Led was shown 
        % If the LED was shown we will determine if the stimVriable is in
        % the imExp.stimulus strucuture and and check whether we need to 
        % call the one dimensional fluorMap or a two dimensional map like 
        % csFluorMap 
        %%%%%%%%%%%%%%%%%%%% CASE SINGLE VARIABLE STIMULUS %%%%%%%%%%%%%%%%
        if isfield(imExp.stimulus(1,1), stimVariable) &&...
                ~any(ismember(twoDimStimuli, stimVariable))
            
            % compute the map for the nonLed trials
            [~, signalMaps{1}, ~] = fluorMap(nonLedExp, stimVariable,...
                                          roiSets,currentRoi, chNumber,...
                                          runState, neuropilRatio);
                                      
            % compute the map for the led trials                         
            [~, signalMaps{2}, ~] = fluorMap(ledExp, stimVariable,...
                                          roiSets,currentRoi, chNumber,...
                                          runState, neuropilRatio);
            % We will also pass as an output the appropriate fluorescence
            % plotter that should be called to plot these maps                          
            plotterType = 'fluorPlotter';
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%% CASE TWO DIMENSIONAL STIMULUS %%%%%%%%%%%%%%%%%%%%%%
        if any(ismember(twoDimStimuli,stimVariable))
             
            % compute the map for the nonLed trials
            [~, signalMaps{1}, ~] = csFluorMap(nonLedExp,...
                                            roiSets,currentRoi, ...
                                            chNumber, runState,...
                                            neuropilRatio);
            % compute the map for the nonLed trials
            [~, signalMaps{2}, ~] = csFluorMap(ledExp,...
                                            roiSets,currentRoi, ...
                                            chNumber, runState,...
                                            neuropilRatio);
                                        
            % We will also pass as an output the appropriate fluorescence
            % plotter that should be called to plot these maps                          
            plotterType = 'csPlotter';
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        
        
    case false
        
        % If the led was not shown then we compute the signals for each roi
        % without regard to led trials using the full imExp. THIS MIGHT
        % NEED TO BE CHANGED SO THE USER CAN PLOT ONLY NON LED TRIALS
        if isfield(imExp.stimulus(1,1), stimVariable) &&...
                ~any(ismember(twoDimStimuli, stimVariable))
            
           [~, signalMaps{1}, ~] = fluorMap(imExp, stimVariable,...
                                          roiSets,currentRoi, chNumber,...
                                          runState, neuropilRatio); 
        % we also set the 2nd element (reserved for led maps) to be []
           signalMaps{2} = {[]};
        
        % We will also pass as an output the appropriate fluorescence
            % plotter that should be called to plot these maps                          
            plotterType = 'fluorPlotter';
         
        end
            
        if any(ismember(twoDimStimuli,stimVariable))
            [~, signalMaps{1}, ~] = csFluorMap(imExp,...
                                          roiSets,currentRoi, chNumber,...
                                          runState, neuropilRatio); 
        % we also set the 2nd element (reserved for led maps) to be []
           signalMaps{2} = {[]};
           
           % We will also pass as an output the appropriate fluorescence
            % plotter that should be called to plot these maps                          
            plotterType = 'CSPlotter';
        end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%assignin('base','signalMaps',signalMaps)
end

