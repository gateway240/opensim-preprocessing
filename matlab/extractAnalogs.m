function [status, output] = extractAnalogs(c3d, output_file, time_start, time_end)
%extractMarkers  Marker Extraction - TRIAL_markers.trc file
%   Detailed explanation goes here
arguments (Input)
    c3d
    output_file
    time_start
    time_end
end

arguments (Output)
    status
    output
end

frequency = c3d.parameters.ANALOG.RATE.DATA;
% Build header
columns = string(c3d.parameters.ANALOG.LABELS.DATA);
% Get data
analogs = c3d.data.analogs;

[status, output] = writeStoFile(analogs,frequency,columns,output_file, ...
    time_start, time_end);
end