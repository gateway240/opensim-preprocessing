function [status, output] = writeStoFile(data, frequency, columns, output_path)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    data
    frequency
    columns
    output_path
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
num_frames = sz(1);
num_cols = sz(2);

output = output + sprintf('%% ---- File PARAMETERS ---- %%\n');
output = output + sprintf('Number of frames = %d\n', num_frames);
output = output + sprintf('Number of columns = %d\n', num_cols);
output = output + sprintf('Frame rate = %d Hz\n', frequency);
output = output + sprintf('Columns: %s\n', sprintf('%s, ', columns));

% Construct header
fprintf(mID,"DataRate=%0.6f\n",frequency);
fprintf(mID,"nColumns=%d\n",num_cols + 1); % +1 for time
fprintf(mID,"nRows=%d\n", num_frames);
fprintf(mID,"DataType=double\n");
fprintf(mID,"version=3\n");
fprintf(mID,"OpenSimVersion=4.6\n");
fprintf(mID,"endheader\n");
header = sprintf('%s\t', columns);
fprintf(mID,"time\t%s\n", header);

% Build the data file
analog_increment = 1.0 / frequency;

end_time = analog_increment * num_frames;
time = linspace(0.0,end_time,num_frames);

% Output the marker file
for i = 1:num_frames
    fprintf(mID,"%0.16f\t",time(i));
    points_str = sprintf("%0.16f\t",data(i,:));
    % Remap NaNs to OpenSim compatible nan string
    points_str = strrep(points_str, 'NaN', 'nan');
    fprintf(mID, '%s\n', points_str);
end

fclose(mID);
output = output + sprintf("[SUCCESS] wrote file: %s\n", output_path);

end