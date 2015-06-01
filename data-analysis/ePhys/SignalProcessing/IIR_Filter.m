function [ filteredSignal ] = IIR_Filter(signal, filter, samplingFreq,...
                                         varargin)
% IIR_FILTER builds a filter filter function and applies the filter to the
% signal to return a filtered signal
% signal.
% INPUTS: signal:                   an n-element sequence
%         filter:                   filter from the list [No Filter
%                                   Butterworth, 
%                                   Chebyshev_I, or Elliptic]
%         samplingFreq:             frequency which data was sampled (Hz)
%         varargin:
%               
%               type:               filter type from the list [low, high,
%                                   bandpass]
%               cutOffFreq:         a scalar for types (low,high) or
%                                   2-elem. array if type = bandpass
%               order:              order of the filter (n+1) taps
%               passBandRipple:     peak to peak passband ripple (dB)
%               stopBandRipple:     ripple in the stop band (dB)
%
% OUTPUTS: a filtered signal array
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
%%%%%%%%%%%%%%%%%%%%%%%%%%% BUILD INPUT PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The input parser will allow the user to call one of the IIR filters
% designed in this function using default values listed below OR allow the
% user to input these values directly into varargin. This makes the
% function flexible enough to handle different numbers of inputs since each
% of the IIR filters has different variable requirements

% Construct parser object
p = inputParser;

%%%%%%%%%%%%%%%%%%%%%%%% ADD REQUIRED ARGS TO PARSER %%%%%%%%%%%%%%%%%%%%%%
% add the required signal input to the parser
addRequired(p,'signal',@isnumeric);

% define the expected required filter choices
expectedFilters = {'No Filter','Butterworth', 'Chebyshev_I', 'Elliptical'};

% check that the user inputted filter matches one of the expected filters
addRequired(p,'filter',@(x) any(validatestring(x,expectedFilters)));

