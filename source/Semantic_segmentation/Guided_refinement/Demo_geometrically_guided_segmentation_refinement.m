% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)

%% Input the required data

close all;
clear;

% Flags for loading inputs, plotting figures and saving results.
plot_less = 1;
plot_more = 0;
save_results = 1;
requires_GPU = 0;

% Plotting parameters.
color_1 = 'r';
color_2 = 'g';
style_line = 'b';

% Add paths.
current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, '..', '..', 'utilities'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Epipolar_geometry'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Depth_estimation'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Feature_extraction_and_matching', 'SURF'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Evaluation'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Evaluation', 'Semantic_segmentation'));

% Data directories.
demo_data_dir = fullfile(current_script_directory, '..', '..', '..', 'data',...
    'demo');

% Output directories.
refinement_outputs_dir = fullfile(current_script_directory, '..', '..', '..',...
    'output', 'demo');
% Create output directories if results are saved and if necessary.
if save_results && ~exist(refinement_outputs_dir, 'dir')
    mkdir(refinement_outputs_dir);
end

% Image names.
image_1_basename = 'GOPR0374_frame_000801';
image_2_basename = 'GP010375_frame_000036';

% Load inputs.
I_1 = im2double(imread(fullfile(demo_data_dir,...
    strcat(image_1_basename, '_rgb.png'))));
I_2 = im2double(imread(fullfile(demo_data_dir,...
    strcat(image_2_basename, '_rgb.png'))));
disp_1_uint16 = imread(fullfile(demo_data_dir,...
    strcat(image_1_basename, '_disparity_raw.png')));
% The SURF inputs need to be loaded from a full-dataset results directory.
[SURF_points_1, SURF_descriptors_1] = read_SURF_from_file(fullfile(...
    demo_data_dir, strcat(image_1_basename, '_gray.surf')));
[SURF_points_2, SURF_descriptors_2] = read_SURF_from_file(fullfile(...
    demo_data_dir, strcat(image_2_basename, '_gray.surf')));
% The RefineNet inputs need to be loaded from a full-dataset results directory.
L_1 = imread(fullfile(demo_data_dir, strcat(image_1_basename, '.png')));
if requires_GPU
    gpu_num = gpuDeviceCount;
    if gpu_num >= 1
        gpuDevice(1);
    else
        error('no gpu found!');
    end
    load(fullfile(demo_data_dir, strcat(image_1_basename, '.mat')), 'data_obj');
    daytime_segmentation_with_void = gather(data_obj.score_map);
    load(fullfile(demo_data_dir, strcat(image_2_basename, '.mat')), 'data_obj');
    twilight_segmentation_with_void = gather(data_obj.score_map);
else
    load(fullfile(demo_data_dir, strcat(image_1_basename, '.mat')),...
        'data_obj');
    daytime_segmentation_with_void = data_obj.score_map;
    load(fullfile(demo_data_dir, strcat(image_2_basename, '.mat')),...
        'data_obj');
    twilight_segmentation_with_void = data_obj.score_map;
end

% Image sizes.
[H_1, W_1, ~] = size(I_1);
[H_2, W_2, ~] = size(I_2);

% Semantic classes.
n_classes = 19;
sky_label = 10;
train_IDs = uint8(0:18);
class_indices_dynamic = 12:19;

% Mode for assigning soft predictions to regions of the target view outside the
% range of the warped source-view grid.
copy_source_predictions = 1;

% Convert inputs to representations employed by the pipeline.
depth_1 = monodepth2_stereo_disparity_raw_to_depth_in_meters(disp_1_uint16);

% Upsampling and renormalizing soft predictions to remove void class.
S_1_help = double(daytime_segmentation_with_void);
S_1_help = log(S_1_help);
S_1_help = max(S_1_help, -20);
S_1_help = imresize(S_1_help, [H_1, W_1], 'bicubic');
S_1_help = exp(S_1_help);
S_1 = S_1_help(:, :, 1:n_classes);
S_1 = S_1 ./ sum(S_1, 3);

