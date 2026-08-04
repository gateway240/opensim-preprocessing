%% C3D Extraction and Processing
% Ensure the ezc3d library is on the MATLAB path!
clear;
%% Path Initialization - OS independent

% On Windows® platforms, the file separator character is a backslash (\).
% On other platforms, the file separator might be a different character.
HOME = getenv("HOME");
DATASET_PATH = fullfile(HOME,"data","kuopio-full-body-dataset","s01_raw");
OUTPUT_DIR = fullfile(HOME,"data","kuopio-full-body-dataset-test","processed");

PARTICIPANT = '09';
MOCAP_SUBDIR = 'mocap';
TRIAL = 'jogging';

OUTPUT_PATH = fullfile(OUTPUT_DIR, PARTICIPANT, MOCAP_SUBDIR);
INPUT_PATH = fullfile(DATASET_PATH, PARTICIPANT, MOCAP_SUBDIR);
if ~exist(OUTPUT_PATH, 'dir')
    mkdir(OUTPUT_PATH)
end

MARKER_ROTATIONS = [-pi/2, pi/2, 0];

% Which force plates correspond to the left and right foot.
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
disp(c3d.parameters.POINT.USED.DATA); % Print the number of points used

%% General Marker Metadata
num_frames = c3d.parameters.POINT.FRAMES.DATA;
num_markers = c3d.parameters.POINT.USED.DATA;
point_frequency = c3d.parameters.POINT.RATE.DATA;
point_labels = c3d.parameters.POINT.LABELS.DATA;
units = c3d.parameters.POINT.UNITS.DATA{1};
point_names = string(point_labels);

fprintf('%% ---- Marker PARAMETERS ---- %%\n');
fprintf('Number of frames = %d\n', num_frames);
fprintf('Number of markers = %d\n', num_markers);
fprintf('Marker frame rate = %d Hz\n', point_frequency);
fprintf('Marker Units = %s\n', units);
fprintf('Marker Names: %s\n', sprintf('%s, ', point_names));
%% Marker Extraction - TRIAL_markers.trc file
MARKER_FILE = fullfile(OUTPUT_PATH, strcat(TRIAL,"_markers.trc"));

mID = fopen(MARKER_FILE,'w');

% Construct the .trc header
fprintf(mID,"PathFileType\t4\t(X/Y/Z)\t%s\n",INPUT_PATH);
fprintf(mID,"DataRate\tCameraRate\tNumFrames\tNumMarkers\tUnits\tOrigDataRate\tOrigDataStartFrame\tOrigNumFrames\n");
fprintf(mID,"%0.6f\t%0.6f\t%d\t%d\t%s\t%0.6f\t%d\t%d\n",point_frequency, point_frequency, num_frames,num_markers,units,point_frequency,0,num_frames);

point_names_header = sprintf('%s\t\t\t', point_names);
fprintf(mID,"Frame#\tTime\t%s\n", point_names_header);

points_index = 1:num_markers;
point_xyz_header = sprintf("X%d\tY%d\tZ%d\t",points_index,points_index,points_index);
fprintf(mID,"\t\t%s\n", point_xyz_header);

% Rotate points to OpenSim frame
% [0,-1,0]
% [0, 0,1]
% [-1,0,0]
rotm = eulang2rotmat(MARKER_ROTATIONS,'XZY');
% disp(rotm)

points = c3d.data.points;
increment = 1.0 / point_frequency;

end_time = increment * num_frames;
time = linspace(0.0,end_time,num_frames);

% Rotate the table
% Apply the transformation to every point (XYZ combo) for all frames
points_out = pagemtimes(rotm, points);

