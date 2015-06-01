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
function table = ExpMakerFilterTable( filter, dataType )
%This is a helper function for the ExpMaker gui. It will populate the
%filter table options in the filter panel under the filter stage of
%processing. The size of the table will be determined by the filter type.
%We will use a switch case to change the filter table depending on user
%selection

% We also use a switch for the chs since the abf and daq are set to use
% different chs for the voltage readings
switch dataType
    case 'daq'
        chNumToFilt = [2];
    case 'abf'
        chNumToFilt = [1];
end

switch filter
    case 'No Filter'
        table = {'Filter Chs', chNumToFilt};
                 
    case 'Butterworth'
        table = {'Filter Chs', chNumToFilt, [];...
                'Order', 5, [];...
                'Type', 'high', [];...
                'Cut-off Freq(s) (Hz)', 300, []};
             
    case 'Chebyshev_I'
        table = {'Filter Chs', chNumToFilt, [];...
                'Order', 5, [];...
                'Type', 'high', [];...
                 'Cut-off Freq(s) (Hz)', 300, [];...
                'Pass-band Ripple (dB)', 3, []};
             
   case 'Elliptic'
        table = {'Filter Chs', chNumToFilt, [];...
                'Order', 5, [];...
                'Type', 'high', [];...
                'cut-off Freq(s) (Hz)', 300, [];...
                'Pass-band Ripple (dB)', 3, [];...
                'Stop-band Ripple (dB)', 40, []};
end


end

