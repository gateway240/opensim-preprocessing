%% C3D Extraction and Processing
% Ensure the ezc3d library is on the MATLAB path!
clear;
%% Setup - Change these parameters for your own data

% Path Initialization - OS independent
% On Windows® platforms, the file separator character is a backslash (\).
% On other platforms, the file separator might be a different character.
HOME = getenv("HOME");
DATASET_PATH = fullfile(HOME,"data","kuopio-full-body-dataset-results","s02_extracted");
OUTPUT_DIR = fullfile(HOME,"data","kuopio-full-body-dataset-results","s02_extracted");

PARTICIPANT = '09';
MOCAP_SUBDIR = 'mocap';
% name
TRIALS = [
    ["jogging"]
    ["walking"]
    ["squats_deep"]
    ["squat_jumps"]
    ];
TRIAL_SUFFIX = "marker_ik_output.mot";

INPUT_PATH = fullfile(DATASET_PATH, PARTICIPANT);
OUTPUT_PATH = fullfile(OUTPUT_DIR, PARTICIPANT);
if ~exist(OUTPUT_PATH, 'dir')
    mkdir(OUTPUT_PATH)
end

% Low-pass parameters
CUTOFF_FREQUENCY = 6; %Hz
FILTER_ORDER = 2; % forward backward filtering doubles it (so 2 = 4th order)

% Files will be named TRIAL+SUFFIX
FILTERED_SUFFIX = sprintf("_filtered_%dHz.mot", CUTOFF_FREQUENCY);

fprintf("Output Path: %s\n", OUTPUT_PATH);
EXT = ".mot";
dir_data = dir(INPUT_PATH + "/*" + EXT);


for i = 1:size(TRIALS,1)
    trial = TRIALS(i,:);
    trial_name = trial(1);
    %% Trial Loading
    idx = contains({dir_data.name}, TRIAL_SUFFIX) & ...
        contains({dir_data.name}, trial_name);
    matching_files = dir_data(idx);
    matching_file = matching_files(1);
    data_file = fullfile(INPUT_PATH,matching_file.name);
    fprintf("Starting to read file: %s\n",data_file);
    [data, labels, header] = readMotFile(data_file);
    %% Trial filtering
    output_full_name = strrep(matching_file.name, EXT, FILTERED_SUFFIX);
    output_file = fullfile(OUTPUT_PATH, output_full_name);
    fprintf("Starting on file: %s\n", output_file);

    time = table2array(data(2:10,1));
    time_end = time(end);
    time_begin = time(1);
    [tf,step] = isuniform(time, 'TimeTolerance', 1e-6);
    % Start filtering
    Fc = CUTOFF_FREQUENCY;
    Fs = (time_end - time_begin);
    % Second order filter forwards-backwards is effectively fourth order
    n = FILTER_ORDER;
    % From Winter Biomechanics and Motor Control p. 69
    C = (2^(1/2)-1)^(1/(2*n));

    Fc_corrected = Fc/C;

    Wn = Fc_corrected/(Fs/2);

    [b,a] = butter(n,Wn,'low');

    % [status, output] = extractMarkers(c3d, marker_file, INPUT_PATH, rotm);
    % fprintf("Status: %d\n%s", status, output);

end
fprintf("Finished all trials!\n");