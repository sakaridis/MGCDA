% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function soft_predictions_resized =...
    upsample_soft_predictions_to_image_size_double_format(...
    soft_predictions_file, hard_predictions_file, n_classes)
%UPSAMPLE_SOFT_PREDICTIONS_TO_IMAGE_SIZE_DOUBLE_FORMAT  Read softmax map that is
%saved in CPU while testing RefineNet, bring it to double format and upsample it
%to original image resolution, using the same steps as in the original RefineNet
%implementation for generating the hard prediction.

% Load soft prediction. Load |data_obj|, whose |score_map| constitutes the soft
% prediction. |data_obj.score_map| is originally in single format, which is why
% we cast it to double format to enhance the accuracy of the subsequent
% upsampling step.
load(soft_predictions_file, 'data_obj');
soft_predictions_with_void = data_obj.score_map;
soft_predictions_with_void = double(soft_predictions_with_void);

% Resize predictions to match the size of the original image, which is
% identified via the available hard predictions file. Perform resizing in log
% space.
hard_predictions = imread(hard_predictions_file);
[H, W, ~] = size(hard_predictions);
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

