function [status, output] = extractMarkers(c3d, file, input_path, rotm)
%extractMarkers  Marker Extraction - TRIAL_markers.trc file
%   Detailed explanation goes here
arguments (Input)
    c3d
    file
    input_path
    rotm
end

arguments (Output)
    status
    output
end

point_frequency = c3d.parameters.POINT.RATE.DATA;
point_units = c3d.parameters.POINT.UNITS.DATA{1};
% Build header
point_columns = string(c3d.parameters.POINT.LABELS.DATA);
% Get data
points = c3d.data.points;
[status, output] = writeMarkerTrcFile(points, point_frequency, point_units,...
    point_columns, input_path, file,  rotm);
end