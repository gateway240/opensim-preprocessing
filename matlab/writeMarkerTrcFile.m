function [status, output] = writeMarkerTrcFile(data, frequency, units, ...
    columns, input_path, output_path,  rotm)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    data
    frequency
    units
    columns
    input_path
    output_path
    rotm
end

arguments (Output)
    status
    output
end
status = 0;
output = "";
mID = fopen(output_path,'w');

% Marker Metadata
sz = size(data);
num_frames = sz(3);
num_cols = sz(2);

output = output + sprintf('%% ---- Marker PARAMETERS ---- %%\n');
output = output + sprintf('Number of frames = %d\n', num_frames);
output = output + sprintf('Number of columns = %d\n', num_cols);
output = output + sprintf('Marker frame rate = %d Hz\n', frequency);
output = output + sprintf('Marker Units = %s\n', units);
output = output + sprintf('Marker Names: %s\n', sprintf('%s, ', columns));

% Construct the .trc header
fprintf(mID,"PathFileType\t4\t(X/Y/Z)\t%s\n",input_path);
fprintf(mID,"DataRate\tCameraRate\tNumFrames\tNumMarkers\tUnits\tOrigDataRate\tOrigDataStartFrame\tOrigNumFrames\n");
fprintf(mID,"%0.6f\t%0.6f\t%d\t%d\t%s\t%0.6f\t%d\t%d\n",frequency, ...
    frequency, num_frames,num_cols,units,frequency,0,num_frames);

header = sprintf('%s\t\t\t', columns);
fprintf(mID,"Frame#\tTime\t%s\n", header);

p_idx = 1:num_cols;
point_xyz_header = strjoin(arrayfun(@(n) sprintf('X%d\tY%d\tZ%d', n, n, n), ...
    p_idx, 'UniformOutput', false), '\t');
fprintf(mID,"\t\t%s\n", point_xyz_header);


time = (0:num_frames-1) / frequency;

% Rotate the table
% Apply the transformation to every point (XYZ combo) for all frames
points_out = pagemtimes(rotm, data);

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
output = output + sprintf("[SUCCESS] wrote file: %s\n", output_path);

end