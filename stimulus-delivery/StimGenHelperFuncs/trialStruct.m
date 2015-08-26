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
function [trials] = trialStruct( stimType, table)
% TRIALSTRUCT creates a structure array based on the values from the Gui
% parameter table. The trial structure arrary contains fields that are
% similar to the table strings (white spaces are removed). The number of
% structures in the structure array matches the total number of trials and
% the parameters for each trial can be called out of the structure array
% using trials(i). This command returns a structure for trial number i
% For example lets say you run 12 gratings at 12 orientations and 0 repeats 
% the trial array structure will contain 144 structures. The variable that 
% changes fastest is the one listed last in the Gui table (if no 
% randomization selected). In this case orientation  would vary first then 
% the contrast.
% INPUTS
% STIMTYPE:         STRING SUPPLIED BY STIMGEN GUI
% TABLE:            CELL ARRAY SUPPLIED BY STIMGEN GUI TABLE
%
% OUTPUTS
% TRIALS:   A STRUCTURE ARRAY CONTAINING ALL STIMULUS TRIAL INFO

%%%% TESTING INPUT TABLE (MSC 4-3-12)
% if nargin<1
%   table = {'Spatial Frequency (cpd)', 0.04, .04, 0.04;...
%               'Temporal Frequency (cps)', 3, 1, 3;...
%               'Contrast (start,end,numsteps)', 1, 1, 1;...
%               'Orientation', 0, 30, 330;...
%               'Timing (delay,duration,wait) (s)', 1, 2, 1;...
%               'Blank', 1, [], [];... 
%               'Randomize', 1, [], [];...
%               'Interleave', 1, [], [];...
%               'Interleave Timing', 1, 2, 10;...
%               'Repeats', 0, [], [];...
%               'Initialization Screen (s)', 5, [], []};
%    stimType = 'Full-field Grating';
%   trials = trialStruct(stimType, table);
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% CONSTRUCT FIELDNAMES FOR TRIALSTRUCT  %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First locate all the special characters like (). We will break on these
% to construct the fieldnames of the structure. Fieldnames will follow the
% format 'Spatial_Frequency' etc since spaces are not allowed in fields

% Initialize a structure to hold parameters (see explanantion below)
params = struct();
% Initialize a structure to hold constants
constants = struct();

for i = 1:size(table,1)
    %Find the strings from the 1st column of the table breaking at the '('
    tableStrings{i} = strtok(table{i,1},'(');
    %remove trailing spaces
    tableStrings{i} = strtrim(tableStrings{i});
    %construct a fieldname by replacing the white space with '_'
    fieldname{i} = strrep(tableStrings{i},' ','_');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%CREATE A PARAMETERS AND CONSTANTS STRUCTURE %%%%%%%
    %%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We will create 2 temporary structures. One will hold parameters to be
    % varied and the other will hold constants (we initialized them above
    % because we want to check whether they are empty later)
    
    % RULES FOR VALID PARAMETERS
    % If all columns after the first are numbers and if the numel of a row 
    % in the table >2 and the first and last values are not equal then we 
    % have a parameter to add to the params struct.
    % Note we meed to exclude the timing becasue it does not follow
    % start:step:end AND contrast becasue it will be varied logarithmically
    % not linearly and also does not follow start:step:end but rather
    % start,end,num_steps
    
    % Check if row contains strings, if so store to constants structure
    if ischar([table{i,2:end}])
        constants.(fieldname{i}) = {table{i,2:end}};
        
    % Check if row is the timing row if so add to constants structure    
    elseif strcmp(fieldname{i},'Timing')
        constants.(fieldname{i}) = horzcat(table{i,2:4});
        
    elseif strcmp(fieldname{i}, 'Interleave_Timing')
        constants.(fieldname{i}) = horzcat(table{i,2:4});
        interleaveTiming = horzcat(table{i,2:4});
        
    % Check number of elements in the row if less than 2 add to constants
    elseif numel(cell2mat(table(i,2:end))) <= 2 % 2 element rows
        constants.(fieldname{i}) = horzcat(table{i,2:4});
        
    % Check if row is Contrast row and the check whether start and end vals
    % are the same or the num steps is 1 or less. If so add to constants
    elseif strcmp(fieldname{i},'Contrast') && table{i,2}==table{i,3} ||...
            strcmp(fieldname{i},'Contrast') && table{i,4} <=1
        constants.(fieldname{i}) = table{i,2};
        
    % Else if row is contrast row and start ~= End then add to paramsStruct
    elseif strcmp(fieldname{i},'Contrast') && table{i,2}~=table{i,3} &&...
            table{i,4}>1 % more than one step is needed to be a parameter
        params.Contrast = logspace(log10(table{i,2}),log10(table{i,3}),...
                                    table{i,4});
                                
    % Check whether start and end vals are the same. If so add to constants
    elseif numel(cell2mat(table(i,2:end))) >2 && table{i,2}==table{i,4}
        constants.(fieldname{i}) = table{i,2};
    % Else if start and end not same add to the params structure
    elseif numel(cell2mat(table(i,2:end))) >2 && table{i,2}~=table{i,4}
        params.(fieldname{i}) = table{i,2}:table{i,3}:table{i,4};
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT TRIAL ARRAYS %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If there are parameters to be varied then we need to determine all
% combinations of the parameters, add blank, randomize, interleave and
% possibly repeat trials if the user has selected these options. In this
% section we will get all the parameters from the params structure and
% convert them to an array. We will then find all combinations of the
% parameters in the array using ndgrid, reshape and concatenation. This is
% a faster way than looping through each parameter and is clearer to code.
% Note there may not be any parameters to vary meaning the trials array
% structure will contain only constants. To check whether we have
% parameters we examine whether the fieldnames cell is empty.

