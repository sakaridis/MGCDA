% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function K = calibration_matrix_simple(H, W, fov_horizontal_deg)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Principal point: assumed to be at the image center.
principal_point = [W / 2; H / 2];

% Focal length: computed from the field of view.
f = W / (2 * tan((fov_horizontal_deg / 2) * pi / 180));

% Calibration matrix: zero skew and unit aspect ratio assumed.
K = [f, 0, principal_point(1);
     0, f, principal_point(2);
     0, 0,                  1];

end

