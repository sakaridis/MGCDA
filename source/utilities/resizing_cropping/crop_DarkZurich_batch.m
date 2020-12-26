% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function crop_DarkZurich_batch(image_file_names, crop_coords,...
    crop_root_directory, crop_attributes_suffix, output_format)
%CROP_DARKZURICH_BATCH  Crop images from Dark Zurich.
%   INPUTS:
%
%   -|image_file_names|: cell array of strings with full paths to input images.
%
%   -|crop_coords|: 1-by-4 matrix with crop coordinates in image coordinate
%   system and in format [top, left, bottom, right]. Common for all processed
%   images in the batch.
%
%   -|crop_root_directory|: full path to root directory where the cropped
%   Cityscapes images are saved.
%
%   -|crop_attributes_suffix|: string containing attribute of taken crop, e.g.,
%   'center', 'left'.
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
    
    % Crop to the specified coordinates.
    I_crop = crop_image(I, crop_coords);
    
    % Save the cropped image in the output directory.
    
    % The name of and path to the output image is based on the input image.
    [path_to_input, I_name] = fileparts(image_file_names{i});
    
    % Suffix specifying the crop attributes.
    crop_suffix = strcat('_crop_', crop_attributes_suffix);
    
    % Full names of output images formed by the name of the input image and the
    % suffices.
    I_crop_name_with_extension = strcat(I_name, crop_suffix, output_format);
    
    % Determine output directories based on the directory structure of original
    % Dark Zurich dataset: 1) sequence directories.
    path_to_input_split = strsplit(path_to_input, filesep);
    current_crop_output_directory = fullfile(crop_root_directory,...
        path_to_input_split{end - 2}, path_to_input_split{end - 1},...
        path_to_input_split{end});
    
    % Create output directory where the cropped image will be saved, if it does
    % not already exist.
    if ~exist(current_crop_output_directory, 'dir')
        mkdir(current_crop_output_directory);
    end
    
    % Build full path from file name and output directory and save it.
    imwrite(I_crop,...
        fullfile(current_crop_output_directory, I_crop_name_with_extension));
    
end

end

