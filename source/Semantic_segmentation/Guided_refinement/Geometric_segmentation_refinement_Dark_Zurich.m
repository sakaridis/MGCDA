% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function Geometric_segmentation_refinement_Dark_Zurich(task_id,...
    dataset_version, subset, split_dark, split_light,...
    feature_results_root_directory, feature_detection_method,...
    depth_results_root_directory, depth_estimation_method,...
    segmentation_results_root_directory, model_type,...
    model_configuration_dark, model_configuration_light, variant,...
    images_per_task)
%GEOMETRIC_SEGMENTATION_REFINEMENT_DARK_ZURICH  Refine the segmentations of a
%batch of images from Dark Zurich using the segmentations of corresponding
%lighter images and write the results. Structured for execution on a cluster.
%   INPUTS:
%
%   -|task_id|: ID of the task. Used to determine which images out of the entire
%    dataset will form the batch that will be processed by this task.
%
%   -|dataset_version|: string that indicates which version of Dark Zurich is
%    used for applying the pipeline, e.g. 'rgb', 'rgb_anon'.
%
%   -|subset|: e.g. 'train', 'test'.
%
%   -|split_dark|: e.g. 'night', 'twilight'.
%
%   -|split_light|: e.g. 'day'.
%
%   -|model_type|: example: 'refinenet'
%
%   -|feature_results_root_directory|: directory under which feature detection
%    results for different versions and splits of Dark Zurich obtained with
%    different models are stored.
%
%   -|feature_detection_method|: string that indicates the feature detection
%    method used on Dark Zurich. Example: 'SURF'.
%
%   -|depth_results_root_directory|: directory under which depth estimation
%    results for different versions and splits of Dark Zurich obtained with
%    different models are stored.
%
%   -|depth_estimation_method|: string that indicates the depth estimation
%    method used on Dark Zurich. Example: 'monodepth2'.
%
%   -|segmentation_results_root_directory|: directory under which segmentation
%    results for different versions and splits of Dark Zurich obtained with
%    different models are stored.
%
%   -|variant|: string that indicates the type of segmentation refinement that
%    is being run, e.g.
%    'color_cross_bilateral_filtering_and_confidence_proportion_weighting',
%    'depth_based_warping_with_bilateral_filtering_alternative_and_confidence_proportion_weighting_with_dynamic_class_distinction'.
%
%   -|images_per_task|: maximum number of images for which segmentation
%    refinement is run in each task.
%    2920 Dark Zurich-twilight images -> 100 images per task * 30 tasks.

if ischar(task_id)
    task_id = str2double(task_id);
end

% ------------------------------------------------------------------------------

% Check which model is used and distinguish between different cases.

% Get abbreviations to be included in output names.
model_directories = containers.Map({'refinenet'}, {'RefineNet'});
model_directory = model_directories(model_type);
model_configuration_prefices =...
    containers.Map({'refinenet'}, {'refinenet_res101_cityscapes_'});
model_configuration_prefix = model_configuration_prefices(model_type);
model_results_leaf_paths =...
    containers.Map({'refinenet'}, {fullfile('predict_result_full')});
segmentation_formats = containers.Map({'refinenet'}, {'.mat'});
segmentation_format = segmentation_formats(model_type);
model_results_leaf_path = model_results_leaf_paths(model_type);
feature_formats = containers.Map({'SURF'}, {'_gray.surf'});
feature_format = feature_formats(feature_detection_method);
feature_results_intermediate_paths = containers.Map({'SURF'},...
    {fullfile('SURF', 'Dark_Zurich')});
feature_results_intermediate_path =...
    feature_results_intermediate_paths(feature_detection_method);
depth_formats = containers.Map({'monodepth2'}, {'_disparity_raw.png'});
depth_format = depth_formats(depth_estimation_method);
depth_results_intermediate_paths = containers.Map({'monodepth2'},...
    {fullfile('monodepth2', 'stereo_1024x320')});
depth_results_intermediate_path =...
    depth_results_intermediate_paths(depth_estimation_method);
depth_results_leaf_paths = containers.Map({'monodepth2'}, {'disparity_raw'});
depth_results_leaf_path =...
    depth_results_leaf_paths(depth_estimation_method);
