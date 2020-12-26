% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [output, mask_undefined] =...
    cross_bilateral_filter_color_reference_with_bilateral_grid(input_image,...
    color_ref, intensity_min, intensity_max, sigma_spatial, sampling_spatial,...
    sigma_intensity, sampling_intensity, kernel_radius_in_std)
%CROSS_BILATERAL_FILTER_COLOR_REFERENCE_WITH_BILATERAL_GRID  Cross-bilateral
%filter using an image of color intensities as reference for defining filtering
%weights. Implementation is based on the **bilateral grid** approach for
%performing approximate bilateral filtering, adjusted from the code provided by
%Jiawen Chen:
%http://people.csail.mit.edu/jiawen/software/bilateralFilter.m
%
%   INPUTS:
%
%   -|input_image|: |input_height|-by-|input_width| matrix with elements of type
%    double. May contain |nan| elements, which correspond to pixels with missing
%    value. It is a required argument of the function.
%
%   -|color_ref|: 3D matrix with the same number of rows and columns and the
%    same type as |input_image|. Must not contain |nan| values. It is a required
%    argument of the function.
%
%   -|intensity_min|: lower ends of range of values of |color_ref| channels.
%    Defaults to 1-by-3 array with minimum values in channels of |color_ref|.
%    Reflects prior knowledge about the domain of |color_ref|.
%
%   -|intensity_max|: upper ends of range of values of |color_ref| channels.
%    Defaults to 1-by-3 array with maximum values in channels of |color_ref|.
%    Reflects prior knowledge about the domain of |color_ref|.
% 
%   -|sigma_spatial|: standard deviation of the space Gaussian. Defaults to
%    |min(input_width, input_height) / 16|.
%
%   -|sampling_spatial|: amount of downsampling used for the approximation in
%    the spatial domain. Defaults to |sigma_spatial|.
%
%   -|sigma_intensity|: standard deviation of the range Gaussian. Defaults to
%    |(intensity_max - intensity_min) / 10|.
%
%   -|sampling_intensity|: amount of downsampling used for the approximation in
%    the intensity range domain. Defaults to |sigma_intensity|.
%
%   -|kernel_radius_in_std|: "radius", i.e. half width, of the Gaussian kernel
%    tensor that is used in the bilateral grid approach, measured in units of
%    the respective standard deviation for each dimension.
%
%   OUTPUTS:
%
%   -|output|: filtered image as a matrix of the same size and type as
%    |input_image|.
%
%   -|mask_undefined|: |input_height|-by-|input_width| matrix of logical values.
%    True where and only where |output| is well-defined.

if ndims(input_image) > 2
    error('Input to filter must be a grayscale image with size [height, width]');
end

if ~isa(input_image, 'double')
    error('Input to filter must be of type "double"');
end

if ~exist('color_ref', 'var')
    error('Color reference image is required for dual-range color cross-bilateral filter.');
end

if ndims(color_ref) ~= 3
    error(strcat('Color reference image must be a color image',...
        ' with size [height, width]'));
end

if ~isa(color_ref, 'double')
    error('Color reference image must be of type "double"');
end

if any(any(isnan(color_ref)))
    error('Color reference image must not contain any NaN element');
end

if ~exist('intensity_min', 'var')
    intensity_min = shiftdim(min(min(color_ref, [], 1), [], 2)).';
    warning('intensity_min not set!  Defaulting to: %f\n', intensity_min);
end

if ~exist('intensity_max', 'var')
    intensity_max = shiftdim(max(max(color_ref, [], 1), [], 2)).';
    warning('intensity_max not set!  Defaulting to: %f\n', intensity_max);
end

intensity_range = intensity_max - intensity_min;

input_height = size(input_image, 1);
input_width = size(input_image, 2);

if ~exist('sigma_spatial', 'var')
    sigma_spatial = min(input_width, input_height) / 64;
    fprintf('Using default sigma_spatial of: %f\n', sigma_spatial);
end

if ~exist('sigma_intensity', 'var')
    sigma_intensity = 0.1 * max(intensity_range);
    fprintf('Using default sigma_intensity of: %f\n', sigma_intensity);
end

if ~exist('sampling_spatial', 'var') || isempty(sampling_spatial)
    sampling_spatial = sigma_spatial;
end

if ~exist('sampling_intensity', 'var') || isempty(sampling_intensity)
    sampling_intensity = sigma_intensity;
end

if ~exist('kernel_radius_in_std', 'var')
    kernel_radius_in_std = 1;
end

if any(size(input_image) ~= [size(color_ref, 1), size(color_ref, 2)])
    error('Input, labels and color reference must be of the same size');
end

% ------------------------------------------------------------------------------

% Parameters.
derived_sigma_spatial = sigma_spatial / sampling_spatial;
derived_sigma_intensity = sigma_intensity / sampling_intensity;

padding_XY = floor(2 * derived_sigma_spatial) + 1;
padding_intensity = floor(2 * derived_sigma_intensity) + 1;

% ------------------------------------------------------------------------------

% 1) Downsampling.

% Split the three channels of the color reference image.
color_1 = color_ref(:, :, 1);
color_2 = color_ref(:, :, 2);
color_3 = color_ref(:, :, 3);

% Compute size of downsampled dimensions of bilateral grids.
downsampled_width =...
    floor((input_width - 1) / sampling_spatial) + 1 + 2 * padding_XY;