% add the required samplingFrequency
addRequired(p, 'samplingFreq',@isnumeric)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% ADD VARARGS TO PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Based on the filter choice, a different number of inputs will be needed
% so we will set the defaults for each filter choice in a switch-case
% structure
switch filter
    case 'No Filter'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % simply call the input parser
        parse(p, signal, filter, samplingFreq, varargin{:})
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 'Butterworth' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % The Butterworth filter function call is [z, p, k] = butter(order,
        % normalized_cutoff_freq, type); We need to supply defaults here
        % in case they are missing in the input arguments
        
        % DEFAULT ORDER OF 5
        defaultOrder = 5;
        %check that the user has entered a numeric value for the order
        addParamValue(p,'order',defaultOrder,@isnumeric);
        
        % DEFAULT TYPE TO BANDPASS
        defaultType = 'bandpass';
        % check that the user has selected a valid passband
        expectedTypes = {'low', 'high', 'bandpass'};
        % check that the type matches one of the expected types (low, high, band)
        addParamValue(p,'type',defaultType,...
                 @(x) any(validatestring(x,expectedTypes)));
             
        % DEFAULT CUTOFFS
        defaultCutOffFreq = [300, 3000];
        % Make sure the user has entered an array of the correct length
        addParamValue(p,'cutOffFreq', defaultCutOffFreq, @(x) numel(x)<=2);
        
        parse(p, signal, filter, samplingFreq, varargin{:})
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 'Chebyshev_I' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % The Chebyshev_I filter function call is [z, p, k] = cheby1(order, 
        % passBandRipple, normalizedCutOffFreq, type). These filters allow
        % for ripple in the passband and thus shorten the transition width
        % of the filter. So we must add the passband ripple if the user has
        % selected this filter function
        
        % DEFAULT ORDER OF 5
        defaultOrder = 5;
        %check that the user has entered a numeric value for the order
        addParamValue(p,'order',defaultOrder,@isnumeric);
        
        % DEFAULT TYPE TO BANDPASS
        defaultType = 'bandpass';
        % check that the user has selected a valid passband
        expectedTypes = {'low', 'high', 'bandpass'};
        % check that the type matches one of the expected types (low, high, band)
        addParamValue(p,'type',defaultType,...
                 @(x) any(validatestring(x,expectedTypes)));
             
        % DEFAULT CUTOFFS
        defaultCutOffFreq = [300, 3000];
        % Make sure the user has entered an array of the correct length
        addParamValue(p,'cutOffFreq', defaultCutOffFreq, @(x) numel(x)<=2);
        
        defaultPassbandRipple = 3;
        % Now add the users entry or the default value to the parser
        addParamValue(p, 'passBandRipple', defaultPassbandRipple,...
                      @isnumeric);
        %call the input parser.
        parse(p, signal, filter, samplingFreq, varargin{:})
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 'Elliptic' %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Elliptic filters are a generalization of Butteworth and Chebyshev
        % filters in that they allow for ripples in both the pass band and
        % the stopband (Chebyshev type II does this). This allows the
        % transition width to be much shorter. The function cal to this
        % filter is [z,p,k] = ellip(order ,passBandRipple, stopBandRipple,
        % cutOffFreq,filterType) 
        
        % DEFAULT ORDER OF 5
        defaultOrder = 5;
        %check that the user has entered a numeric value for the order
        addParamValue(p,'order',defaultOrder,@isnumeric);
        
        % DEFAULT TYPE TO BANDPASS
        defaultType = 'bandpass';
        % check that the user has selected a valid passband
        expectedTypes = {'low', 'high', 'bandpass'};
        % check that the type matches one of the expected types (low, high, band)
        addParamValue(p,'type',defaultType,...
                 @(x) any(validatestring(x,expectedTypes)));
             
        % DEFAULT CUTOFFS
        defaultCutOffFreq = [300, 3000];
        % Make sure the user has entered an array of the correct length
        addParamValue(p,'cutOffFreq', defaultCutOffFreq, @(x) numel(x)<=2);
        
        defaultPassBandRipple = 3;
        % Now add the users entry or the default value to the parser
        addParamValue(p, 'passBandRipple', defaultPassBandRipple,...
                      @isnumeric);
        defaultStopBandRipple = 40;
        % Now add the users entry or the default value to the parser
        addParamValue(p, 'stopBandRipple', defaultStopBandRipple,...
                      @isnumeric);
        %call the input parser.
        parse(p, signal, filter, samplingFreq, varargin{:})
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%%%%%%%%%%%%%%%%%%% EXTRACT FROM PARSER REQUIRED INPUTS %%%%%%%%%%%%%%%%%%%
signal = p.Results.signal;
filter = p.Results.filter;
samplingFreq = p.Results.samplingFreq;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT FILTERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that we have all the inputs availabe from the input parser, we can
% construct the filter that the user has chosen.

% Each of the three IIR filters requires a normalized cuttoff Freq. The
% normaliztion factor is the nyquist frequency
 nyquistFreq = samplingFreq/2;
 
 % Now we will use a switch case structure that will build the filter
 % supplied in the arguments of IIR_filter
 switch filter
     case 'No Filter'
         filteredSignal = signal;
         
    case 'Butterworth'
        [b,a] = butter(p.Results.order,...
                       p.Results.cutOffFreq/nyquistFreq, p.Results.type);
        filteredSignal = filtfilt(b, a, zeroMean(signal));
        
     case 'Chebyshev_I'
         [b,a] = cheby1(p.Results.order, p.Results.passBandRipple,...
                        p.Results.cutOffFreq/nyquistFreq, p.Results.type);   
        filteredSignal = filtfilt(b, a, zeroMean(signal));
        
     case 'Elliptic'
         [b,a] = ellip(p.Results.order, p.Results.passBandRipple,...
                       p.Results.stopBandRipple,...
                       p.Results.cutOffFreq/nyquistFreq, p.Results.type);
        filteredSignal=filtfilt(b,a,zeroMean(signal));
 end        
% Hd = dfilt.df2tsos(sos,g); 
% h = fvtool(Hd);	             % Plot magnitude response
% set(h,'Analysis','freq')	     % Display frequency response
% scale = max(signal)/max(filteredSignal);

% plot(time, scale*filteredSignal,'b', time, zeroMean(signal), 'r');
% min(scale*filteredSignal)
% set(gca, 'ylim', ([-scale*max(abs(filteredSignal))-.2*scale*max(abs(filteredSignal)) scale*max(abs(filteredSignal))]));
end

