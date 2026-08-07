function [grf_mapping] = calculateGrfMapping(analog_columns, fp_l, fp_r)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    analog_columns, 
    fp_l
    fp_r
end

arguments (Output)
    grf_mapping
end
% Mapping from analog channel name to GRF name expected in OpenSim
% [name in file, result key, index]
grf_mapping = [
    [strcat("Force.Fx",fp_l),"L_ground_force_vx",0]
    [strcat("Force.Fy",fp_l),"L_ground_force_vy",0]
    [strcat("Force.Fz",fp_l),"L_ground_force_vz",0]
    ["","L_ground_force_px",0]
    ["","L_ground_force_py",0]
    ["","L_ground_force_pz",0]
    [strcat("Moment.Mx",fp_l),"L_ground_torque_x",0]
    [strcat("Moment.My",fp_l),"L_ground_torque_y",0]
    [strcat("Moment.Mz",fp_l),"L_ground_torque_z",0]
    [strcat("Force.Fx",fp_r),"R_ground_force_vx",0]
    [strcat("Force.Fy",fp_r),"R_ground_force_vy",0]
    [strcat("Force.Fz",fp_r),"R_ground_force_vz",0]
    ["","R_ground_force_px",0]
    ["","R_ground_force_py",0]
    ["","R_ground_force_pz",0]
    [strcat("Moment.Mx",fp_r),"R_ground_torque_x",0]
    [strcat("Moment.My",fp_r),"R_ground_torque_y",0]
    [strcat("Moment.Mz",fp_r),"R_ground_torque_z",0]
    ];

grf_columns = grf_mapping(:,2);

% Find the indexes for the GRF keys
for i = 1:length(analog_columns)
    analog_label = analog_columns(i);
    for j = 1:length(grf_mapping)
        if grf_mapping(j) == analog_label
            grf_mapping(j,3) = i;
            break;
        end
    end
end

end