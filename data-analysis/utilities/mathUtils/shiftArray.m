function [shiftedArray] = shiftArray(array, varargin)
% shiftArray finds the index of the maximum in array and shifts the maximum
% to the index indicated by shiftIndex
% INPUTS
%                   array               : an n-element sequence
%                   varargin                  
%                       shiftIndex      : an integer amount to shift, ...
%                                         defaults to shift to center of...
%                                         array
% OUTPUTS           shiftedArray        : n-element sequence shifted 
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inputParseStruct = inputParser;
% set default values for the options under varargin (saveOption, normalize)
defaultShiftIndex = floor(numel(array)/2);

% Add all requried and optional args to the input parser object
addRequired(inputParseStruct,'array',@isnumeric);
addParamValue(inputParseStruct,'shiftIndex',defaultShiftIndex,@isnumeric);

% call the parser
parse(inputParseStruct,array,varargin{:})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[~, maxIndex] = max(array);
deltaIndices = inputParseStruct.Results.shiftIndex - maxIndex;

shiftedArray = circshift(array, [0,deltaIndices]);