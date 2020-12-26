% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function output = joint_color_bilateral_upsampling(input_image, color_ref,...
    intensity_min, intensity_max, sigma_spatial, sigma_intensity, kernel_radius)
%JOINT_COLOR_BILATERAL_UPSAMPLING  Cross-bilateral filter using a
%higher-resolution image of color intensities as reference for defining
%filtering weights.
%
%   INPUTS:
%
%   -|input_image|: |input_height|-by-|input_width| matrix with elements of type
%    double. May contain |nan| elements, which correspond to pixels with missing
%    value. It is a required argument of the function.
%
%   -|color_ref|: 3D matrix with a larger number of rows and columns and the
%    same type and aspect ratio as |input_image|. Must not contain |nan| values.
%    It is a required argument of the function.
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
%   -|sigma_intensity|: standard deviation of the range Gaussian. Defaults to
%    |(intensity_max - intensity_min) / 10|.
%
%   -|kernel_radius|: "radius", i.e. half width, of the Gaussian kernel
%    tensor that is used in the bilateral grid approach, measured in units of
%    the respective standard deviation for each dimension.
%
%   OUTPUTS:
%
%   -|output|: filtered image as a matrix of the same size and type as
%    |input_image|.

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

H_d = size(input_image, 1);
W_d = size(input_image, 2);
C = size(input_image, 3);

if ~exist('sigma_spatial', 'var')
    sigma_spatial = min(W_d, H_d) / 64;
    fprintf('Using default sigma_spatial of: %f\n', sigma_spatial);
end

if ~exist('sigma_intensity', 'var')
    sigma_intensity = 0.1 * max(intensity_range);
    fprintf('Using default sigma_intensity of: %f\n', sigma_intensity);
end

if ~exist('kernel_radius', 'var')
    kernel_radius = 1;
end

% ------------------------------------------------------------------------------

% Compute image dimensions.
[H, W, ~] = size(color_ref);

% Define auxiliary image for bilinear interpolation application.
color_ref_help = padarray(color_ref, [1, 1, 0], 'replicate', 'post');

% Initialize output.
output = zeros(H, W, C);

for i = 1:H
    for j = 1:W
        % Compute corresponding coordinates of current pixel in downsampled
        % space.
        i_d = i * (H_d - 1) / (H - 1) + (H - H_d) / (H - 1);
        j_d = j * (W_d - 1) / (W - 1) + (W - W_d) / (W - 1);
        
        % Get the current neighborhood subscripts.
        k_d = max(1, round(i_d) - kernel_radius):min(H_d, round(i_d) + kernel_radius);
        l_d = max(1, round(j_d) - kernel_radius):min(W_d, round(j_d) + kernel_radius);
        
        % Map the neighborhood subscripts back to the upsampled space. Because
        % the decimation factor is generally not an integer, these subscripts
        % can assume fractional values.
        k = k_d * (H - 1) / (H_d - 1) - (H - H_d) / (H_d - 1);
        l = l_d * (W - 1) / (W_d - 1) - (W - W_d) / (W_d - 1);
        
        % Get floor and "ceiling" (floor + 1) values for these fractional
        % subscripts.
        k_f = floor(k);
        k_c = k_f + 1;
        l_f = floor(l);
        l_c = l_f + 1;
        
        % Create meshgrid for the neighborhood in the downsampled space.
        [L_d, K_d] = meshgrid(l_d, k_d);
        
        % Create bilinear interpolation weights.
        w_bilin_ff = (k_c - k).' * (l_c - l);
        w_bilin_fc = (k_c - k).' * (l - l_f);
        w_bilin_cf = (k - k_f).' * (l_c - l);
        w_bilin_cc = (k - k_f).' * (l - l_f);
        
        % Apply bilinear interpolation in the upsampled space to get color
        % values for pixels in the neighborhood.
        color_ref_neighb =...
            w_bilin_ff .* color_ref_help(k_f, l_f, :) +...
            w_bilin_fc .* color_ref_help(k_f, l_c, :) +...
            w_bilin_cf .* color_ref_help(k_c, l_f, :) +...
            w_bilin_cc .* color_ref_help(k_c, l_c, :);
        
        % Define unnormalized bilateral weights.
        w_spatial =...
            exp(-((L_d - j_d) .^ 2 + (K_d - i_d) .^ 2) / sigma_spatial ^ 2);
        w_range =...
            exp(-sum((color_ref_neighb - color_ref(i, j, :)) .^ 2, 3) /...
            sigma_intensity ^ 2);
        w_bilateral = w_spatial .* w_range;
        
        % Compute the normalization factor as the sum of the weights.
        norm_factor = sum(w_bilateral(:));
        
        % Obtain the weighted sum of input intensities with the unnormalized
        % weights.
        weighted_sum = sum(sum(input_image(k_d, l_d, :) .* w_bilateral, 1), 2);
        
        % Get the filtered output by normalizing the weighted sum with the
        % proper factor.
        output(i, j, :) = weighted_sum / norm_factor;
    end
end


end
