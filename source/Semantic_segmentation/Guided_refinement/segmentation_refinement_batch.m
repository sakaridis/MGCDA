% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function segmentation_refinement_batch(dark_image_file_names,...
    dark_segmentation_initial_file_names,...
    light_segmentation_assigned_file_names,...
    light_segmentation_filtering_method, filter_parameters,...
    segmentation_fusion_method, fusion_parameters, n_classes,...
    refined_segmentations_output_directory, model_type, model_results_leaf_path)
%SEGMENTATION_REFINEMENT_BATCH  Refine segmentations of dark images into
%Cityscapes classes via segmentations of corresponding lighter images.

% Total number of processed images. Should be equal to number of files for each
% auxiliary set.
number_of_images = length(dark_image_file_names);
assert(number_of_images == length(dark_segmentation_initial_file_names));
assert(number_of_images == length(light_segmentation_assigned_file_names));

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
 
for i = 1:number_of_images
    
    % The name of the refined prediction is the same as the initial prediction.
    [~, S_dark_refined_basename] =...
        fileparts(dark_segmentation_initial_file_names{i});
    
    % Check whether result has been already computed, and if yes, continue with
    % the next image.
    if exist(fullfile(refined_segmentations_soft_output_directory,...
            strcat(S_dark_refined_basename, output_format_soft)), 'file')
        % Display progress.
        fprintf('Processed %d/%d images.\n', i, number_of_images);
        continue;
    end
    
    % Read dark image and bring it to double precision for subsequent
    % computations.
    I_dark = im2double(imread(dark_image_file_names{i}));
    
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
    
    % Filter the segmentation of the light image, using the dark image as
    % reference.
    fprintf('Filtering for %d-th image....\n', i);
    S_light_filtered = light_segmentation_filtering_method(S_light_init,...
        I_dark, filter_parameters);
    fprintf('Completed filtering for %d-th image.\n', i);
    
    % Fuse the initial segmentation of the dark image with the filtered
    % segmentation of the light image to get the refined segmentation of the
    % dark image.
    S_dark_refined = segmentation_fusion_method(S_dark_init,...
        S_light_filtered, fusion_parameters);
    
    % Infer the hard version of the refined segmentation in train IDs format.
    [~, S_dark_refined_hard_indices] = max(S_dark_refined, [], 3);
    S_dark_refined_hard = uint8(S_dark_refined_hard_indices - 1);
    
    % Convert the hard prediction to labelIDs and color format.
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
    
    % Display progress.
    fprintf('Processed %d/%d images.\n', i, number_of_images);
    
end

end

