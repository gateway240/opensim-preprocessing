function [data, labels, header] = readMotFile(filename)
fid = fopen(filename, 'r');
if fid < 0
    error('readMot:FileOpenError', 'Cannot open file: %s', filename);
end
cleanup = onCleanup(@() fclose(fid));

header = struct();
line = fgetl(fid);

while ischar(line)
    if strcmpi(strtrim(line), 'endheader')
        break
    end

    token = regexp(strtrim(line), '^([^=]+)=(.*)$', 'tokens', 'once');
    if ~isempty(token)
        key = matlab.lang.makeValidName(strtrim(token{1}));
        value = strtrim(token{2});
        numericValue = str2double(value);

        if ~isnan(numericValue)
            value = numericValue;
        end

        header.(key) = value;
    end

    line = fgetl(fid);
end

if ~ischar(line)
    error('readMot:InvalidFile', 'Missing endheader marker.');
end

line = fgetl(fid);
while ischar(line) && isempty(strtrim(line))
    line = fgetl(fid);
end

if ~ischar(line)
    error('readMot:InvalidFile', 'Missing column header line.');
end

labels = string(regexp(strtrim(line), '\s+', 'split'));
nColumns = numel(labels);

values = fscanf(fid, '%f');

if mod(numel(values), nColumns) ~= 0
    error('readMot:InvalidData', 'Data rows have inconsistent column counts.');
end

values = reshape(values, nColumns, []).';

data = values;

end
