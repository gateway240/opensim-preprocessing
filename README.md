# opensim-preprocessing
This repository will help you pre-process your motion capture data for use in OpenSim. You DO NOT need to have the OpenSim package installed or configured to use these scripts. This repository is for PREPARING your data for use in OpenSim and does not require OpenSim as a dependency.

OpenSim currently only support 3rd-order Butterworth low-pass filtering. With these simple processing scripts, you can apply any filter of any order to existing OpenSim `.mot` and `.sto` data files. Additionally, these scripts provide an easy and customizable way to properly apply low-pass filtering to your ground reaction force data. 

The [ezc3d](https://github.com/pyomeca/ezc3d/) library is excellent for `.c3d` file processing and it must be installed prior to running the processing scripts.

The [Kuopio Full-Body Dataset](https://doi.org/10.5281/zenodo.17826877) contains motion trials which have been tested with these scripts.

# MATLAB
MATLAB testing and processing has been developed and tested on Linux with MATLAB 2026a but should work with other OS and platform combinations.

## Environment Setup

1. Install MATLAB for your OS
2. Install the `Signal Processing Toolbox by MathWorks` in MATLAB for low-pass filtering
3. Download the [ezc3d MATLAB package](https://github.com/pyomeca/ezc3d/releases) for your OS
4. Unzip the folder, and add it to the MATLAB path (`Home`->`Set Path`->`Add Folder` & click `Save path for future sessions`).
5. Set the parameters in `matlab/process_c3d_trial.m` and run it!


# Python
WIP