% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function mean_IoU_images = mean_IoU_per_image(intersection_counts, union_counts)
%MEAN_IOU_PER_IMAGE  Compute mean IoU score separately for each image in a
%dataset.
%
% Inputs:
%
% - intersection_counts: K-by-N matrix, where K is the number of evaluation
%   classes and N is the number of images for the processed dataset. The
%   (k,n)-th element of this matrix specifies the number of true positive pixels
%   for the evaluated method on class k and image n.
%
% - union_counts: same as intersection_counts, but each element specifies the
%   number of (true positive + false positive + false negative) pixels.
%
% Outputs:
%
% - mean_IoU_images: 1-by-N vector. The n-th element of this vector holds the
%   mean IoU score of the evaluated method on image n, taking into account
%   those classes k for which union_counts(k,n) > 0 when taking the mean and
%   setting the IoU scores for the rest of the classes to 1.

[K, N] = size(intersection_counts);

% Check that the dimensions of the two inputs match exactly before performing
% an element-wise division.
assert(~any(size(union_counts) - [K, N]));

% Element-wise division to get IoU scores per class and image. May output NaN
% values when both the numerator and denominator equal zero. These NaN values
% are detected and ignored in subsequent steps.
IoU_with_nans = intersection_counts ./ union_counts;

% Initialize output.
mean_IoU_images = zeros(1, N);

% Loop over all images to compute output.
for n = 1:N
    IoU_cur = IoU_with_nans(:, n);
    nonexistent_classes = isnan(IoU_cur);
    mean_IoU_existent_classes = mean(IoU_cur(~nonexistent_classes));
    n_nonexistent_classes = sum(nonexistent_classes);
    % Weighted mean between existent classes and non-existent ones, for which
    % IoU is defined as 1.
    mean_IoU_images(n) =...
        (mean_IoU_existent_classes * (K - n_nonexistent_classes) +...
        1 * n_nonexistent_classes) / K;
end

end

