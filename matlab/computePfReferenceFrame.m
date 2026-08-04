function frame = computePfReferenceFrame(corners)
% Same as ezc3d computePfReferenceFrame
axis_x = corners(:,1) - corners(:,2);
axis_y = corners(:,1) - corners(:,4);
axis_z = cross(axis_x, axis_y);
axis_y = cross(axis_z, axis_x);

% Same normalization as ezc3d
% axis_x = axis_x / sqrt(dot(axis_x,axis_x));
axis_x = normalize(axis_x,"norm");
axis_y = normalize(axis_y,"norm");
axis_z = normalize(axis_z,"norm");

frame = [axis_x(:)'; axis_y(:)'; axis_z(:)'];
end