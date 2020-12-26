% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function hard_prediction_indices =...
    soft_to_hard_prediction_with_invalid_regions(soft_prediction,...
    confidence_threshold)
%SOFT_TO_HARD_PREDICTION_WITH_INVALID_REGIONS  Convert soft prediction for
%semantic segmentation (class-wise probabilities at each pixel) to hard
%prediction with invalid regions where the confidence of the prediction is below
%a specified threshold.
%
%   INPUTS:
%
%   -|soft_prediction|: H-by-W-by-C 3D matrix with class-specific probabilities
%    at each pixel of the image, where C is the number of considered classes.
%
%   -|confidence_threshold|: scalar value in the range [0, 1] that defines the
%    threshold for the confidence (probability) of the prediction at each pixel
%    under which the prediction is deemed invalid.
%
%   OUTPUT:
%
%   -|hard_prediction_indices|: uint8 H-by-W 2D matrix containing the indices of
%    the predicted class labels (ranging from 1 to C), or 0 for invalid pixels.

[H, W, C] = size(soft_prediction);

% Assert that the input matrix |soft_prediction| contains class probability
% vectors.
assert(all(soft_prediction(:)) >= 0);
epsilon = 10 ^ -6;
assert(max(max(abs(sum(soft_prediction, 3) - ones(H, W)))) <= epsilon);

% Get hard prediction as the most probable class at each pixel, along with the
% associated confidence.
[confidence_soft_prediction, hard_prediction_indices] =...
    max(soft_prediction, [], 3);

% Set the pixels where the confidence for the predicted class is below the input
% threshold to invalid, assigning them 0 to distinguish from valid predicted
% class indices that range from 1 to C.
is_prediction_invalid = confidence_soft_prediction < confidence_threshold;
hard_prediction_indices(is_prediction_invalid) = 0;
hard_prediction_indices = uint8(hard_prediction_indices);

end