downsampled_height =...
    floor((input_height - 1) / sampling_spatial) + 1 + 2 * padding_XY;
downsampled_intensity_range =...
    floor(intensity_range / sampling_intensity) + 1 +...
    2 * repmat(padding_intensity, 1, 3);

% Compute indices for bilateral grid.
[jj, ii] = meshgrid(0:input_width - 1, 0:input_height - 1);
di = round(ii / sampling_spatial) + padding_XY + 1;
dj = round(jj / sampling_spatial) + padding_XY + 1;

dc1 = round((color_1 - intensity_min(1)) / sampling_intensity) +...
    padding_intensity + 1;
dc2 = round((color_2 - intensity_min(2)) / sampling_intensity) +...
    padding_intensity + 1;
dc3 = round((color_3 - intensity_min(3)) / sampling_intensity) +...
    padding_intensity + 1;

% Calculate auxiliary matrices that are used to populate the bilateral grid by
% handling NaN values as zeros, i.e. ignoring their contribution.
input_nan_mask = isnan(input_image);
input_image_nans_as_zeros = input_image;
input_image_nans_as_zeros(input_nan_mask) = 0;
% Abusive variable name. After the following assignment, |input_nan_mask| is
% rather a mask of non-NaN values.
input_nan_mask = double(~input_nan_mask);

% Compute the bilateral grid for intensity with one shot using |accumarray|,
% which accumulates all the values that correspond to a single subscript tuple
% by default.

intensity_grid_image =...
    accumarray([di(:), dj(:), dc1(:), dc2(:), dc3(:)],...
    input_image_nans_as_zeros(:), [downsampled_height, downsampled_width,...
    downsampled_intensity_range]);
intensity_grid_weights =...
    accumarray([di(:), dj(:), dc1(:), dc2(:), dc3(:)], input_nan_mask(:),...
    [downsampled_height, downsampled_width, downsampled_intensity_range]);

% Build the 3D kernel corresponding to the intensity grid.

kernel_width = 2 * ceil(kernel_radius_in_std * derived_sigma_spatial) + 1;
kernel_height = kernel_width;

kernel_half_width = floor(kernel_width / 2);
kernel_half_height = floor(kernel_height / 2);

intensity_kernel_depth =...
    2 * ceil(kernel_radius_in_std * derived_sigma_intensity) + 1;
intensity_kernel_half_depth = floor(intensity_kernel_depth / 2);

[grid_X, grid_Y, grid_C1, grid_C2, grid_C3] = ndgrid(0:kernel_width - 1,...
    0:kernel_height - 1, 0:intensity_kernel_depth - 1,...
    0:intensity_kernel_depth - 1, 0:intensity_kernel_depth - 1);
grid_X = grid_X - kernel_half_width;
grid_Y = grid_Y - kernel_half_height;
grid_C1 = grid_C1 - intensity_kernel_half_depth;
grid_C2 = grid_C2 - intensity_kernel_half_depth;
grid_C3 = grid_C3 - intensity_kernel_half_depth;
grid_R_squared =...
    (grid_X .* grid_X + grid_Y .* grid_Y) / (derived_sigma_spatial ^ 2) +...
    (grid_C1 .* grid_C1 + grid_C2 .* grid_C2 + grid_C3 .* grid_C3) /...
    (derived_sigma_intensity ^ 2);
intensity_kernel = exp(-0.5 * grid_R_squared);
intensity_kernel = intensity_kernel ./ sum(intensity_kernel(:));

% ------------------------------------------------------------------------------

% 2) Convolution.

blurred_intensity_grid_image =...
    convn(intensity_grid_image, intensity_kernel, 'same');
blurred_intensity_grid_weights =...
    convn(intensity_grid_weights, intensity_kernel, 'same');

% ------------------------------------------------------------------------------

% 3) Upsampling and slicing.

% Indices for upsampling: no rounding.
di = (ii / sampling_spatial) + padding_XY + 1;
dj = (jj / sampling_spatial) + padding_XY + 1;
dc1 = (color_1 - intensity_min(1)) / sampling_intensity +...
    padding_intensity + 1;
dc2 = (color_2 - intensity_min(2)) / sampling_intensity +...
    padding_intensity + 1;
dc3 = (color_3 - intensity_min(3)) / sampling_intensity +...
    padding_intensity + 1;

% Use |interpn| to retrieve the filtering output using interpolation from the
% samples of the bilateral grid. Interpolation is linear in all cases.
unnormalized_intensity_filtered =...
    interpn(blurred_intensity_grid_image, di, dj, dc1, dc2, dc3);
intensity_weights = interpn(blurred_intensity_grid_weights, di, dj, dc1, dc2,...
    dc3);

% ------------------------------------------------------------------------------

% 4) Division nonlinearity.

% Form denominator of the division.
denominator = intensity_weights;

% Identify pixels where the output is not defined, i.e. the denominator is equal
% to zero, and set them to a non-zero value; corresponding elements of output
% are anyway irrelevant.
mask_undefined = denominator == 0;
denominator(mask_undefined) = -eps;

% Weighted average of the two ranges: the label range and the intensity range.
output = unnormalized_intensity_filtered ./ denominator;

% Put zeros by convention where output is undefined.
% Implicit assumption: |input_image| contains positive values.
output(mask_undefined) = 0;

end
