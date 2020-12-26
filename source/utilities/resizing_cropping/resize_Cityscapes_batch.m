% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function resize_Cityscapes_batch(image_file_names, resize_dims,...
    resize_root_directory, resize_attributes_suffix, output_format)
%RESIZE_CITYSCAPES_BATCH  Resize images from Cityscapes.
%
%   INPUTS:
%
%   -|image_file_names|: cell array of strings with full paths to input images.
%
%   -|resize_dims|: 1-by-2 matrix with dimensions of resized output images in
%   format [rows, columns]. Common for all processed images in the batch.
%
%   -|resize_root_directory|: full path to root directory where the resized
%   Cityscapes images are saved.
%
%   -|resize_attributes_suffix|: string containing attribute of resizing, e.g.,
%   '360', '512'.
%
%   -|output_format|: string specifying the image format for the output images,
%   e.g. '.png'

% Total number of processed images. Should be equal to number of files for each
% auxiliary set.
number_of_images = length(image_file_names);

% Crop and save images.
for i = 1:number_of_images
    
    % Read input image.
    I = imread(image_file_names{i});
    
    % Bring image to standard double format in [0, 1] range.
    I = im2double(I);
    
    % Resize to the specified dimensions.
    I_rsz = resize_image(I, resize_dims(1), resize_dims(2));
    
    % Save the resized image in the output directory.
    
    % The name of and path to the output image is based on the input image.
    [path_to_input, I_name] = fileparts(image_file_names{i});
    
    % Suffix specifying the resizing attributes.
    resize_suffix = strcat('_resize_', resize_attributes_suffix);
    
    % Full names of output images formed by the name of the input image and the
    % suffices.
    I_rsz_name_with_extension = strcat(I_name, resize_suffix, output_format);
    
    % Determine output directories based on the directory structure of original
    % Cityscapes dataset: 1) train-val-test directories, 2) city directories.
    path_to_input_split = strsplit(path_to_input, filesep);
    current_resize_output_directory = fullfile(resize_root_directory,...
        path_to_input_split{end - 1}, path_to_input_split{end});
    
    % Create output directory where the resized image will be saved, if it does
    % not already exist.
    if ~exist(current_resize_output_directory, 'dir')
        mkdir(current_resize_output_directory);
    end
    
    % Build full path from file name and output directory and save it.
    imwrite(I_rsz,...
        fullfile(current_resize_output_directory, I_rsz_name_with_extension));
    
end

end

