function [controlMap, meanControlMap, varargout] = ePhysDataMapII( ...
                                       data, stimulus, stimVariables,...
                                       behavior, fileInfo, spikeIndices,...
                                       varargin)
%ePhysDataMap constructs a set of map objects keyed on one or two
%stimVariables for the values data specified in argin. This function
%specifically handles both current and voltage clamp data from a single
%electrode.
%
% INPUTS                    : data, a substructure of a prepared electroExp
%                             containing the voltage/current traces for a
%                             single channel
%                           : stimulus, a substructure frm electroExp
%                             containg all the stimulus information
%                           : stimVariables, a cell array of stimlus
%                             parameters varied in the experiment (not to
%                             exceed two)
%                           : behavior, substructure from
%                             electroExp containing animal
%                             running condition (always present in Exp)
%                           : fileInfo, substructure from electroExp
%                             containg fileInfo such as sampleRate
%                   VARARGIN
%                           : runstate, an integer to determine whether the
%                             map should include runing only trials,
%                             non-running trials, or both
%                             (1,0,2)[DEFAULT=2]
%                           : dataOffSet, dc offset applied globally to all
%                             data, intended for IC where pipette
%                             adjustment was incorrect [DEFAULT 0]
%                           : removeSpikes, logical to remove spikes
%                             [DEFAULT=1]
%                   OUTPUTS
%                           : controlMap, a map object for non-led trials
%                             keyed on the stimulus variables
%                           : meanControlMap, a map object of the mean
%                             signals in control map. If two stimVariables,
%                             the second stimulus variable will be the
%                             variable averaged.
%                           : dataOffset, the data offset user requested
%                   VARARGOUT
%                           : dcOffset, the offset the user requested if ~0
%                           : ledMap, a map of the same dim as control map
%                             but containing LED trials
%                           : meanLedMap, a map of mean signals in led map.
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
%%%%%%%%%%%%%%%%%%%%%%%%% BUILD AN INPUT PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We start by building our variable arg in input parser to define defaults
% for inputs if not specified by user.

% construct a parser object (builtin matlab class)
p = inputParser;

% add the required variables to the parser object and validate
addRequired(p,'data',@isstruct)
addRequired(p,'stimulus',@isstruct)

% add required StimVariables and validate it is a fieldname of the stimulus
% structure
expectedStimVariables = fieldnames(stimulus);

% add required stimVariables and validate that each is one of the expected
% stimVariables
addRequired(p, 'stimVariables',...
        @(x) all(ismember(x,expectedStimVariables)));
   
% add the required behavior structure
addRequired(p,'behavior',@isstruct)

% complete adding the required arguments
addRequired(p, 'fileInfo', @isstruct)

% add the required spikeIndices
addRequired(p,'spikeIndices',@isstruct)

% add the variable input arguments
% add runState argument setting the defualt value to be two.
defaultRunState = 2;
%add the runningState to the params and validate it is numeric
addParamValue(p, 'runState', defaultRunState,@isnumeric)

% add the parameter dataOffset (default is 0mV/pA)
defaultDataOffset = 0; 
addParamValue(p,'dataOffset',defaultDataOffset,@isnumeric)

%add the parameter remove spikes (default is to remove spikes)
defaultRemoveSpikes = true;
addParamValue(p,'removeSpikes',defaultRemoveSpikes,@islogical)

% call the input parser method parse
parse(p, data, stimulus, stimVariables, behavior, fileInfo,spikeIndices,...
         varargin{:})
% and retrieve the variable arguments from the parsed inputs     
runState = p.Results.runState;
dataOffset = p.Results.dataOffset;
removeSpikes = p.Results.removeSpikes;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

