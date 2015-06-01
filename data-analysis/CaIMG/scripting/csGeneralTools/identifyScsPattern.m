function [responsePattern] = identifyScsPattern(cellTypeOfInterest,...
                                                classification)
%
% identifyScsPattern takes a single classification for an roi from an
% imExp_analyed and maps the five-element classification to a response
% pattern scalar.
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
%
% INPUTS:
%
% OUTPUTS:
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% DETERMINE RESPONSE PATTERN %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here we define our scs pattern classification scheme for pyramidal cells
% and Som cells
% PYRAMIDAL
% [0,0,0,0,0] maps to 1. no response case
% [1,0,0,0,0] maps to 2. center only response case
% [0,(0,1),(0,1),(0,1),0] maps to 3. where pos 2 or 3 must contain a one
% [1,(0,1),(0,1),(0,1),0] maps to 4. where pos 2 or 3 must contain a one
% [(0,1),(0,1),(0,1),(0,1),1] maps to 5. case where surround responds
% [(0,1),0,0,1,0] maps to 6. iso-orientation response only case
%
% SOM
% [0,0,0,0,0] maps to 1. no response case
% [1,0,0,0,0] maps to 2. center only response case
% [(0,1),(0,1),(0,1),0,0] maps to 3. where pos 2 or 3 must contain a one
% [0,(0,1),(0,1), 1,0] maps to 4.
% [1,(0,1),(0,1),1,0] maps to 5. case where surround responds
% [(0,1),(0,1),(0,1),(0,1),1] surround activated

switch cellTypeOfInterest
    case 'pyr'
        if classification(5) == 1
            responsePattern = 5;
            
        elseif sum(classification(:)) == 0;
            responsePattern = 1;
            
        elseif classification(1) == 1 && sum(classification(2:5)) == 0
            responsePattern = 2;
            
        elseif classification(1) == 1 && sum(classification(2:3)) > 0
            responsePattern = 4;
            
        elseif classification(1) == 0 && sum(classification(2:3)) > 0
            responsePattern = 3;
            
        elseif sum(classification(2:3)) == 0 && classification(4) == 1
            responsePattern = 6;
            
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    case 'som'
        if classification(5) == 1
            responsePattern = 6;
            
        elseif sum(classification(:)) == 0;
            responsePattern = 1;
            
        elseif classification(1) == 1 && sum(classification(2:5)) == 0
            responsePattern = 2;
            
        elseif sum(classification(2:3)) > 0 && classification(4) == 0
            responsePattern = 3;
            
        elseif classification(1) == 0 && classification(4) == 1
            responsePattern = 4;
            
        elseif classification(1) ==1 && classification(4) == 1
            responsePattern = 5;
        end
end
            

end