abbreviations_of_variants = containers.Map(...
    {'depth_based_warping_with_bilateral_filtering_alternative_and_confidence_proportion_weighting_with_dynamic_class_distinction',...
    'color_cross_bilateral_filtering_and_confidence_proportion_weighting',...
    'color_cross_bilateral_filtering_and_confidence_proportion_weighting_with_dynamic_class_distinction'},...
    {'warpDepthAlternBilateral_confProportionDyn',...
    'bilateralCrossColor_confProportion',...
    'bilateralCrossColor_confProportionDyn'});
variant_abbreviation = abbreviations_of_variants(variant);

% ------------------------------------------------------------------------------

% Add paths to functions that are called for guided refinement.

current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, '..', '..', 'utilities'));
addpath_relative_to_caller(current_script_full_name, '..');
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Feature_extraction_and_matching'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Feature_extraction_and_matching', 'SURF'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Depth_estimation'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Epipolar_geometry'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Color_transformations'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Evaluation'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Evaluation', 'Semantic_segmentation', 'RefineNet'));

% ------------------------------------------------------------------------------

% Create lists of input files for various modalities.

Dark_Zurich_root_directory = fullfile(current_script_directory,...
    '..', '..', '..', 'data', 'Dark_Zurich');
Dark_Zurich_file_lists_directory = fullfile(Dark_Zurich_root_directory,...
    'lists_file_names');
Dark_Zurich_corresp_directory = fullfile(Dark_Zurich_root_directory,...
    'corresp', subset, split_dark);

% Dark input images.
switch subset
    case 'train'
        list_of_dark_images_file = strcat(subset, '_', split_dark,...
            '_filenames.txt');
    case 'test'
        list_of_dark_images_file = strcat(subset, '_filenames.txt');
end
fid = fopen(fullfile(Dark_Zurich_file_lists_directory,...
    list_of_dark_images_file));
dark_image_rel_file_names = textscan(fid, '%s');
fclose(fid);
dark_image_rel_file_names = dark_image_rel_file_names{1};

dark_image_file_names = fullfile(Dark_Zurich_root_directory, dataset_version,...
    strcat(dark_image_rel_file_names, '_', dataset_version, '.png'));

number_of_images = length(dark_image_file_names);

% Initial semantic labelings of dark input images to be refined via semantic
% labelings of corresponding light reference images. Their basenames are derived
% from the respective names of the RGB images.
switch subset
    case 'train'
        split_dark_subdirectory = strcat('Dark_Zurich_', split_dark);
    case 'test'
        split_dark_subdirectory = 'Dark_Zurich_test04';
end
dark_segmentation_results_directory =...
    fullfile(segmentation_results_root_directory, model_directory,...
    split_dark_subdirectory, strcat(model_configuration_prefix,...
    model_configuration_dark), model_results_leaf_path);
[~, dark_image_basenames] = cellfun(@fileparts, dark_image_rel_file_names,...
    'UniformOutput', false);
dark_segmentation_file_names = fullfile(dark_segmentation_results_directory,...
    strcat(dark_image_basenames, '_', dataset_version, segmentation_format));

% Features of dark input images to be used for motion extraction.
dark_feature_results_directory = fullfile(feature_results_root_directory,...
    feature_results_intermediate_path);
dark_feature_file_names = fullfile(dark_feature_results_directory,...
    strcat(dark_image_rel_file_names, feature_format));

% Light reference images assigned to dark input images.
switch subset
    case 'train'
        light_image_assigned_rel_file_names = cell(0, 1);
        lists_corresp_files = full_paths_list(Dark_Zurich_corresp_directory,...
            '**/*_ref_day.csv');
        n_corresp_files = length(lists_corresp_files);
        for i = 1:n_corresp_files
            fid = fopen(lists_corresp_files{i});
            current_corresps = textscan(fid, '%s');
            fclose(fid);
            current_corresps = current_corresps{1};
            n_pairs = size(current_corresps, 1);
            current_light_image_rel_file_names = cell(n_pairs, 1);
            for j = 1:n_pairs
                current_corresps_parts = strsplit(current_corresps{j}, ',');
                current_light_image_rel_file_names{j} =...
                    current_corresps_parts{2};
            end
            light_image_assigned_rel_file_names =...
                [light_image_assigned_rel_file_names;
                 current_light_image_rel_file_names];
        end
    case 'test'
        % For the test set, the daytime reference set is already structured
        % according to the correspondences to the dark set.
        list_of_assigned_light_images_file = 'test_ref_filenames.txt';
        fid = fopen(fullfile(Dark_Zurich_file_lists_directory,...
            list_of_assigned_light_images_file));
        light_image_assigned_rel_file_names = textscan(fid, '%s');
        fclose(fid);
        light_image_assigned_rel_file_names =...
            light_image_assigned_rel_file_names{1};
