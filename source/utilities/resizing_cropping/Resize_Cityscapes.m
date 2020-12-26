% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function Resize_Cityscapes(task_id, dataset_split, resize_dims,...
    resize_attributes_suffix, input_root_directory, output_root_directory,...
    images_per_task)
%RESIZE_CITYSCAPES  Resize a batch of images from Cityscapes
%and write the results. Structured for execution on a cluster.
%   INPUTS:
%
%   -|task_id|: ID of the task. Used to determine which images out of the entire
%    dataset will form the batch that will be processed by this task.
%
%   -|dataset_split|: string that indicates which subset of Cityscapes is used
%    for resizing, e.g. 'trainval', 'train_extra'.
%
%   -|resize_dims|: 1-by-2 matrix with dimensions of resized output images in
%   format [rows, columns]. Common for all processed images in the batch.
%
%   -|resize_attributes_suffix|: string containing attribute of resizing, e.g.,
%   '360', '512'.
%
%   -|input_root_directory|: full path to directory under which the input images
%    for resizing are located.
%
%   -|output_root_directory|: full path to directory under which the results of 
%    resizing are written.
%
%   -|images_per_task|: maximum number of images for which fog simulation is run
%    in each task.
%    19997 train_extra Cityscapes images -> 200 images per task * 100 tasks.
%    19997 train_extra Cityscapes images -> 400 images per task * 50 tasks.
%    19997 train_extra Cityscapes images -> 1000 images per task * 20 tasks.
%    5000 trainvaltest Cityscapes images -> 50 images per task * 100 tasks.
%    550 trainval refined Cityscapes images -> 11 images per task * 50 tasks.

if ischar(task_id)
    task_id = str2double(task_id);
end

% ------------------------------------------------------------------------------

% Add paths to functions that are called for fog simulation.

current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
% Add path to |utilities| directory.
addpath(fullfile(current_script_directory, '..'));

% ------------------------------------------------------------------------------

% Create lists of input files for various modalities.

cityscapes_file_lists_directory = fullfile(current_script_directory,...
    '..', '..', '..', 'data', 'Cityscapes_lists_file_names');

% Left input images.
list_of_left_images_file = strcat('leftImg8bit_', dataset_split,...
    '_filenames.txt');
fid = fopen(fullfile(cityscapes_file_lists_directory,...
    list_of_left_images_file));
image_leaf_paths = textscan(fid, '%s');
fclose(fid);
image_leaf_paths = image_leaf_paths{1};
image_full_paths = fullfile(input_root_directory, image_leaf_paths);

number_of_images = length(image_leaf_paths);

% ------------------------------------------------------------------------------

% Determine current batch.

% Determine the set of images that are to be processed in the current task.
batch_ind = (task_id - 1) * images_per_task + 1:task_id * images_per_task; 
if batch_ind(1) > number_of_images
    return;
end
if batch_ind(end) > number_of_images
    % Truncate for last task.
    batch_ind = batch_ind(1:number_of_images - batch_ind(1) + 1);
end

% ------------------------------------------------------------------------------

% Output specifications.

% Specify output format for resized images.
output_format = '.png';

% Determine initial part of the path of output files.

output_directories_basename = strcat('leftImg8bit_',...
    dataset_split, '_orig', '_resize_', resize_attributes_suffix);
output_resize_directory =...
    fullfile(output_root_directory, output_directories_basename);

% ------------------------------------------------------------------------------

% Run resizing on current batch using the specified settings.

resize_Cityscapes_batch(image_full_paths(batch_ind), resize_dims,...
    output_resize_directory, resize_attributes_suffix, output_format);

end

