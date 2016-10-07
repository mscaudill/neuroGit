# neuroGit - A suite of Matlab software packages for Visual Neuroscience. 

STIMULUS-DELIVERY
______

The stimulus-delivery directory contains a gui called StimGen and supporting helper functions for generating and drawing visual stimulus to a monitor. The package creates a trials structure containing all the stimulus information for a particular trial specified by the gui inputs provided by the user. 

<img src=https://github.com/mscaudill/neuroGit/blob/master/stimulus-delivery/StimGenGui/StimGen.PNG height=200, align="left">

The package supports parallel port triggering on the following computer architectures: 32-bit and 64-bit Windows XP and Windows 7. This allows users to engage data acquistions systems with millisecond accuracy. A range of possible stimuli are provided in the stimGenStimuli directory. The framework is modular with expemplary code annotation to aid developers in creating new stimuli.The software is free to use under a public license. If used, please cite this repository. 

DATA-ANALYSIS
_______

*ePhys:* A lightwieght analysis package for cell-attached and whole-cell
recordings from single cells. It supports both matlab DAQ and axoclamp ABF
file types. The gui walks the user through the following processing stages:
- Data Selection
- Filtering - included IIR filters are Butterworth, Chebyshev, and Elliptic
- Spike detection
- Results

<img src=https://github.com/mscaudill/neuroGit/blob/master/data-analysis/ePhys/eExpMaker/ephys.PNG height=200, align="right">

The package works seamlessly integrates with the stimGen visual stimulation
software by joining individual stimulus trials with their corresponding
electrophysiology traces. Finally, the package allows for assesment of
behavior such as running during the trials. This package is free to use
under a public license. If used please cite this repository.



3. A fluorescent imaging package for motion correction and region of interest intensity analysis. Supports all versions of scan image data acquisition
4. An intrinsic imaging package for analyzing hemodynamic flow in response to stimuli. Currently supports only tiff format images