end

% Semantic labelings of light reference images used to refine the labelings of
% corresponding dark input images. Their basenames are derived from the
% respective names of the RGB images.
switch subset
    case 'train'
        split_light_subdirectory = strcat('Dark_Zurich_', split_light);
    case 'test'
        split_light_subdirectory = 'Dark_Zurich_test04RefDay';
end
light_segmentation_results_directory =...
    fullfile(segmentation_results_root_directory, model_directory,...
    split_light_subdirectory, strcat(model_configuration_prefix,...
    model_configuration_light), model_results_leaf_path);
[~, light_image_assigned_basenames] = cellfun(@fileparts,...
    light_image_assigned_rel_file_names, 'UniformOutput', false);
light_segmentation_assigned_file_names =...
    fullfile(light_segmentation_results_directory,...
    strcat(light_image_assigned_basenames, '_', dataset_version,...
    segmentation_format));

% Hard semantic labelings of light reference images.
light_hard_segmentation_results_directory =...
    fullfile(segmentation_results_root_directory, model_directory,...
    split_light_subdirectory, strcat(model_configuration_prefix,...
    model_configuration_light), 'labelTrainIds');
light_hard_segmentation_assigned_file_names =...
    fullfile(light_hard_segmentation_results_directory,...
    strcat(light_image_assigned_basenames, '_', dataset_version, '.png'));

% Features of light reference images to be used for motion extraction.
light_feature_results_directory = fullfile(feature_results_root_directory,...
    feature_results_intermediate_path);
light_feature_file_names = fullfile(light_feature_results_directory,...
    strcat(light_image_assigned_rel_file_names, feature_format));

% Disparity maps of light reference images to be used for warping to target
% views.
light_disparity_results_directory = fullfile(depth_results_root_directory,...
    depth_results_intermediate_path, 'Dark_Zurich', depth_results_leaf_path);
light_disparity_file_names = fullfile(light_disparity_results_directory,...
    strcat(light_image_assigned_rel_file_names, depth_format));

% ------------------------------------------------------------------------------

% Determine current batch.

% Determine the set of images that are to be processed in the current task.
batch_ind = (task_id - 1) * images_per_task + 1:task_id * images_per_task; 
if batch_ind(1) > number_of_images
    return;
end
if batch_ind(end) > number_of_images
    % Truncate for last task.
    batch_ind = batch_ind(1:number_of_images - batch_ind(1) + 1);
end

% ------------------------------------------------------------------------------

% Instantiate individual components of the semantic segmentation refinement
% pipeline that are required for the selected variant and set their parameters.

% Number of Cityscapes evaluation classes.
n_classes = 19;

