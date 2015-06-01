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

This file outlines the setup steps for using the Stimulus generation 
package stimGen:

After installing tortoise subversion. Please go to 
https://code.google.com/p/mouse-electrophysiology-project/source/checkout
to make a fresh checkout of code

1. Place Stimulus-delivery directory in the Matlab path
___________________________________________________________________________
2. Cd into the RigSpecific directory
3. Edit monitorInformation to match your rig's visual stimuluation monitor
___________________________________________________________________________
4. Create a shared stimulus folder on your Daq PC
___________________________________________________________________________
5. Cd into RigSpecificInfo and Edit dirInformation.m
6. Change the save to drive location to the shared stimulus drive name from
   step 4
7. Enter a local backup copy save location. This will be saved locally on 
   visual stim PC
___________________________________________________________________________
8. Engage the parallel port in each of the stimulus 
   files by uncommenting a line under the section heading parallel port 
   trigger
___________________________________________________________________________
9. Edit stimGen gui and change the user initials in the function 
   StimGen_OpeningFcn to your user initials
___________________________________________________________________________
10. Install the psychophysics toolbox: 
http://psychtoolbox.org/PsychtoolboxDownload
___________________________________________________________________________
11. Install GStreamer:
http://gstreamer.freedesktop.org/