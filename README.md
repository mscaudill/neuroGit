# neuroGit -  A suite of Matlab© packages for visual neuroscience. 

This software is free to download and use under a public license. If used, please cite: Caudill M.S., neurogit, (2013), GitHub repository, https://github.com/mscaudill/neurogit

## STIMULUS-DELIVERY
______

**STIMGEN:**

StimGen is a visual stimulation package capable of drawing
complex visual stimuli to a set of monitors with millisecond timing
accuracy. The package utilizes Matlab's abstract structure array data type
to store all the parameters of a visual stimulus. The structure arrays can
be tagged with a user specified name to facilitate data processing.

<img src=https://github.com/mscaudill/neuroGit/blob/master/stimulus-delivery/StimGenGui/StimGen.PNG height=250, align="left">

Further, the package supports parallel port triggering on the following computer architectures: 32-bit and 64-bit Windows XP and Windows 7. This allows users to initiate a cascade of data acquistions sequences with millisecond timing accuracy. A range of possible stimuli are provided in the stimGenStimuli directory. These stimuli are modular and feature  expemplary code annotation to aid developers in creating new stimuli.

## DATA-ANALYSIS
_______

<img src=https://github.com/mscaudill/neuroGit/blob/master/data-analysis/ePhys/eExpMaker/ephys.PNG height=300, align="right">

**EPHYS:** 

Ephys is an electrophysiology analysis package for cell-attached and whole-cell recordings from single cells. It supports both matlab DAQ and axoclamp ABF file types. The software walks the user through the following processing stages:
- Data Selection 
- IIR filtering 
 - Butterworth 
 - Chebyshev
 - Elliptic
- Spike detection
- Results

Ephys seamlessly integrates with the stimGen visual stimulation
software, joining individual stimulus trials with their corresponding
electrophysiology traces. Further, Ephys can accept multiple
hardware channel inputs from matlab and axoclamp data acqutitions devices.
This feature allows users to greatly expand Ephys processing capabilities
by allowing users to sort electrophysiology trials according to various
behavior and physiology signals.

**CAIMG:** 

CAIMG is an extensive package for calcium indicator response analysis. Two
guis and supporting helper functions seamlessly integrate visual stimuli
from the stimGen package with imaging stacks collected using two-photon
microscopy running scan-image software. The guis and the functionality they
provide are:

<img src = https://github.com/mscaudill/neuroGit/blob/master/data-analysis/CaIMG/ImExpMakerGui/imExpMaker.PNG height = 350, align="right">

*imExpMaker*
- Data Selection and Visualization
- Autodetection of missed triggers
- Motion Correction
- Supports separating optogenetic & control trials
- Supports non-imaging data collected from Matlab 'DAQ' or Axoclamp hardware channels.  

*imExpAnalyzer*
- Data Visualization including video playback
- Region of interest (ROI) selection
- Tagging of neuron type
- Fluoresence calculations with neuropil subtraction
- Support for separating calculations of optogenetic and control trials
- Supports separating trials based on behavior and physiology from hardware
  signals

CaImg utilizes Matlab's abstract map container object to store  all the 
stimulus information and the signals for each individual roi. This container 
object makes it easy to carry out further calculations on the fluoresence 
signals from each roi. The package includes numerous scripts that demonstrate
the interaction with the signal map object.

**Intrinsic Imaging**

A package for analyzing hemodynamic flow in response to stimuli. Currently supports only tiff format images.

## DEPENDENCIES:

- Windows XP and greater.
- Matlab version 2013a or greater.
