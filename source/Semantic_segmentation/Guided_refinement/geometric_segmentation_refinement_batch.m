% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function geometric_segmentation_refinement_batch(dark_image_file_names,...
    dark_segmentation_initial_file_names,...
    light_segmentation_assigned_file_names,...
    light_hard_segmentation_assigned_file_names,...
    light_disparity_file_names,...
    dark_SURF_file_names, light_SURF_file_names,...
    camera_motion_extraction_method, camera_motion_extraction_parameters,...
    light_segmentation_warping_method,...
    light_segmentation_filtering_method, filter_parameters,...
    segmentation_fusion_method, fusion_parameters, n_classes,...
    refined_segmentations_output_directory, model_type, model_results_leaf_path)
%SEGMENTATION_REFINEMENT_BATCH  Refine segmentations of dark images into
%Cityscapes classes via segmentations of corresponding lighter images.
%   INPUTS:
%

% Total number of processed images. Should be equal to number of files for each
% auxiliary set.
number_of_images = length(dark_image_file_names);
assert(number_of_images == length(dark_segmentation_initial_file_names));
assert(number_of_images == length(light_segmentation_assigned_file_names));
assert(number_of_images == length(light_hard_segmentation_assigned_file_names));
assert(number_of_images == length(light_disparity_file_names));
assert(number_of_images == length(dark_SURF_file_names));
assert(number_of_images == length(light_SURF_file_names));

% Define output directories and create them if necessary.
refined_segmentations_soft_output_directory =...
    fullfile(refined_segmentations_output_directory, model_results_leaf_path);
refined_segmentations_hard_output_directory =...
    fullfile(refined_segmentations_output_directory, 'labelTrainIds');
refined_segmentations_labelIDs_output_directory =...
    fullfile(refined_segmentations_output_directory, 'labelIds');
refined_segmentations_color_output_directory =...
    fullfile(refined_segmentations_output_directory, 'color');

if ~exist(refined_segmentations_soft_output_directory, 'dir')
    mkdir(refined_segmentations_soft_output_directory);
end
if ~exist(refined_segmentations_hard_output_directory, 'dir')
    mkdir(refined_segmentations_hard_output_directory);
end
if ~exist(refined_segmentations_labelIDs_output_directory, 'dir')
    mkdir(refined_segmentations_labelIDs_output_directory);
end
if ~exist(refined_segmentations_color_output_directory, 'dir')
    mkdir(refined_segmentations_color_output_directory);
end

% Define output formats for refined predictions.
output_format_soft = '.mat';
output_format_hard = '.png';

% Parameters related to semantic classes.
sky_label = 10;

% Counter for images on which warping is applied.
n_warped = 0;

