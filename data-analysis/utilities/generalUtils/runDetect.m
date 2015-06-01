function [ boolean ] = runDetect( signal, dc_offset, threshold, ...
                                      percentage )
%runDetect determines if a signal is above a threshold for more than a
%percentage of the length of signal. A binary value is then assigned as the
%output
%INPUTS
%       signal          : an n-element sequence
%       dc_offset       : dc component to remove from signal
%       threshold       : threshold value to be applied to signal
%       percentage      : percentage of signal that is above threshold
%OUTPUTS
%       boolean         : true or false (1 or 0)

if (sum(signal-dc_offset-threshold>0)/numel(signal))> percentage/100;
    boolean = 1;
else
    boolean = 0;
end


end