% Check to see if the parameters struct is empty
if ~isempty(fieldnames(params))
    %Get the fieldnames present in the parameters sturcture
    params_fields = fieldnames(params);
    % Make a cell array of the arrays in the parameters structure
    for i=1:numel(params_fields);
        params_arrays{i} = params.(params_fields{i});
    end
 
    % Make an array over the numel in the parameters stucture called p
    p = 1:numel(params_fields);
    % if the number of parameters varied is one then simple place this
    % parameter into the trial array
    if numel(p) == 1
        trial_arrays = params_arrays{:}';
    else %If there is more than one parameter we need to get all possible
        % combinations of parameters. We accomplish this by making a full
        % grid for each parameter using ndgrid, then concatenating these
        % and finally reshaping the array
        
        %reverse the order of param fields so the last one is used first
        %since it will change the fastest. this means  the lowest parameter
        %positioned in the table changes fastest. This will be the way of
        %handling which parameters to vary first when they are presented
        %sequentially and not randomly
        ip=p(end:-1:1);
        %use ndgrid to make a full grid over the parameters
        [trial_arrays{ip}] = ndgrid(params_arrays{ip});
        %Now concatenate along the p+1 dim. & make the number of columns of
        %the final matrix p in length
        trial_arrays =...
                reshape(cat(length(p)+1,trial_arrays{:}),[],length(p));
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% ADD BLANK TO TRIAL ARRAY %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % use strcmp to determine if blank is in the input table then append
    % NaN to the parameter array if the blank is present

    if constants.Blank ==1
        trial_arrays(end+1,:) = NaN;
    end
    %note this will make only the parameters being varied NaNs not all the
    %fields in the structure. So if a NaN is present it means that trial
    % was blank

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% RANDOMIZE/INTERLEAVE/REPEAT TRIAL ARRAYS %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We will break the randomize and inerleave into cases. CASE 1:
    % Interleave and NO Randomize. CASE 2: Interleave and Randomize. CASE 
    % 3: Randomize and no interleave. Finally if asked for we repeat.

    % INTERLEAVE AND NO RANDOMIZE
    if constants.Interleave == 1 && constants.Randomize ~= 1
        trial_arrays=sortrows(vertcat(trial_arrays,trial_arrays));
        
        % create a binary LED array to append to trials array (LED is ON
        % if the trial is even
        binaryArray = ones(1,size(trial_arrays,1));
        binaryArray(1:2:end) = 0;
        % append to the last column of trial_arrays
        trial_arrays = [trial_arrays, binaryArray'];
        
    end
    
    % INTERLEAVE AND RANDOMIZE 
    if constants.Interleave == 1 && constants.Randomize == 1
 
       % generate two sets of randomized indexes
       randIndices = [randperm(size(trial_arrays,1));...
                      randperm(size(trial_arrays,1))]';  
       
        % create two randomized trial_arrays
        rand_trial_arrays = trial_arrays(randIndices(:,1),:);
        rand_trial_arraysCopy =  trial_arrays(randIndices(:,2),:);
 
        % now perform interleave using concatenation and reshape
        
        % get the number of columns
        nColumns = size(rand_trial_arrays,2);
        % concatenate the two blocks columnwise then rotate (this
        % interleaves)
        rotated_trial_arrays = [rand_trial_arrays,rand_trial_arraysCopy]';
        
        trial_arrays = reshape(rotated_trial_arrays(:),nColumns,[])';
        
        % create a binary LED array to append to trials array (LED is OFF
        % if the trial is odd
        binaryArray = ones(1,size(trial_arrays,1));
        binaryArray(1:2:end) = 0;
        % append to the last column of trial_arrays
        trial_arrays = [trial_arrays, binaryArray'];
    end

    % RANDOMIZE AND NO INTERLEAVE
    if constants.Randomize == 1 && constants.Interleave ~=1
        randIndex = randperm(size(trial_arrays,1));
        trial_arrays = trial_arrays(randIndex,:);
    end            

    % REPEAT
    if constants.Repeats > 0
        trial_arrays = repmat(trial_arrays,constants.Repeats+1,1);
    end

    %find the trials which have a NaN (ie the blank stim) (for later use)
    blankTrials=find(isnan(trial_arrays(:,1)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% ADD ARRAYS TO TRIAL STRUCTURE %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Make the trials array into a cell array
    trialCell=num2cell(trial_arrays);
    % If we have interleaved then we add the new parameter Led_Condition to
    % the params_fields and fieldname
    if constants.Interleave == 1
        params_fields{end+1} = 'Led';
        fieldname{end+1} = 'Led';
    end
    % Call the funct cell2struct along the 2nd Dimension to make our struct
    trials = cell2struct(trialCell,params_fields,2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% ADD CONSTANTS TO TRIAL STRUCTURE %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Get the fieldnames of the constants struct
constant_fields = fieldnames(constants);
%Now add the constants from the constants structure to the trial structure
for i=1:numel(constant_fields)
    [trials(:).(constant_fields{i})] =...
                                    deal(constants.(constant_fields{i}));
end

% If the trials have been interleaved then the timing on the interleaved
% trials may be different than the timing of the control trials we update
% that timing now. If the trial is ODD we use the standard timing and if
% the trial is EVEN we ust the interleave timing
if constants.Interleave == 1
    [trials(2:2:end).Timing] = deal(interleaveTiming);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% ADD STIMTYPE TO TRIAL STRUCTURE %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Now add stimType to the structure
[trials(:).Stimulus_Type] = deal(stimType);

% For the blank trials we want to set the Stimulus_type to Blank (note
% blanks only exist if a parameter exist so we check for this
if ~isempty(fieldnames(params))
[trials(blankTrials).Stimulus_Type] = deal('Blank'); 
end

% Since we added stimType last reorder the fields of the structure so
% stimType appears first and all other fields appear in the order in which
% they arrive in from the Gui table
trials = orderfields(trials, ['Stimulus_Type',fieldname]);

% clean up the trials structure by removing unneccessary fields
% remove the interleave timing field since its values are stored in timing
if isfield(trials,'Interleave_Timing')
    trials = rmfield(trials, 'Interleave_Timing');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% REPEAT CONSTANT TRIAL STRUCTURE %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If there are no parameters but the user has chosen to repeat the
% stimulus we must increase the trial structure from a 1x1 structure to a
% size of repeats x 1 structure of arrays. So check that there are no
% parameters first then if so repeat the trial structure to the number of
% times the user selected by appending the first trial.
if isempty(fieldnames(params)) && trials.Repeats > 0
    for i=1:trials.Repeats
        trials=[trials;trials(1)];
    end
end
    


