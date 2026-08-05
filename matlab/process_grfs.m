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
GRF_CUTOFF = 1;

% Low-pass parameters
CUTOFF_FREQUENCY = 6; %Hz
FILTER_ORDER = 4; %th order

C3D_FILE = fullfile(INPUT_PATH,strcat(TRIAL,'.c3d'));
fprintf("Input File: %s\n",C3D_FILE);
fprintf("Output Path: %s\n", OUTPUT_PATH);
%% C3D Loading
[c3d, all_pf] = ezc3dRead(convertStringsToChars(C3D_FILE));
fprintf("C3D file loaded! Found %d points.\n", c3d.parameters.POINT.USED.DATA);

%% Marker Extraction - TRIAL_markers.trc file
marker_file = fullfile(OUTPUT_PATH, strcat(TRIAL,MARKERS_SUFFIX));
point_frequency = c3d.parameters.POINT.RATE.DATA;
point_units = c3d.parameters.POINT.UNITS.DATA{1};
% Build header
point_columns = string(c3d.parameters.POINT.LABELS.DATA);
% Get data
points = c3d.data.points;
[status, output] = writeMarkerTrcFile(points, point_frequency, point_units,...
    point_columns, INPUT_PATH, marker_file,  rotm);
fprintf("Status: %d\n%s", status, output);
fprintf("[SUCCESS] wrote file: %s\n", marker_file);

%% Analog Extraction - TRIAL_analog.sto file
analog_file = fullfile(OUTPUT_PATH, strcat(TRIAL,ANALOGS_SUFFIX));
analog_frequency = c3d.parameters.ANALOG.RATE.DATA;
% Build header
analog_columns = string(c3d.parameters.ANALOG.LABELS.DATA);
% Get data
analogs = c3d.data.analogs;

[status, output] = writeStoFile(analogs,analog_frequency,analog_columns,analog_file);
fprintf("Status: %d\n%s", status, output);
fprintf("[SUCCESS] wrote file: %s\n", analog_file);

%% GRF Extraction - TRIAL_grfs.sto file
grf_file = fullfile(OUTPUT_PATH, strcat(TRIAL,GRFS_SUFFIX));

% Mapping from analog channel name to GRF name expected in OpenSim
% [name in file, result key, index]
grf_mapping = [
    [strcat("Force.Fx",FP_L),"L_ground_force_vx",0]
    [strcat("Force.Fy",FP_L),"L_ground_force_vy",0]
    [strcat("Force.Fz",FP_L),"L_ground_force_vz",0]
    ["","L_ground_force_px",0]
    ["","L_ground_force_py",0]
    ["","L_ground_force_pz",0]
    [strcat("Moment.Mx",FP_L),"L_ground_torque_x",0]
    [strcat("Moment.My",FP_L),"L_ground_torque_y",0]
    [strcat("Moment.Mz",FP_L),"L_ground_torque_z",0]
    [strcat("Force.Fx",FP_R),"R_ground_force_vx",0]
    [strcat("Force.Fy",FP_R),"R_ground_force_vy",0]
    [strcat("Force.Fz",FP_R),"R_ground_force_vz",0]
    ["","R_ground_force_px",0]
    ["","R_ground_force_py",0]
    ["","R_ground_force_pz",0]
    [strcat("Moment.Mx",FP_R),"R_ground_torque_x",0]
    [strcat("Moment.My",FP_R),"R_ground_torque_y",0]
    [strcat("Moment.Mz",FP_R),"R_ground_torque_z",0]
    ];

grf_columns = grf_mapping(:,2);

% Find the indexes for the GRF keys
for i = 1:length(analog_columns)
    analog_label = analog_columns(i);
    for j = 1:length(grf_mapping)
        if grf_mapping(j) == analog_label
            grf_mapping(j,3) = i;
            break;
        end
    end
end

% Low-pass filter raw signals
normalized_cutoff = CUTOFF_FREQUENCY / (analog_frequency / 2);
[b, a] = butter(FILTER_ORDER, normalized_cutoff, 'low');

fp_active = [FP_L, FP_R];
num_inputs = sum(count(grf_mapping(:,1),FP_L));
num_outputs = length(grf_mapping)/ length(fp_active);
grf_filtered = zeros(length(analogs), num_inputs * length(fp_active));

grf_index = 1;
for i = 1:length(grf_mapping)
    index = str2double(grf_mapping(i,3));
    if index > 0
        grf_filtered(:,grf_index) = filtfilt(b, a, analogs(:,index));
        grf_index = grf_index + 1;
    end
end

% Re-calculate COP from analog force and moment signal
grfs_final = zeros(length(analogs), length(grf_mapping));
for j = 1:numel(fp_active)
    fp_index = fp_active(j);
    fp = all_pf(str2double(fp_index));
    stride_in = (j-1)*num_inputs;

    data = grf_filtered(:, 1+stride_in: num_inputs+stride_in);

    stride_out =  (j-1)*num_outputs;
    grfs_final(:, 1+stride_out: num_outputs+stride_out) = ...
        calculateFpGrf(data,fp,rotm,GRF_CUTOFF);
end
% Write the sto file
[status, output] = writeStoFile(grfs_final,analog_frequency,grf_columns,grf_file);
fprintf("Status: %d\n%s", status, output);
fprintf("[SUCCESS] wrote file: %s\n", grf_file);