% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function prediction_fused =...
    fuse_soft_predictions_adaptive_confidence_proportion(prediction_orig,...
    prediction_extra, fusion_parameters)
%FUSE_SOFT_PREDICTIONS_ADAPTIVE_CONFIDENCE_PROPORTION  Fuse two soft predictions
%for segmentation of the same image by adaptively weighting each of the two at
%each pixel with the proportion of its confidence over the sum of the
%confidences of both predictions at the pixel, i.e.
%w_orig = conf_orig / (conf_orig + alpha * conf_extra) and
%w_extra = alpha * conf_extra / (conf_orig + alpha * conf_extra)
%alpha regulates the effect of the extra prediction on the fused result.

% Read parameters for prediction fusion.
alpha = fusion_parameters.alpha;

% Compute the confidence map for both predictions.
conf_orig = max(prediction_orig, [], 3);
conf_extra = max(prediction_extra, [], 3);

% Fuse adaptively.
prediction_fused =...
    (conf_orig ./ (conf_orig + alpha * conf_extra)) .* prediction_orig...
    + (alpha * conf_extra ./ (conf_orig + alpha * conf_extra)) .* prediction_extra;

end