S_2_help = double(twilight_segmentation_with_void);
S_2_help = log(S_2_help);
S_2_help = max(S_2_help, -20);
S_2_help = imresize(S_2_help, [H_1, W_1], 'bicubic');
S_2_help = exp(S_2_help);
S_2 = S_2_help(:, :, 1:n_classes);
S_2 = S_2 ./ sum(S_1, 3);

%% Depth map visualization

% Monodepth2 maximum depth value in meters.
md2_depth_max = 540;
depth_1_min = min(depth_1(:));
depth_1_max = max(depth_1(:));

if plot_more
    % Visualize in log scale.
    figure;
    imshow(log10(depth_1), [log10(depth_1_min), log10(depth_1_max)]);
end

% Set the depth of all pixels labeled as sky to the maximum possible value.
is_sky = L_1 == sky_label;
depth_1(is_sky) = md2_depth_max;
depth_1_max = max(depth_1(:));

if plot_less
    % Visualize in log scale.
    figure;
    imshow(log10(depth_1), [log10(depth_1_min), log10(depth_1_max)]);
    title('Depth map after sky correction');
end

%% SURF points visualization

N_1 = size(SURF_points_1, 2);
N_2 = size(SURF_points_2, 2);


% Randomly subsample the sets of SURF points for the two images to avoid
% clutter.
rng('default');
perm_1 = randperm(N_1);
perm_2 = randperm(N_2);

N_less = 200;
assert(N_less <= N_1 && N_less <= N_2,...
    'Number of visualized SURF points exceeds original number of points');
SURF_points_1_less = SURF_points_1(:, perm_1(1:N_less));
SURF_points_2_less = SURF_points_2(:, perm_2(1:N_less));

