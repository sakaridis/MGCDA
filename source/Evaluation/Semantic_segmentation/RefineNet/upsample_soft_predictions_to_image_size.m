% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function soft_predictions_resized = upsample_soft_predictions_to_image_size(...
    soft_predictions_file, hard_predictions_file, n_classes)
%UPSAMPLE_SOFT_PREDICTIONS_TO_IMAGE_SIZE  Read softmax map that is saved while
%testing RefineNet and upsample it to original image resolution, using the same
%steps as in the original RefineNet implementation for generating the hard
%prediction.

% Load soft prediction. Load |data_obj|, whose |score_map| constitutes the soft
% prediction. |score_map| is assumed to be in single format.
load(soft_predictions_file, 'data_obj');
% soft_predictions_with_void = gather(data_obj.score_map);
soft_predictions_with_void = data_obj.score_map;

% Optional step (ensures correct range of softmax values before casting to log
% space).
% soft_predictions_with_void = soft_predictions_with_void ./...
%     sum(soft_predictions_with_void, 3);

% Resize predictions to match the size of the original image, which is
% identified via the available hard predictions file. Perform resizing in log
% space.
hard_predictions = imread(hard_predictions_file);
[H, W] = size(hard_predictions);
soft_predictions_help = log(soft_predictions_with_void);
soft_predictions_help = max(soft_predictions_help, -20);
soft_predictions_help = imresize(soft_predictions_help, [H, W], 'bicubic');
soft_predictions_resized_unnormalized = exp(soft_predictions_help);

% Renormalize predictions after removing the one corresponding to the void
% class.
soft_predictions_resized = soft_predictions_resized_unnormalized(:, :,...
    1:n_classes);
soft_predictions_resized = soft_predictions_resized ./...
    sum(soft_predictions_resized, 3);

end

