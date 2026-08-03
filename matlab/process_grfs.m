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

MARKER_ROTATIONS = [-pi / 2, pi / 2, 0];

C3D_FILE = fullfile(INPUT_PATH,strcat(TRIAL,'.c3d'));
fprintf("Input File: %s\n",C3D_FILE);
fprintf("Output Path: %s\n", OUTPUT_PATH);
%% C3D Loading
[c3d, all_pf] = ezc3dRead(convertStringsToChars(C3D_FILE));
disp(c3d.parameters.POINT.USED.DATA); % Print the number of points used

%% 
plate = 1;
pf_1 = all_pf(plate); % Select the first platform
disp(pf_1)

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
sz = size(points);
points_out = zeros(sz);
increment = 1.0 / point_frequency;

end_time = increment * num_frames;
time = linspace(0.0,end_time,num_frames);

% Rotate the table
for i = 1:sz(3)
    for j = 1:sz(2)
        points_out(:,j,i) = rotm * points(:,j,i);
    end
end

% Output the marker file
for i = 1:sz(3)
    % MATLAB uses 1-based indexing :(
    frame = i -1;
    fprintf(mID,"%d\t%0.4f\t",frame,time(i));
    points_str = sprintf("%0.11f\t",points_out(:,:,i));
    % Remap NaNs to OpenSim compatible nan string
    points_str = strrep(points_str, 'NaN', 'nan');
    fprintf(mID, '%s\n', points_str);
end

fclose(mID);
fprintf("[SUCCESS] wrote file: %s\n", INPUT_PATH);