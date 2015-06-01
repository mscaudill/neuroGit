function [ crossings ] = thresholdDetect( signal, thresholdType, threshold)
% thresholdDetect locates where a siganl crosses a threshold. It locates
% both upward and downward going crossings by loooking for a sign change in
% the quantity (signal-threshold). It is written as a vectorized code to
% optimize speed.
% INPUTS:       Signal, an n-element sequence
%               Threshold, a double multiplier of the std of signal
% OUTPUTS:      a cell array of tuples containing the upward and downward
%               crossings
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

% The user may choose between SD and fixed thresholds. We implement with a
% switch
switch thresholdType
    case 'Standard Dev'
        % compute the threshold in as a factor of the standard deviation of
        % the input signal
        threshold = threshold*std(signal);
    case 'Fixed'
        threshold = threshold;
end

% Compute the thresholded signal to look for sign changes
threshedSignal = signal-threshold;

% Now locate the crossings by looking for where consecutive elements of
% signal change sign (i.e. their product is negative)
crossings = find(threshedSignal.*circshift(threshedSignal,1) < 0);

% Now pair the upward and downward corssings into a cell array
% First reshape the array into a two column array where the first column
% contains upward crossings and the second contains downward crossings
crossings = reshape(crossings,2,[])';
% combine the upward and downward crossings into each element of the cell
% array (i.e. along dimension 2)
crossings = num2cell(crossings,2);

end

