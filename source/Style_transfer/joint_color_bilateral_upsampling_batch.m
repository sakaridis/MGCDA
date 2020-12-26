% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function joint_color_bilateral_upsampling_batch(stylized_file_names,...
    source_file_names, bilateral_parameters, output_directory,...
    stylized_subdirectories_depth, input_suffix, output_suffix, output_format)
%JOINT_COLOR_BILATERAL_UPSAMPLING_BATCH  Apply joint bilateral upsampling to a
%batch of images and write the results.
%
%   INPUTS:
%
%   -|stylized_file_names|: cell array of strings with full paths to
%    intermediate stylized outputs that are input to joint bilateral upsampling.
%
%   -|source_file_names|: cell array of strings with full paths to content
%    images that are used as reference in joint bilateral upsampling.
%
%   -|output_directory|: full path to root directory under which the output
%    images are saved.
%
%   -|stylized_subdirectories_depth|: positive integer specifying the number of
%    directory levels that are interposed between the root image directory of
%    the dataset comprising the images in the batch and the image files
%    themselves. This number is preserved in the output dataset.
%
%   -|output_format|: string specifying the image format for the output stylized
%    images after the application of joint bilateral upsampling, e.g. '.png'.

% Total number of processed images. Should be equal to number of files for each
% modality.
n_images = length(stylized_file_names);
assert(n_images == length(source_file_names));

% Decode parameters for joint bilateral upsampling.
sigma_spatial = bilateral_parameters.sigma_spatial;
sigma_intensity = bilateral_parameters.sigma_intensity;
kernel_radius = bilateral_parameters.kernel_radius;

% Compute and save synthetic dark images.
for i = 1:n_images
    
    % The name of and path to the output image are based on the input image.
    [current_input_directory, current_input_basename] =...
        fileparts(stylized_file_names{i});
    current_output_name =...
        strcat(strrep(current_input_basename, input_suffix, output_suffix),...
        output_format);
    
    % Generic directory name transformation from input to output, depending on
    % depth of subdirectories for the input dataset. ASSUMPTION: all input
    % images are located at the same directory level.
    
    input_subdirectories = [];
    input_path_temp = current_input_directory;
    
    % Get input subdirectories one by one.
    for j = 1:stylized_subdirectories_depth
        [input_path_temp, current_input_subdirectory] =...
            fileparts(input_path_temp);
        input_subdirectories =...
            [{current_input_subdirectory}, input_subdirectories];
    end
    
    % Concatenate input subdirectories into a single path component.
    input_subdirectories_concat = '';
    for j = 1:stylized_subdirectories_depth
        input_subdirectories_concat = fullfile(input_subdirectories_concat,...
            input_subdirectories{j});
    end
    
    % Append input subdirectories to base output directory |output_directory| in
    % order to form the current output directory.
    current_output_directory = fullfile(output_directory,...
        input_subdirectories_concat);
    
    % Build full path to output image.
    output_full_name = fullfile(current_output_directory, current_output_name);
    
    % --------------------------------------------------------------------------
    
    % If the output does not exist, compute and save it.
    if ~exist(output_full_name, 'file')
        
        % Create current output directory, if it does not already exist.
        if ~exist(current_output_directory, 'dir')
            mkdir(current_output_directory);
        end
        
        % Read inputs.
        I = im2double(imread(source_file_names{i}));
        I_CIELAB = RGB_to_CIELAB_unit_range(I);
        intensity_min = shiftdim(min(min(I_CIELAB, [], 1), [], 2)).';
        intensity_max = shiftdim(max(max(I_CIELAB, [], 1), [], 2)).';
        
        S = im2double(imread(stylized_file_names{i}));
        
        % Compute.
        S_upsampled = joint_color_bilateral_upsampling(S, I_CIELAB,...
            intensity_min, intensity_max, sigma_spatial, sigma_intensity,...
            kernel_radius);
        
        % Save.
        imwrite(S_upsampled, output_full_name);
    end
    
    % Display progress.
    fprintf('Processed images: %d/%d\n', i, n_images);
end

end

