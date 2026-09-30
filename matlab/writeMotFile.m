function [status, output] = writeMotFile(data, labels, header, output_path)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    data
    labels
    header
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
output = output + sprintf('Number of rows = %d\n', num_frames);
output = output + sprintf('Number of columns = %d\n', num_cols);
output = output + sprintf('Columns: %s\n', sprintf('%s, ', labels));

% Construct header
fprintf(mID,"Coordinates");
fields = fieldnames(header);

for i = 1:numel(fields)
    field = fields{i};
    value = header.(field);

    fprintf(mID, "%s=%s\n", field, string(value));
end

fprintf(mID, "\nUnits are S.I. units (second, meters, Newtons, ...)\n" + ...
    " If the header above contains a line with 'inDegrees'," + ...
    " this indicates whether rotational values are in degrees (yes) or radians (no).)\n\n");
fprintf(mID,"endheader\n");
header = sprintf('%s\t', labels);
fprintf(mID,"%s\n", header);

% Output the file
for i = 1:num_frames
    fprintf(mID,"%0.16f\t",data(i,1));
    data_str = sprintf("%0.16f\t",data(i,2:end));
    % Remap NaNs to OpenSim compatible nan string
    data_str = strrep(data_str, 'NaN', 'nan');
    fprintf(mID, '%s\n', data_str);
end

fclose(mID);
output = output + sprintf("[SUCCESS] wrote file: %s\n", output_path);

end