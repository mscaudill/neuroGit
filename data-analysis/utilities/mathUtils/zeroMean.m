function [ zeroMeanedSignal ] = zeroMean( signal, varargin )
%ZEROMEAN takes an input signal and zero means the signal
% INPUTS      : n-element sequence of points
%           
%      VARARGIN
%               : samplingFreq, sampling Frequency of data
%               : zeroingTime, time over whcih to compute the mean dc offset
% OTPUTS     : zero mean of input signal
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

% We perform a test of the number of variable inputs. If one then zeromean
% using the entire signal, If 4 use only the specified time interval as
% the dc offset. If anything else throw error.
switch numel(varargin)
    case 0 
        zeroMeanedSignal=signal-mean(signal(:));
    case 4
        % Obtain the sampling frequency and validate is scalar
        samplingFreq = varargin{2};
        validateattributes(samplingFreq,{'numeric'} ,{'scalar'})
        
        % obtain the times over which to compute offset and validate is
        % 2-el vector
        zeroingTime = varargin{4};
        validateattributes(zeroingTime,{'numeric'} ,{'size',[1,2]})
        
        % calculate zeroMeanedSignal
        zeroTime = floor(samplingFreq*(zeroingTime(1):zeroingTime(2)));
        zeroMeanedSignal=signal-mean(signal(zeroTime));
    
    otherwise
        % if the user enters anything other than zero or 4 inputs throw
        % error
        error('MathUtiles:zeroMean: requires one or three inputs')
end
    
end