% Output the marker file
for i = 1:num_frames
    % MATLAB uses 1-based indexing :(
    frame = i - 1;
    fprintf(mID,"%d\t%0.16f\t",frame,time(i));
    points_str = sprintf("%0.11f\t",points_out(:,:,i));
    % Remap NaNs to OpenSim compatible nan string
    points_str = strrep(points_str, 'NaN', 'nan');
    fprintf(mID, '%s\n', points_str);
end

fclose(mID);
fprintf("[SUCCESS] wrote file: %s\n", MARKER_FILE);

%% General Marker Metadata
analog_frames_num = length(c3d.data.analogs);
num_analogs = c3d.parameters.ANALOG.USED.DATA;
analog_frequency = c3d.parameters.ANALOG.RATE.DATA;
analog_labels = c3d.parameters.ANALOG.LABELS.DATA;
analog_names = string(analog_labels);
analog_cols = c3d.header.analogs.size;

fprintf('%% ---- Analog PARAMETERS ---- %%\n');
fprintf('Number of frames = %d\n', analog_frames_num);
fprintf('Number of analogs = %d\n', num_analogs);
fprintf('Analog frame rate = %d Hz\n', analog_frequency);
fprintf('Analog Names: %s\n', sprintf('%s, ', analog_names));

%% Analog Extraction - TRIAL_analog.sto file
ANALOG_FILE = fullfile(OUTPUT_PATH, strcat(TRIAL,"_analog.sto"));
mID = fopen(ANALOG_FILE,'w');

% Construct header
fprintf(mID,"DataRate=%0.6f\n",analog_frequency);
fprintf(mID,"nColumns=%d\n",num_analogs + 1); % +1 for time
fprintf(mID,"nRows=%d\n", analog_frames_num);
fprintf(mID,"DataType=double\n");
fprintf(mID,"version=3\n");
fprintf(mID,"OpenSimVersion=4.6\n");
fprintf(mID,"endheader\n");
point_names_header = sprintf('%s\t', analog_names);
fprintf(mID,"time\t%s\n", point_names_header);

% Build the data file
analogs = c3d.data.analogs;
analog_increment = 1.0 / analog_frequency;

end_time = analog_increment * analog_frames_num;
time = linspace(0.0,end_time,analog_frames_num);

% Output the marker file
for i = 1:analog_frames_num
    fprintf(mID,"%0.16f\t",time(i));
    points_str = sprintf("%0.16f\t",analogs(i,:));
    % Remap NaNs to OpenSim compatible nan string
    points_str = strrep(points_str, 'NaN', 'nan');
    fprintf(mID, '%s\n', points_str);
end

fclose(mID);
fprintf("[SUCCESS] wrote file: %s\n", ANALOG_FILE);

%% Analog Extraction - TRIAL_grfs.sto file
GRF_FILE = fullfile(OUTPUT_PATH, strcat(TRIAL,"_grfs.sto"));
mID = fopen(GRF_FILE,'w');

% Construct header
fprintf(mID,"DataRate=%0.6f\n",analog_frequency);
fprintf(mID,"nColumns=%d\n",num_analogs + 1);% +1 for time
fprintf(mID,"nRows=%d\n", analog_frames_num);
fprintf(mID,"DataType=double\n");
fprintf(mID,"version=3\n");
fprintf(mID,"OpenSimVersion=4.6\n");
fprintf(mID,"endheader\n");

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
grf_names_header = sprintf('%s\t', grf_mapping(:,2));
fprintf(mID,"time\t%s\n", grf_names_header);

% Build the data file
analogs = c3d.data.analogs;
analog_increment = 1.0 / analog_frequency;

end_time = analog_increment * analog_frames_num;
time = linspace(0.0,end_time,analog_frames_num);

% Find the indexes for the GRF keys
for i = 1:length(analog_labels)
    analog_label = analog_labels(i);
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
grf_filtered = zeros(analog_frames_num, num_inputs * length(fp_active));

grf_index = 1;
for i = 1:length(grf_mapping)
    index = str2double(grf_mapping(i,3));
    if index > 0
        grf_filtered(:,grf_index) = filtfilt(b, a, analogs(:,index));
        grf_index = grf_index + 1;
    end
end

% Setup grf data structure information for final calculation
grfs_final = zeros(analog_frames_num, length(grf_mapping));
for j = 1:numel(fp_active)
    fp_index = fp_active(j);
    fp = all_pf(str2double(fp_index));
    stride_in = (j-1)*num_inputs;

    data = grf_filtered(:, 1+stride_in: num_inputs+stride_in);
    
    stride_out =  (j-1)*num_outputs;
    result = calculateFpGrf(data,fp,rotm,GRF_CUTOFF);
    grfs_final(:, 1+stride_out: num_outputs+stride_out) = result;
end
% Output the marker file
for i = 1:analog_frames_num
    fprintf(mID,"%0.16f\t",time(i));
    points_str = sprintf("%0.16f\t",grfs_final(i,:));
    % Remap NaNs to OpenSim compatible nan string
    points_str = strrep(points_str, 'NaN', 'nan');
    fprintf(mID, '%s\n', points_str);
end

fclose(mID);
fprintf("[SUCCESS] wrote file: %s\n", GRF_FILE);