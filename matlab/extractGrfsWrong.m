function [status, output] = extractGrfsWrong(c3d, all_pf, output_file, rotm, fp_l, fp_r, ...
    filter_order, filter_cutoff_frequency, force_minimum , time_start, time_end)
%extractMarkers  Marker Extraction - TRIAL_markers.trc file
%   Detailed explanation goes here
arguments (Input)
    c3d
    all_pf
    output_file
    rotm
    fp_l
    fp_r
    filter_order
    filter_cutoff_frequency
    force_minimum
    time_start
    time_end
end

arguments (Output)
    status
    output
end

analog_frequency = c3d.parameters.ANALOG.RATE.DATA;
% Build header
analog_columns = string(c3d.parameters.ANALOG.LABELS.DATA);
% Get data
analogs = c3d.data.analogs;
grf_mapping = calculateGrfMapping(analog_columns, fp_l, fp_r);
grf_columns = grf_mapping(:,2);

% Low-pass filter raw signals
% THIS doesn't work :(
% normalized_cutoff = 6 / (analog_frequency / 2);
% [b, a] = butter(FILTER_ORDER, normalized_cutoff, 'low');

% This works
Fc = filter_cutoff_frequency;
Fs = analog_frequency;
% Second order filter forwards-backwards is effectively fourth order
n = filter_order;
% From Winter Biomechanics and Motor Control p. 69
C = (2^(1/2)-1)^(1/(2*n));

Fc_corrected = Fc/C;

Wn = Fc_corrected/(Fs/2);

[b,a] = butter(n,Wn,'low');

fp_active = [fp_l, fp_r];

num_inputs = sum(count(grf_mapping(:,1),string(fp_l)));
num_outputs = length(grf_mapping)/ length(fp_active);
grfs_prior = zeros(length(analogs), length(grf_mapping));
% Extract force, COP, and Tz from FP
for i = 1:numel(fp_active)
    fp_index = fp_active(i);
    fp = all_pf(fp_index);
    stride_out =  (i-1)*num_outputs;
    data = zeros(length(analogs), num_outputs);
    for j = 1:length(analogs)
        f = rotm * fp.force(:,j);
        % m = rotm * m;
        cop = rotm * fp.center_of_pressure(:,j);
        tz = rotm * fp.Tz(:,j);

        % Convert from mm to m
        cop = cop ./ 1000;
        tz = tz ./ 1000;
        % m = m ./1000;

        data(j,:) = [f' cop' tz'];
    end
    % Fill NaNs on the columns - OpenSim ID can't handle NaN values
    final_result = fillmissing(data,"linear",1);
    grfs_prior(:, 1+stride_out: num_outputs+stride_out) = final_result;
end

grfs_final = zeros(length(analogs), num_inputs * length(fp_active));

% Filter all signals now
for i = 1:length(grf_mapping)
    grfs_final(:,i) = filtfilt(b, a, grfs_prior(:,i));
end
% Write the sto file
[status, output] = writeStoFile(grfs_final,analog_frequency,grf_columns, ...
    output_file, time_start, time_end);
end