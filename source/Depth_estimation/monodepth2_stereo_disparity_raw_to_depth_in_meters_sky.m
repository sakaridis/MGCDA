% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [depth_in_meters, is_sky] =...
    monodepth2_stereo_disparity_raw_to_depth_in_meters_sky(disparity_uint16,...
    labeling, sky_label)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Convert inputs to representations employed by the pipeline.
depth_in_meters =...
    monodepth2_stereo_disparity_raw_to_depth_in_meters(disparity_uint16);

% Monodepth2 maximum depth value in meters.
md2_depth_max = 540;

% Set the depth of all pixels labeled as sky to the maximum possible value.
is_sky = labeling == sky_label;
depth_in_meters(is_sky) = md2_depth_max;

end