switch variant_abbreviation
    case 'warpDepthAlternBilateral_confProportionDyn'
        camera_motion_extraction_method = @motion_from_feature_points;
        camera_motion_extraction_parameters.nn_to_2nn_ratio = sqrt(0.7);
        camera_motion_extraction_parameters.theta_rel = 20;
        camera_motion_extraction_parameters.theta_inlier = 2;
        camera_motion_extraction_parameters.fov_horizontal_deg = 64.4;
        light_segmentation_warping_method = @depth_based_warping_with_quad_mesh;
        light_segmentation_filtering_method =...
            @soft_prediction_cross_bilateral_filtering_with_color_reference;
        filter_parameters.sigma_spatial = 80;
        filter_parameters.sampling_spatial = 20;
        filter_parameters.sigma_intensity = 0.1;
        filter_parameters.sampling_intensity = 0.1;
        filter_parameters.kernel_radius_in_std = 1;
        segmentation_fusion_method =...
            @fuse_soft_predictions_adaptive_confidence_proportion_dynamic;
        fusion_parameters.alpha_high = 0.6;
        fusion_parameters.alpha_low = 0.3;
        fusion_parameters.thresh_daytime_confidence_for_twilight_prediction = 0.2;
        fusion_parameters.thresh_twilight_confidence_for_daytime_prediction = 0.2;
        fusion_parameters.class_indices_dynamic = 12:19;
    case 'bilateralCrossColor_confProportion'
        light_segmentation_filtering_method =...
            @soft_prediction_cross_bilateral_filtering_with_color_reference;
        filter_parameters.sigma_spatial = 80;
        filter_parameters.sampling_spatial = 20;
        filter_parameters.sigma_intensity = 0.1;
        filter_parameters.sampling_intensity = 0.1;
        filter_parameters.kernel_radius_in_std = 1;
        segmentation_fusion_method =...
            @fuse_soft_predictions_adaptive_confidence_proportion;
        fusion_parameters.alpha = 0.6;
    case 'bilateralCrossColor_confProportionDyn'
        light_segmentation_filtering_method =...
            @soft_prediction_cross_bilateral_filtering_with_color_reference;
        filter_parameters.sigma_spatial = 80;
        filter_parameters.sampling_spatial = 20;
        filter_parameters.sigma_intensity = 0.1;
        filter_parameters.sampling_intensity = 0.1;
        filter_parameters.kernel_radius_in_std = 1;
        segmentation_fusion_method =...
            @fuse_soft_predictions_adaptive_confidence_proportion_dynamic;
        fusion_parameters.alpha_high = 0.6;
        fusion_parameters.alpha_low = 0.3;
        fusion_parameters.thresh_daytime_confidence_for_twilight_prediction = 0.2;
        fusion_parameters.thresh_twilight_confidence_for_daytime_prediction = 0.2;
        fusion_parameters.class_indices_dynamic = 12:19;
end

% ------------------------------------------------------------------------------

% Output specifications.

% Determine initial part of the path of output files.

switch variant_abbreviation
    case {'warpDepthAlternBilateral_confProportionDyn',...
            'bilateralCrossColor_confProportion',...
            'bilateralCrossColor_confProportionDyn'}
        refined_segmentations_output_directory_basename =...
            strcat(model_configuration_prefix, model_configuration_dark,...
            '_refined_', split_light, 'Gps_', variant_abbreviation);
        refined_segmentations_output_directory =...
            fullfile(segmentation_results_root_directory, model_directory,...
            split_dark_subdirectory,...
            refined_segmentations_output_directory_basename);
end

% ------------------------------------------------------------------------------

% Run segmentation refinement on current batch using the specified settings.

switch variant_abbreviation
    case 'warpDepthAlternBilateral_confProportionDyn'
        geometric_segmentation_refinement_batch(...
            dark_image_file_names(batch_ind),...
            dark_segmentation_file_names(batch_ind),...
            light_segmentation_assigned_file_names(batch_ind),...
            light_hard_segmentation_assigned_file_names(batch_ind),...
            light_disparity_file_names(batch_ind),...
            dark_feature_file_names(batch_ind),...
            light_feature_file_names(batch_ind),...
            camera_motion_extraction_method,...
            camera_motion_extraction_parameters,...
            light_segmentation_warping_method,...
            light_segmentation_filtering_method, filter_parameters,...
            segmentation_fusion_method, fusion_parameters,...
            n_classes, refined_segmentations_output_directory,...
            model_type, model_results_leaf_path);
    case {'bilateralCrossColor_confProportion',...
            'bilateralCrossColor_confProportionDyn'}
        segmentation_refinement_batch(dark_image_file_names(batch_ind),...
            dark_segmentation_file_names(batch_ind),...
            light_segmentation_assigned_file_names(batch_ind),...
            light_segmentation_filtering_method, filter_parameters,...
            segmentation_fusion_method, fusion_parameters,...
            n_classes, refined_segmentations_output_directory,...
            model_type, model_results_leaf_path);
end

end

