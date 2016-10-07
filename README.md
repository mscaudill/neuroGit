# neuroGit - A suite of Matlab software packages for Visual Neuroscience. 

STIMULUS-DELIVERY
______
The stimulus-delivery directory contains a gui (stimGen) and supporting helper functions for generating and drawing visual stimulus to a monitor. The package creates a trials structure containing all the stimulus information for a particular trail specified by the gui inputs provided by the user. The package supports parallel port triggering on the following computer architectures: 32-bit and 64-bit Windows XP and Windows 7 to allow users to engage data acquistions systems with millisecond accuracy. A range of possible stimuli are provided in the stimGenStimuli directory. The framework is modular with expemplary code annotation to aid developers in creating new stimuli.
<img src=https://github.com/mscaudill/neuroGit/blob/master/stimulus-delivery/StimGenGui/StimGen.PNG height=100, align="center">
 


1. A visual stimulus generation package (stimGen) for drawing a variety of visual stimuli to a monitor.


2. An electrophysiology analysis package that works with both Matlab daq and Axoclamp abf file types. Supports data collected in cell-attached and whole-cell recording modes. Offers filtering, spike extraction, various intracellular metrics etc.
3. A fluorescent imaging package for motion correction and region of interest intensity analysis. Supports all versions of scan image data acquisition
4. An intrinsic imaging package for analyzing hemodynamic flow in response to stimuli. Currently supports only tiff format images
