% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [succeeded, R, t_abs] = motion_from_feature_points(points_1, points_2,...
    descriptors_1, descriptors_2, depth_1, is_sky_1, K_1, K_2, parameters)
%MOTION_FROM_FEATURE_POINTS  Compute absolute motion between two views from
%feature points in both views, given additionally the intrinsics for both views
%and a dense depth map for the first view. If the computation does not succeed
%due to difficulties in feature matching or in the establishment of epipolar
%geometry (e.g. due to inadequate inliers), indicate this in the first output
%and set the rest of the outputs to empty.

% Add required paths.
current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, '..', 'utilities'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', 'Feature_extraction_and_matching'));

% Sample size for 7-point RANSAC for fundamental matrix.
S = 7;

% Decode parameters structure.
nn_to_2nn_ratio = parameters.nn_to_2nn_ratio;
theta_rel = parameters.theta_rel;
theta_inlier = parameters.theta_inlier;

% Match points from view no. 2 to view no. 1 using a nearest neighbor rule with
% rejection of matches that are not distinct enough.
matches = nearest_neighbor_feature_matching(descriptors_1, descriptors_2,...
    nn_to_2nn_ratio, theta_rel);
matched_points_1 = points_1(:, matches(1, :));
matched_points_2 = points_2(:, matches(2, :));

% Initial matches count.
N_init = size(matched_points_1, 2);

% Determine whether initial feature matching was successful and return if not.
if N_init < 2 * S
    succeeded = 0;
    R = [];
    t_abs = [];
    return;
end

% Automatic estimation of fundamental matrix for the two views.
[matched_points_1_final, matched_points_2_final, ~, ~, F] =...
    fundamental_RANSAC_7point(matched_points_1, matched_points_2, theta_inlier);

% Inlier matches count.
N = size(matched_points_1_final, 2);

% Determine whether inlier matches detection was successful and return if not.
if N < 2 * S
    succeeded = 0;
    R = [];
    t_abs = [];
    return;
end

% Essential matrix from fundamental matrix and camera intrinsics.
E = K_2.' * F * K_1;

% Decompose essential matrix into translation and rotation and compute
% corresponding camera matrix.

x1_hat = K_1 ^ -1 * [matched_points_1_final; ones(1, N)];
x2_hat = K_2 ^ -1 * [matched_points_2_final; ones(1, N)];

[P_2, X] = decompose_essential(E, x1_hat(1:2, :), x2_hat(1:2, :));
R = P_2(1:3, 1:3);
% ATTENTION: translation t can only be determined up to scale without further
% information.
t = P_2(1:3, 4);

% Recover scale using the depth map.

% Get the Z-values of the key points.
Z_1_matched_points = X(3, :);
is_Z_positive = Z_1_matched_points > 0;

% Get the depth map values of the key points in the first view.
[H_1, W_1] = size(depth_1);
inds_matched_points_1 = sub2ind([H_1, W_1],...
    min(max(round(matched_points_1_final(2, :)), 1), H_1),...
    min(max(round(matched_points_1_final(1, :)), 1), W_1));

depth_1_matched_points = depth_1(inds_matched_points_1);

% Keep only points with positive depth.
depth_1_matched_points = depth_1_matched_points(is_Z_positive);
Z_1_matched_points = Z_1_matched_points(is_Z_positive);
inds_matched_points_1 = inds_matched_points_1(is_Z_positive);

% Keep only points which do not belong to the sky class.
is_matched_point_nonsky = ~is_sky_1(inds_matched_points_1);
depth_1_matched_points = depth_1_matched_points(is_matched_point_nonsky);
Z_1_matched_points = Z_1_matched_points(is_matched_point_nonsky);

% Least square fit in log space.
scale_factor =...
    exp(median(log(depth_1_matched_points) - log(Z_1_matched_points)));

% Restore scale of translation component of the extrinsics of the second view.
t_abs = scale_factor * t;

% Motion computation was successful.
succeeded = 1;

end

