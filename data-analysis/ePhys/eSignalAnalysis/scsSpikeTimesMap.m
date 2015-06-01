function [ returnMap ] = scsSpikeTimesMap( spikeIndices, stimulus,...
                                           ledCond, fileInfo, behavior,...
                                           runstate )
% scsSpikeTimesMap constructs a map object keyed on surround condition and
% containing the spike times for each condition. Note this means it only
% works for a single center angle. The surround conditions are {center
% alone, cross1, cross2, Iso, surround alone, blank (if exist)} with
% corresponding condition numbers 1 to 6 (or 5 if no blank).
%
% INPUTS                        :spikeIndices, a substructure of electroExp
%                                containg the detected spike indices
%                               :stimulus, a substructure frm electroExp
%                                containg all the stimulus information
%                               :ledCond, a substructure from electroExp
%                                contating LED ON/OFF binary
%                               :fileInfo, substructure from electroExp
%                                containg fileInfo such as sampleRate
%                               :behavior, substructure from electroExp
%                                containing animal running condition
%                               : runState, an integer deterimining whether
%                                the map should include only running trials,
%                                non-running trials or both (1, 0, 2) 
%                                respectively
% OUTPUTS                       : returnMap, a map object keyed on stimulus
%                                surround condition containing the
%                                spikeTimes of the cell for each trial
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
end

