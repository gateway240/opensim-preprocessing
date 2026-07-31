%% C3D Extraction and Processing
% Ensure the ezc3d library is on the MATLAB path!
clear;
%% Path Initialization - OS independent

% On Windows® platforms, the file separator character is a backslash (\).
% On other platforms, the file separator might be a different character. 
HOME = getenv("HOME");
DATASET_PATH = fullfile(HOME,"data","kuopio-full-body-dataset","s01_raw");
PARTICIPANT = '09';
MOCAP_SUBDIR = 'mocap';
TRIAL = 'jogging';

C3D_PATH = fullfile(DATASET_PATH, PARTICIPANT, MOCAP_SUBDIR, strcat(TRIAL,'.c3d'));
disp(C3D_PATH)
%% C3D Loading
[c3d, all_pf] = ezc3dRead(convertStringsToChars(C3D_PATH));
disp(c3d.parameters.POINT.USED.DATA); % Print the number of points used

%% 
plate = 1;
pf_1 = all_pf(plate); % Select the first platform
disp(pf_1)