for i = 1:number_of_images
    
    % Read dark image and bring it to double precision for subsequent
    % computations.
    I_dark = im2double(imread(dark_image_file_names{i}));
    [~, dark_image_basename] = fileparts(dark_image_file_names{i});
    [H_dark, W_dark, ~] = size(I_dark);
    
    % Read initial segmentations of the dark image and the light image as soft
    % predictions.
    switch model_type
        case 'refinenet'
            S_dark_init =...
                upsample_soft_predictions_to_image_size_double_format(...
                dark_segmentation_initial_file_names{i},...
                dark_image_file_names{i}, n_classes);
            S_light_init =...
                upsample_soft_predictions_to_image_size_double_format(...
                light_segmentation_assigned_file_names{i},...
                dark_image_file_names{i}, n_classes);
    end
    
    % Read hard segmentation of the light image, to be used in correction of
    % depth map subsequently.
    L_light = imread(light_hard_segmentation_assigned_file_names{i});
    
    % Read disparity map for the light image in uint16 format.
    disp_light = imread(light_disparity_file_names{i});
    [depth_light, is_sky_light] =...
        monodepth2_stereo_disparity_raw_to_depth_in_meters_sky(disp_light,...
        L_light, sky_label);
    [H_light, W_light] = size(depth_light);
    
    % Read SURF points and descriptors for the light and the dark image.
    [SURF_points_light, SURF_descriptors_light] =...
        read_SURF_from_file(light_SURF_file_names{i});
    [SURF_points_dark, SURF_descriptors_dark] =...
        read_SURF_from_file(dark_SURF_file_names{i});
    
    % Calculate camera intrinsics based on the given parameter values.
    K_light = calibration_matrix_simple(H_light, W_light,...
        camera_motion_extraction_parameters.fov_horizontal_deg);
    K_dark = calibration_matrix_simple(H_dark, W_dark,...
        camera_motion_extraction_parameters.fov_horizontal_deg);
    
    % Try to extract camera motion from dark to light view, using the detected
    % SURF points, as well as the depth map for the light view to determine
    % scale.
    [motion_extraction_succeeded, R, t_abs] =...
        camera_motion_extraction_method(SURF_points_light, SURF_points_dark,...
        SURF_descriptors_light, SURF_descriptors_dark, depth_light,...
        is_sky_light, K_light, K_dark, camera_motion_extraction_parameters);
    
    if ~motion_extraction_succeeded
        % If extraction of camera motion was NOT successful:
        % Filter the segmentation of the light image, using the dark image as
        % reference.
        fprintf('Image %4d - %s: Filtering...\n', i, dark_image_basename);
        S_light_transformed = light_segmentation_filtering_method(...
            S_light_init, I_dark, filter_parameters);
    else
        % If extraction of camera motion was NOT successful:
        % Warp the segmentation of the light image to the dark view.
        fprintf('Image %4d - %s: Warping...\n', i, dark_image_basename);
        S_light_transformed = light_segmentation_warping_method(depth_light,...
            K_light, K_dark, R, t_abs, H_dark, W_dark, S_light_init);
        
        % Increment warped counter.
        n_warped = n_warped + 1;
    end
    
    % Fuse the initial segmentation of the dark image with the filtered
    % segmentation of the light image to get the refined segmentation of the
    % dark image.
    S_dark_refined = segmentation_fusion_method(S_dark_init,...
        S_light_transformed, fusion_parameters);
    
    % Infer the hard version of the refined segmentation in train IDs format.
    [~, S_dark_refined_hard_indices] = max(S_dark_refined, [], 3);
    S_dark_refined_hard = uint8(S_dark_refined_hard_indices - 1);
    
    % Convert the hard prediction to labelIDs, catIds and color format.
    S_dark_refined_labelIds =...
        cityscapes_labelTrainIds2labelIds(S_dark_refined_hard);
    S_dark_refined_color =...
        cityscapes_labelTrainIds2colors(S_dark_refined_hard);
    
    % Downsample the soft refined prediction and cast it to single precision in
    % order to reduce the size of the saved file.
    S_dark_refined_downsampled = imresize(S_dark_refined, 0.25, 'bicubic');
    S_dark_refined_downsampled =...
        S_dark_refined_downsampled ./ sum(S_dark_refined_downsampled, 3);
    S_dark_refined_downsampled = single(S_dark_refined_downsampled);
    switch model_type
        case 'refinenet'
            data_obj.score_map = S_dark_refined_downsampled;
    end
    
    % --------------------------------------------------------------------------
    
    % Save the refined soft and hard prediction (four formats) for the dark
    % image in the respective output directories in a lossless format.
    
    % The name of the refined prediction is the same as the initial prediction.
    [~, S_dark_refined_basename] =...
        fileparts(dark_segmentation_initial_file_names{i});
    
    % Save soft prediction as .mat file. The variable name depends on the type
    % of the segmentation model.
    switch model_type
        case 'refinenet'
            save(fullfile(refined_segmentations_soft_output_directory,...
                strcat(S_dark_refined_basename, output_format_soft)), 'data_obj');
    end
    
    % Save hard predictions as .png images.
    imwrite(S_dark_refined_hard,...
        fullfile(refined_segmentations_hard_output_directory,...
        strcat(S_dark_refined_basename, output_format_hard)));
    imwrite(S_dark_refined_labelIds,...
        fullfile(refined_segmentations_labelIDs_output_directory,...
        strcat(S_dark_refined_basename, output_format_hard)));
    imwrite(S_dark_refined_color,...
        fullfile(refined_segmentations_color_output_directory,...
        strcat(S_dark_refined_basename, output_format_hard)));
    
end

% Display proportion of images with application of warping.
fprintf('----------------------\nWarped predictions: %d/%d\n',...
    n_warped, number_of_images);

end

