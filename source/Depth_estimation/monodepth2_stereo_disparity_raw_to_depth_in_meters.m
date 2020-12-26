% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function depth_in_meters = monodepth2_stereo_disparity_raw_to_depth_in_meters(disparity_uint16)
%MONODEPTH2_STEREO_DISPARITY_RAW_TO_DEPTH_IN_METERS  Convert disparity uint16
%image from Monodepth2 stereo-trained model to depth map in meters.
%
% INPUT:
%
%   -|disparity_uint16|: disparity image in uint16 format corresponding to
%    sigmoid output of Monodepth2 model through the mapping 0 -> 0, 65535 -> 1.

% Define constants.
UINT16_MAX = 65535;
MD2_DISP_MIN = 0.01;
MD2_DISP_MAX = 10;
MD2_STEREO_FACTOR = 5.4;

% Bring input disparity back to unit range corresponding to Monodepth2 raw
% output.
disparity_sigmoid = double(disparity_uint16) / UINT16_MAX;

% Map Monodepth2 raw output to specified disparity range.
disparity_final = MD2_DISP_MIN + disparity_sigmoid * (MD2_DISP_MAX - MD2_DISP_MIN);

% Compute depth map in meters from disparity by scaling with the ratio of the
% camera baseline of the training dataset of the Monodepth2 stereo model over
% the length unit used during training.
depth_in_meters = MD2_STEREO_FACTOR ./ disparity_final;

end

