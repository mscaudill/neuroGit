function [subExp] = loadExp(expFileName, varargin)
%loadExp takes a full expFileName (including path) and a list of fields to
% load from the experiment and returns a subExp structure containing only
% the fields specified in varargin
% INPUTS                : expFileName, a fullfile path to an experiment               
%                       : varargin, the fields the user wishes to load
%                         from a specified Exp structure
% OUTPUTS               : subExp, a structure containing only the varargin
%                         fields and values
%
% Explanation: The Exp structure can be very large due to the fact that it
% holds data sampled at a high rate. So we want to only load fields of the
% experiment that are needed at any given time. So this function allows the
% user to specify which fields of the Exp structure to load. This greatly
% enhances the speed of scripts that may call this function rather than
% loading the entire Exp structure
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
%%%%%%%%%%%% LOAD THE SELECTED VARIABLES FROM EXP STRUCT %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subExp = load(expFileName, varargin{:});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

