%% C3D Extraction and Processing
% Ensure the ezc3d library is on the MATLAB path!
clear;
%% Setup - Change these parameters for your own data

% Path Initialization - OS independent
% On Windows® platforms, the file separator character is a backslash (\).
% On other platforms, the file separator might be a different character.
HOME = getenv("HOME");
DATASET_PATH = fullfile(HOME,"data","kuopio-full-body-dataset","s01_raw");
OUTPUT_DIR = fullfile(HOME,"data","kuopio-full-body-dataset-results","s02_extracted");

PARTICIPANT = '09';
MOCAP_SUBDIR = 'mocap';
TRIAL = 'jogging';

% Files will be named TRIAL+SUFFIX
MARKERS_SUFFIX = "_markers.trc";
ANALOGS_SUFFIX = "_analog_custom.sto";
GRFS_SUFFIX = "_grfs_custom.sto";
GRFS_WRONG_SUFFIX = "_grfs_wrong.sto";

INPUT_PATH = fullfile(DATASET_PATH, PARTICIPANT, MOCAP_SUBDIR);
OUTPUT_PATH = fullfile(OUTPUT_DIR, PARTICIPANT);
if ~exist(OUTPUT_PATH, 'dir')
    mkdir(OUTPUT_PATH)
end

% Mapping from laboratory frame to OpenSim frame
MARKER_ROTATIONS = [-pi/2, pi/2, 0];
% Rotate points to OpenSim frame
% [0,-1,0]
% [0, 0,1]
% [-1,0,0]
rotm = eulang2rotmat(MARKER_ROTATIONS,'XZY');

% Force Plate (FP) indexes for the left and right foot.
FP_L = '4';
FP_R = '5';
GRF_CUTOFF = 2; %N

% Low-pass parameters
CUTOFF_FREQUENCY = 6; %Hz
FILTER_ORDER = 2; % forward backward filtering doubles it (so 2 = 4th order)

C3D_FILE = fullfile(INPUT_PATH,strcat(TRIAL,'.c3d'));
fprintf("Input File: %s\n",C3D_FILE);
fprintf("Output Path: %s\n", OUTPUT_PATH);
%% C3D Loading
[c3d, all_pf] = ezc3dRead(convertStringsToChars(C3D_FILE));
fprintf("C3D file loaded! Found %d points.\n", c3d.parameters.POINT.USED.DATA);

%% Marker Extraction - TRIAL_markers.trc file
marker_file = fullfile(OUTPUT_PATH, strcat(TRIAL,MARKERS_SUFFIX));
fprintf("Starting on file: %s\n", marker_file);
[status, output] = extractMarkers(c3d, marker_file, INPUT_PATH, rotm);
fprintf("Status: %d\n%s", status, output);

%% Marker Extraction - static_cal_markers.trc file
static_cal_trial = "static_cal";
marker_file = fullfile(OUTPUT_PATH, strcat(static_cal_trial,MARKERS_SUFFIX));
fprintf("Starting on file: %s\n", marker_file);
[status, output] = extractMarkers(c3d, marker_file, INPUT_PATH, rotm);
fprintf("Status: %d\n%s", status, output);

%% Analog Extraction - TRIAL_analog.sto file
analog_file = fullfile(OUTPUT_PATH, strcat(TRIAL,ANALOGS_SUFFIX));
fprintf("Starting on file: %s\n", analog_file);
[status, output] = extractAnalogs(c3d,analog_file);
fprintf("Status: %d\n%s", status, output);

%% GRF Extraction - TRIAL_grfs.sto file
grf_file = fullfile(OUTPUT_PATH, strcat(TRIAL,GRFS_SUFFIX));
fprintf("Starting on file: %s\n", grf_file);
[status, output] = extractGrfs(c3d, all_pf, grf_file, rotm, ...
    FP_L, FP_R, FILTER_ORDER, CUTOFF_FREQUENCY, GRF_CUTOFF);
fprintf("Status: %d\n%s", status, output);

%% GRF Extraction - TRIAL_grfs_wrong.sto file
grf_file = fullfile(OUTPUT_PATH, strcat(TRIAL,GRFS_WRONG_SUFFIX));
fprintf("Starting on file: %s\n", grf_file);
[status, output] = extractGrfsWrong(c3d, all_pf, grf_file, rotm, ...
    FP_L, FP_R, FILTER_ORDER, CUTOFF_FREQUENCY, GRF_CUTOFF);
fprintf("Status: %d\n%s", status, output);