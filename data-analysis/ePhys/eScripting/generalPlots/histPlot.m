function [hHist] = histPlot(plotMetric , inputMatrix, runState, varargin)
% histPlot creates a publication ready histogram plot from the
% columns of the input matrix. Each column is a unique data set sent to
% histogram.
% INPUTS                      : plotMetric  the type of data being plotted
%                               currently the acceptable inputs are {'OSI',
%                               'DSI','HWHM'}
%                             : inputMatrix, a matrix of data organized
%                               column-wise
%                : varargin
%                             : Names, a cell array of names corresponding
%                               to each column in the input Matrix
%                             : bins
%                             : save
%
% OUTPUTS                     : hHist, a handle to the histogram object
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
% CONSTRUCT PARSER
parser = inputParser;

% SET DEFAULTS
% set the cell array of acceptable plotMetrics
acceptableMetrics = {'OSI', 'DSI', 'HWHM'};
% set default bins to empty and let matlab auto set the bins
defaultBins = [];
% set default values for the options under varargin (saveOption, normalize)
defaultSave = true;


% VALIDATION FUNCTIONS
validateMetric = @(x) sum(strcmp(x,acceptableMetrics));

% ADD REQUIRED INPUTS
addRequired(parser,'plotMetric', validateMetric);
addRequired(parser,'inputMatrix', @isnumeric);

% ADD PARAMETER INPUTS
addParamValue(parser,'bins', defaultBins, @isnumeric)
addParamValue(parser, 'save', defaultSave, @islogical);

% CALL THE PARSE FUNCTION TO PARSE INPUTS
parse(parser, plotMetric, inputMatrix, varargin{:})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bins = parser.Results.bins;

if ~isempty(bins)
    hist(inputMatix, bins)
else
    hist(inputMatrix)
end

switch plotMetric
    case 'OSI'
        popTitle = ['Direction Selectivity:', ' Running State is  '...
                    num2str(runState)];

end

