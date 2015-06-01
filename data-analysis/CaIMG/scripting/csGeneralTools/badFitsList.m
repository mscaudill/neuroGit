% This script holds a listing of cells that have poor double gaussian fits
% and must be exluded from the tuning analysis. These list are for cells in
% the following imExps_analyzed

%04232013s3
%60602013s7
%06072013s1
%07122013s3
%07162013s4
%07162013s5
%07192013s4
%07192013s5
%07192013s6

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% CREATE EXCLUSION LISTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
centerExclusions = ...
    [41,40,39,38,35,34,33,32,31,30,29,26,25,24,23,22,19,13,10,6];
surroundExclusions = ...
    [40,36,35,33,27,26,25,24,23,21,19,17,16,12,11,10,9,5,3,2];

commonExclusionList = unique([centerExclusions,surroundExclusions]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%