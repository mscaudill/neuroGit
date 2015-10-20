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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA DIRS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Raw data and stimulus directories (prior to eExp creation)
eDirInfo.DaqFileLoc = 'A:\MSC\Data\CSproject\rawData\';
eDirInfo.StimFileLoc = 'A:\MSC\Data\CSproject\stimuli\';
eDirInfo.rootDirLoc = 'A:\MSC\Data\CSproject\';

%%%%%%%%%%%%%%%%%%%%% CELL ATTACHED DIRS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% root dir of cell attached containing dirs for raw and analyzed
% cell-attached exps
eDirInfo.cellAttachedElectroExpFileLoc = ...
            'A:\MSC\Data\CSproject\cellAttachedExps\';

% Cell attached raw data directory (post eExp creation)
eDirInfo.cellAttElectroExpRawFileLoc = ...
             'A:\MSC\Data\CSproject\cellAttachedExps\rawElectroExps\';
% Cell attach analyzed data directory (post eExp analysis)            
eDirInfo.cellAttElectroExpAnalyzedFileLoc = ...
             'A:\MSC\Data\CSproject\cellAttachedExps\analyzedElectroExps\';
         
%%%%%%%%%%%%%%%%%%%%%%%%%% WHOLE-CELL DIRS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
% root whole-cell directory containing dirs for both vclamp and iclamp exps
eDirInfo.wholeCellElectroExpFileLoc = ...
            'A:\MSC\Data\CSproject\WholeCellExps';
        
%%% VCLAMP EXPS %%%
% vclamp post eExp creation       
eDirInfo.wholeCellElectroExpVclampRawFileLoc = ...
            'A:\MSC\Data\CSproject\WholeCellExps\Vclamp\';
% vclamp eExp post analysis
eDirInfo.wholeCellElectroExpVclampAnalyzedFileLoc = ...
            'A:\MSC\Data\CSproject\WholeCellExps\Vclamp_analyzed\';

%%% ICALMP EXPS %%%
% Iclamp post eExp creation       
eDirInfo.wholeCellElectroExpIclampRawFileLoc = ...
            'A:\MSC\Data\CSproject\WholeCellExps\Iclamp\';
% vclamp eExp post analysis
eDirInfo.wholeCellElectroExpIclampAnalyzedFileLoc = ...
            'A:\MSC\Data\CSproject\WholeCellExps\Iclamp_analyzed\';
        
        
            
eDirInfo.RoughFigLoc = 'G:\data\RoughFigs\';

