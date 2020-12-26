% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function prediction_output =...
    soft_prediction_cross_bilateral_filtering_with_color_reference(...
    prediction_input, I, cross_bilateral_filter_parameters, varargin)
%SOFT_PREDICTION_CROSS_BILATERAL_FILTERING_WITH_COLOR_REFERENCE  Filter a 3D
%tensor of soft predictions with a cross bilateral filter using a color image as
%reference.

current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, '..', '..', 'utilities'));
addpath_relative_to_caller(current_script_full_name,...
    fullfile('..', '..', 'Color_transformations'));

% Convert to unit range CIELAB.
I_CIELAB = RGB_to_CIELAB_unit_range(I);
intensity_min = shiftdim(min(min(I_CIELAB, [], 1), [], 2)).';
intensity_max = shiftdim(max(max(I_CIELAB, [], 1), [], 2)).';

% Read parameters for cross bilateral filter.
sigma_spatial = cross_bilateral_filter_parameters.sigma_spatial;
sampling_spatial = cross_bilateral_filter_parameters.sampling_spatial;
sigma_intensity = cross_bilateral_filter_parameters.sigma_intensity;
sampling_intensity = cross_bilateral_filter_parameters.sampling_intensity;
kernel_radius_in_std = cross_bilateral_filter_parameters.kernel_radius_in_std;

% Postprocess by filtering.

% Initialization.
n_channels = size(prediction_input, 3);
prediction_output = zeros(size(prediction_input));

for i = 1:n_channels
    % Filter each channel (the softmax map for each class) separately. This
    % separate filtering should already produce outputs that are normalized up
    % to numerical accuracy, since filter weights are normalized.
    prediction_output(:, :, i) =...
        cross_bilateral_filter_color_reference_with_bilateral_grid(...
        prediction_input(:, :, i), I_CIELAB, intensity_min, intensity_max,...
        sigma_spatial, sampling_spatial, sigma_intensity, sampling_intensity,...
        kernel_radius_in_std);
end

% Normalize the output soft predictions to account for potential numerical
% issues in the filtering.
prediction_output = prediction_output ./ sum(prediction_output, 3);

end