if plot_more
    figure;
    imshow(I_1);
    hold on;
    plot(SURF_points_1_less(1, :), SURF_points_1_less(2, :),...
        'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
    
    figure;
    imshow(I_2);
    hold on;
    plot(SURF_points_2_less(1, :), SURF_points_2_less(2, :),...
        'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
end

%% Initial matching of SURF points with nearest neighbor ratio strategy

% Match points from view no. 2 (target) to view no. 1 (source).

% Define parameters for the two threshold criteria. Select values that
% correspond to an equal level of selectivity for both criteria.
nn_to_2nn_ratio = sqrt(0.7);
theta_rel = 20;

% Compute pairwise distances for all pairs of feature vectors across the two
% images.
SURF_pairwise_dists_sq = squared_euclidean_distances_exact(...
    SURF_descriptors_1.', SURF_descriptors_2.');

% Find nearest neighbors.
[dists_sq_nn, row_subs_nn] = min(SURF_pairwise_dists_sq);
indices_nn = sub2ind([N_1, N_2], row_subs_nn, 1:N_2);

% Find nearest neighbors in the opposite direction (source to target view) so as
% to eliminate many-to-one matches.
[~, col_subs_nn_inv] = min(SURF_pairwise_dists_sq, [], 2);
accepted_unique = col_subs_nn_inv(row_subs_nn).' == 1:N_2;

% Increase distances of nearest neighbors by a factor equal to the inverse of
% the ratio parameter. Iff the arg minimum is preserved, the candidate match
% satisfies the ratio criterion.
SURF_pairwise_dists_sq(indices_nn) = dists_sq_nn * (1 / nn_to_2nn_ratio ^ 2);
[~, row_subs_nn_or_2nn] = min(SURF_pairwise_dists_sq);
accepted_ratio = row_subs_nn == row_subs_nn_or_2nn;

% Compare distances of nearest neighbors to the distance of the best match, i.e.
% the smallest distance between all candidate pairs. Iff the distance is smaller
% or equal to a multiple of the smallest match distance, the candidate match
% satisfies this criterion.
dist_sq_nn_min = min(dists_sq_nn);
accepted_rel = dists_sq_nn <= theta_rel * dist_sq_nn_min;

% Matches are determined by candidates that satisfy all criteria.
is_matched_2 = accepted_unique & accepted_ratio & accepted_rel;
P = sum(is_matched_2);
matches = zeros(2, P);
matches(2, :) = find(is_matched_2);
matches(1, :) = row_subs_nn(is_matched_2);
matched_points_1 = SURF_points_1(:, matches(1, :));
matched_points_2 = SURF_points_2(:, matches(2, :));

% Visualize the initial matching results.
if plot_less
    show_matches(I_1, I_2, matched_points_1, matched_points_2,...
        color_1, color_2, style_line);
end

% Visualize a subset of the matches to reduce clutter.
if plot_more
    perm_matched = randperm(P);
    P_less = 20;
    assert(P_less <= P,...
        'Number of visualized initial matches exceeds number of original matches');
    
    matched_points_1_less = matched_points_1(:, perm_matched(1:P_less));
    matched_points_2_less = matched_points_2(:, perm_matched(1:P_less));
    
    show_matches(I_1, I_2, matched_points_1_less, matched_points_2_less,...
        color_1, color_2, style_line);
end

%% Automatic estimation of fundamental matrix for the two views

% Parameters.
n_thr = 5;
thresholds = linspace(0.5, 2.5, n_thr);
inlier_counts = zeros(1, n_thr);
matched_points_1_inliers = cell(1, n_thr);
matched_points_2_inliers = cell(1, n_thr);
M = zeros(1, n_thr);
F = zeros(3, 3, n_thr);
p = 0.999;
adaptive_RANSAC = false;

for i = 1:n_thr
    if adaptive_RANSAC
        [matched_points_1_inliers{i}, matched_points_2_inliers{i},...
            outliers_1, outliers_2, M(i), F(:, :, i)] =...
            fundamental_RANSAC_7point_adaptive(matched_points_1,...
            matched_points_2, thresholds(i), p);
    else
        [matched_points_1_inliers{i}, matched_points_2_inliers{i},...
            outliers_1, outliers_2, F(:, :, i)] =...
            fundamental_RANSAC_7point(matched_points_1,...
            matched_points_2, thresholds(i));
    end
    
    % Compute total inlier count for each iteration
    inlier_counts(i) = length(matched_points_1_inliers{i});
    
    if plot_less && i == 4
        show_matches(I_1, I_2,...
            matched_points_1_inliers{i}, matched_points_2_inliers{i},...
            color_1, color_2, style_line);
        title(strcat('Inliers for threshold = ', num2str(thresholds(i))),...
            'FontSize', 15);
    end
    
    if plot_less && i == 4
        show_matches(I_1, I_2, outliers_1, outliers_2,...
            color_1, color_2, style_line);
        title(strcat('Outliers for threshold = ', num2str(thresholds(i))),...
            'FontSize', 15);
    end

end

% Show number of iterations needed
if plot_less && adaptive_RANSAC
    figure;
    plot(thresholds, M, 'LineWidth', 2);
    xlabel('Threshold');
    ylabel('Iterations');
end

% Show inlier ratio
if plot_less
    figure;
    plot(thresholds, inlier_counts / P, 'LineWidth', 2);
    xlabel('Threshold');
    ylabel('Inlier ratio');
end

% Final selection of fundamental matrix by fixing the inlier threshold.

% Corresponds to a threshold value of 2 pixels.
threshold_final_index = 4;
F_final = F(:, :, threshold_final_index);

matched_points_1_final = matched_points_1_inliers{threshold_final_index};
matched_points_2_final = matched_points_2_inliers{threshold_final_index};
N = size(matched_points_1_final, 2);

%% Camera intrinsics

% Principal points: assumed to be at the image centers.
principal_1 = [W_1 / 2; H_1 / 2];
principal_2 = [W_2 / 2; H_2 / 2];

% Focal length:

% Assignment based on our GoPro Hero 5 camera specifications for field of view.
fov_horizontal_deg = 64.4;
f_1 = W_1 / (2 * tan((fov_horizontal_deg / 2) * pi / 180));
f_2 = W_2 / (2 * tan((fov_horizontal_deg / 2) * pi / 180));

% Calibration matrices: zero skew and unit aspect ratio assumed.
K_1 = [f_1, 0, principal_1(1);
       0, f_1, principal_1(2);
       0,   0,              1];

K_2 = [f_2, 0, principal_2(1);
       0, f_2, principal_2(2);
       0,   0,              1];

%% Camera extrinsics

% Essential matrix from fundamental matrix and camera intrinsics.
E = K_2.' * F_final * K_1;

% Decompose essential matrix into translation and rotation and compute
% corresponding camera matrix.
P_1 = eye(4);

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
inds_matched_points_1 = sub2ind([H_1, W_1],...
    min(max(round(matched_points_1_final(2, :)), 1), H_1),...
    min(max(round(matched_points_1_final(1, :)), 1), W_1));

depth_1_matched_points = depth_1(inds_matched_points_1);

% Keep only points with positive depth.
depth_1_matched_points = depth_1_matched_points(is_Z_positive);
Z_1_matched_points = Z_1_matched_points(is_Z_positive);
inds_matched_points_1 = inds_matched_points_1(is_Z_positive);

% Keep only points which do not belong to the sky class.
is_matched_point_sky = ~is_sky(inds_matched_points_1);
depth_1_matched_points = depth_1_matched_points(is_matched_point_sky);
Z_1_matched_points = Z_1_matched_points(is_matched_point_sky);

% Least square fit in log space.
scale_factor = exp(median(log(depth_1_matched_points) - log(Z_1_matched_points)));

% Restore scale of translation component of the extrinsics of the second view.
t_abs = scale_factor * t;

%% Establish per-pixel correspondences from source to target view

% Contruct pixel grid in the first view.
[j_1, i_1] = meshgrid(1:W_1, 1:H_1);

% Get homogeneous coordinates of pixel grid in proper dimensions for subsequent
% operations.
coords_1_pixel = cat(3, j_1, i_1, ones(H_1, W_1));
coords_1_pixel = shiftdim(coords_1_pixel, 2);
coords_1_pixel = reshape(coords_1_pixel, [3, H_1 * W_1]);

% Backproject 2D image points to 3D space using the estimated depth map.
coords_1_normalized = K_1 ^ -1 * coords_1_pixel;
depth_1_vectorized = depth_1(:);
X_dense = (depth_1_vectorized.') .* coords_1_normalized;
X_dense_hom = [X_dense; ones(1, H_1 * W_1)];

% Reproject the obtained 3D points to the second view using the estimated
% intrinsics and extrinsics for that view. Determine which points lie very close
% to the image plane in the second view.

thresh_z = 0.1;
coords_2_pixel = K_2 * ([R, t_abs] * X_dense_hom);
is_projection_ill_cond = (abs(coords_2_pixel(3, :)) < thresh_z).';
coords_2_pixel = coords_2_pixel ./ coords_2_pixel(3, :);
j_1_warped = reshape(coords_2_pixel(1, :), [H_1, W_1]);
i_1_warped = reshape(coords_2_pixel(2, :), [H_1, W_1]);

% Visualize the resulting per-pixel correspondences.

samples_j_1 = 1:13:W_1;
samples_i_1 = 1:13:H_1;
[samples_j_1_grid, samples_i_1_grid] = meshgrid(samples_j_1, samples_i_1);

j_1_warped_sampled = j_1_warped(samples_i_1, samples_j_1);
i_1_warped_sampled = i_1_warped(samples_i_1, samples_j_1);

if plot_less
    figure;
    imshow(I_2);
    hold on;
    plot(j_1_warped_sampled(:), i_1_warped_sampled(:), '.');
end

% Quiver plot to show the "flow" between the two views.
u = j_1_warped - j_1;
v = i_1_warped - i_1;

u_sampled = u(samples_i_1, samples_j_1);
v_sampled = v(samples_i_1, samples_j_1);

if plot_less
    figure;
    imshow(I_1);
    hold on;
    quiver(samples_j_1_grid(:), samples_i_1_grid(:), u_sampled(:),...
        v_sampled(:), 2);
end

%% Warp soft predictions from source to target view

% Contruct pixel grid in the second view.
[j_2, i_2] = meshgrid(1:W_2, 1:H_2);
pixel_grid_2_vectorized = [j_2(:), i_2(:)];

% Construct quadrangular mesh for the first view.
quads = create_quad_mesh_2d(true(H_1, W_1));

% Form vertex matrix for quadrangular mesh based on the established per-pixel
% correspondences.
verts = coords_2_pixel(1:2, :).';

% Determine which polygons contain each pixel in the second view.
quad_inclusions_2 = pixels_in_polygonal_mesh(pixel_grid_2_vectorized, verts,...
    quads, is_projection_ill_cond, H_2, W_2);

% Plot three categories of pixels: included in zero, one, or more than one
% quads.
polygon_count = zeros(1, H_2 * W_2);

for i = 1:H_2 * W_2
    c = size(quad_inclusions_2{i}, 2);
    if c >= 2
        polygon_count(i) = 2;
    else
        if c == 1
            polygon_count(i) = 1;
        end
    end
end

polygon_count = reshape(polygon_count, [H_2 W_2]);

if plot_more
    figure;
    imshow(polygon_count, []);
end

% Disambiguate polygon membership for pixels that are contained in two or more
% polygons based on depth values of polygon vertices.
[quad_assignments_2, depth_quads] = assign_quads_to_pixels(quads,...
    quad_inclusions_2, depth_1, verts);

% Compute weights for quad mesh interpolation.
[w_bilinear, disocclusion_mask_vectorized] =...
    weights_bilinear_except_disocclusions(pixel_grid_2_vectorized,...
    verts, quads, quad_assignments_2, depth_1_vectorized);
% Plot mask showing pixels where disocclusion has occurred.
disocclusion_mask = reshape(disocclusion_mask_vectorized, [H_2 W_2]);
if plot_more
    figure;
    imshow(disocclusion_mask, []);
end

% Perform the warping.

if copy_source_predictions
    S_1_warped_init = S_1;
else
    S_1_warped_init = (1 / n_classes) * ones(H_2, W_2, n_classes);
end
S_1_warped_init_vectorized = reshape(S_1_warped_init, H_2 * W_2, n_classes);

S_1_vectorized = reshape(S_1, H_1 * W_1, n_classes);

S_1_warped_vectorized = warp_soft_prediction(S_1_vectorized,...
    S_1_warped_init_vectorized, disocclusion_mask_vectorized, quads,...
    quad_assignments_2, w_bilinear);

S_1_warped = reshape(S_1_warped_vectorized, H_2, W_2, n_classes);

% Visualization.
% Get hard warped predictions. Set pixels outside warping boundaries to black,
% if applicable.
[S_1_warped_confidence, L_warped_1] = max(S_1_warped, [], 3);
L_warped_1(S_1_warped_confidence <= 1 / n_classes) = 0;
L_warped_1_train_IDs =...
    Cityscapes_class_indices2labelTrainIds_invalid(L_warped_1);
L_warped_1_colors = cityscapes_labelTrainIds2colors(L_warped_1_train_IDs);

if plot_less
    figure;
    imshowpair(I_2, L_warped_1_colors, 'blend');
    title('Target view blended with warped source prediction');
end

if plot_less
    figure;
    imshow(L_warped_1_colors);
    title('Warped source prediction in target view');
end

% Get hard color predictions for source view to facilitate comparison.
L_1_colors = cityscapes_labelTrainIds2colors(L_1);

if plot_more
    figure;
    imshowpair(I_1, L_1_colors, 'blend');
    title('Source prediction');
end

% Save warped soft prediction result.
if save_results
    warped_prediction_output_filename =...
        strcat(image_1_basename(end - 20:end), '_warped_to_',...
        image_2_basename(end - 20:end), '_color.png');
    imwrite(L_warped_1_colors,...
        fullfile(refinement_outputs_dir, warped_prediction_output_filename));
end

%% Confidence-adaptive fusion of target-view prediction with warped source-view prediction

% Weight and threshold parameters for fusion.
alpha_low = 0.3;
alpha_high = 0.6;

thresh_confidence_1_for_prediction_2 = 0.2;
thresh_confidence_2_for_prediction_1 = 0.2;

% Compute the confidence map pertaining to the original target-view prediction.
[S_2_confidence, L_2] = max(S_2, [], 3);

is_L_2_dynamic = ismember(L_2, class_indices_dynamic);
is_L_warped_1_dynamic = ismember(L_warped_1, class_indices_dynamic);

indices_L_2_predictions = sub2ind([H_2, W_2, n_classes],...
    pixel_grid_2_vectorized(:, 2), pixel_grid_2_vectorized(:, 1), L_2(:));
S_1_warped_confidence_for_L_2 =...
    S_1_warped(indices_L_2_predictions);
S_1_warped_confidence_for_L_2 = reshape(S_1_warped_confidence_for_L_2, [H_2, W_2]);
if plot_more
    figure;
    imshow(S_1_warped_confidence_for_L_2);
end

is_S_1_warped_confidence_for_L_2_low =...
    S_1_warped_confidence_for_L_2 <= thresh_confidence_1_for_prediction_2;
is_S_1_warped_confidence_for_dynamic_L_2_low =...
    is_S_1_warped_confidence_for_L_2_low...
    & is_L_2_dynamic;
if plot_more
    figure;
    imshow(is_S_1_warped_confidence_for_dynamic_L_2_low);
end

indices_L_warped_1_predictions = sub2ind([H_2, W_2, n_classes],...
    pixel_grid_2_vectorized(:, 2), pixel_grid_2_vectorized(:, 1), L_warped_1(:));
S_2_confidence_for_L_warped_1 = S_2(indices_L_warped_1_predictions);
S_2_confidence_for_L_warped_1 = reshape(S_2_confidence_for_L_warped_1, [H_2, W_2]);
if plot_more
    figure;
    imshow(S_2_confidence_for_L_warped_1);
end

is_S_2_confidence_for_L_warped_1_low =...
    S_2_confidence_for_L_warped_1 <= thresh_confidence_2_for_prediction_1;
is_S_2_confidence_for_dynamic_L_warped_1_low =...
    is_S_2_confidence_for_L_warped_1_low & is_L_warped_1_dynamic;
if plot_more
    figure;
    imshow(is_S_2_confidence_for_dynamic_L_warped_1_low);
end

is_either_confidence_for_cross_dynamic_low =...
    is_S_1_warped_confidence_for_dynamic_L_2_low...
    | is_S_2_confidence_for_dynamic_L_warped_1_low;
if plot_more
    figure;
    imshow(is_either_confidence_for_cross_dynamic_low);
end

alpha_ada = alpha_low * is_either_confidence_for_cross_dynamic_low...
    + alpha_high * ~is_either_confidence_for_cross_dynamic_low;

% Apply the confidence-adaptive fusion scheme.
S_2_refined =...
    (S_2_confidence ./ (S_2_confidence + alpha_ada .* S_1_warped_confidence))...
    .* S_2...
    + (alpha_ada .* S_1_warped_confidence ./...
    (S_2_confidence + alpha_ada .* S_1_warped_confidence))...
    .* S_1_warped;

% Get hard predictions for visualization.
[S_2_refined_confidence, L_2_refined] = max(S_2_refined, [], 3);
L_2_refined_train_IDs =...
    Cityscapes_class_indices2labelTrainIds_invalid(L_2_refined);
L_2_refined_colors = cityscapes_labelTrainIds2colors(L_2_refined_train_IDs);

% Visualization.
if plot_less
    figure;
    imshowpair(I_2, L_2_refined_colors, 'blend');
    title('Target view blended with refined prediction');
end

if plot_less
    figure;
    imshow(L_2_refined_colors);
    title('Refined target-view prediction');
end

% Save refined hard prediction result.
if save_results
    refined_prediction_output_filename =...
        strcat(image_2_basename(end - 20:end),...
        '_corrected_with_', image_1_basename(end - 20:end),...
        '_warpDense_weights_confRatioDynamic_theta02_alphaLow03_alphaHigh06_color.png');
    imwrite(L_2_refined_colors,...
        fullfile(refinement_outputs_dir, refined_prediction_output_filename));
end










