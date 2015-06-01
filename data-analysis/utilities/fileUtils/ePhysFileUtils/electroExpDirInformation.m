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

% This file contains a dirInfo structure holding directory information used
% for determing where previously recorded data files and stimulus files are 
%located. It also sets where combined data/stim structures (called exps are
%to be saved

eDirInfo.DaqFileLoc = 'A:\MSC\Data\CSproject\rawData\';

eDirInfo.StimFileLoc = 'A:\MSC\Data\CSproject\stimuli\';

eDirInfo.electroExpRawFileLoc = ...
             'A:\MSC\Data\CSproject\cellAttachedExps\rawElectroExps\';
            
eDirInfo.electroExpAnalyzedFileLoc = ...
             'A:\MSC\Data\CSproject\cellAttachedExps\analyzedElectroExps\';
         
eDirInfo.electroExpWholeCellFileLoc = ...
            'A:\MSC\Data\CSproject\WholeCellExps';
            
eDirInfo.RoughFigLoc = 'G:\data\RoughFigs\';

