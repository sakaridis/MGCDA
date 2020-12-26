% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function joint_color_bilateral_upsampling_for_dataset(task_id,...
    images_per_task, dataset_source, dataset_source_split, dataset_stylized,...
    dataset_source_root_directory, dataset_stylized_root_directory,...
    CycleGAN_configs, input_suffix,...
    output_suffix, output_root_directory)
%JOINT_COLOR_BILATERAL_UPSAMPLING_FOR_DATASET  Apply joint bilateral upsampling
%to a batch of images from an input dataset and write the results. Structured
%for execution on a cluster.
%
%   INPUTS:
%
%   -|task_id|: ID of the task. Used to determine which images out of the entire
%    dataset will form the batch that will be processed by this task.
%
%   -|images_per_task|: maximum number of images for which joint bilateral
%    upsampling is run in each task.
%
%   -|dataset_source|: string containing the name of the dataset with source
%    images, e.g. 'Cityscapes'.
%
%   -|dataset_source_split|: string indicating which subset of the source
%    dataset is used in the experiment, e.g. 'trainval'.
%
%   -|dataset_stylized|: string containing the name of the dataset with stylized
%    images deriving from the source ones, e.g. 'Dark_Cityscapes'.
%
%   -|dataset_source_root_directory|: full path to root directory of the dataset
%    with source images.
%
%   -|dataset_stylized_root_directory|: full path to root directory of the
%    dataset with intermediate stylized images.
%
%   -|CycleGAN_configs|: string that summarizes the configuration of the
%    preceding style transfer experiment which produced the intermediate
%    stylized images that are input together with the source images to joint
%    bilateral upsampling, e.g. 'DarkZurichNight_resize_360'
%
%   -|output_root_directory|: path to directory under which the results of the
%    experiment are written (relative or absolute), e.g.
%    '../../../../data/Dark_Cityscapes'.

% Add paths to functions that are called for joint bilateral upsampling.

current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, '..', 'Color_transformations'));

% ------------------------------------------------------------------------------

% Create lists of input files for the two relevant modalities: source daytime
% images and intermediate stylized outputs after the CycleGAN step.

% Define path parts and components of names of list files.
datasets_list_file_prefixes =...
    containers.Map({'Cityscapes', 'Dark_Cityscapes'},...
    {'leftImg8bit_', 'leftImg8bit_'});
datasets_source_list_file_suffixes =...
    containers.Map({'Cityscapes'}, {'_filenames.txt'});
datasets_stylized_list_file_suffixes =...
    containers.Map({'Dark_Cityscapes'}, {'_filenames.txt'});
datasets_stylized_list_file_infixes =...
    containers.Map({'Dark_Cityscapes'}, {'_dark_CycleGAN_'});
datasets_source_RGB_directory_prefixes =...
    containers.Map({'Cityscapes'}, {'leftImg8bit_'});
datasets_source_subdir_depth = containers.Map({'Cityscapes'}, {3});

% Construct paths to directories containing list files.
dataset_source_file_lists_directory = fullfile(current_script_directory,...
    '..', '..', 'data', 'Cityscapes_lists_file_names');
dataset_stylized_file_lists_directory = dataset_source_file_lists_directory;

% Source images.
list_file_source = strcat(datasets_list_file_prefixes(dataset_source),...
    dataset_source_split, datasets_source_list_file_suffixes(dataset_source));
list_file_source_full_name = fullfile(dataset_source_file_lists_directory,...
    list_file_source);
fid = fopen(list_file_source_full_name);
source_file_names = textscan(fid, '%s');
fclose(fid);
source_file_names = source_file_names{1};
n_images = length(source_file_names);
source_full_file_names = fullfile(dataset_source_root_directory,...
    source_file_names);

% Intermediate stylized images at low resolution.
list_file_stylized = strcat(datasets_list_file_prefixes(dataset_stylized),...
    dataset_source_split,...
    datasets_stylized_list_file_infixes(dataset_stylized), CycleGAN_configs,...
    datasets_stylized_list_file_suffixes(dataset_stylized));
list_file_stylized_full_name =...
    fullfile(dataset_stylized_file_lists_directory, list_file_stylized);
fid = fopen(list_file_stylized_full_name);
stylized_file_names = textscan(fid, '%s');
fclose(fid);
stylized_file_names = stylized_file_names{1};
stylized_full_file_names = fullfile(dataset_stylized_root_directory,...
    stylized_file_names);

% Sanity check. Total number of files should be identical for both modalities.
assert(n_images == length(stylized_file_names));

% ------------------------------------------------------------------------------

% Parameters for joint bilateral upsampling.

bilateral_parameters.sigma_spatial = 0.5;
bilateral_parameters.sigma_intensity = 0.1;
bilateral_parameters.kernel_radius = 2;

% ------------------------------------------------------------------------------

% Determine current batch.

% Determine the set of images that are to be processed in the current task.
batch_ind = (task_id - 1) * images_per_task + 1:task_id * images_per_task; 
if batch_ind(1) > n_images
    return;
end
if batch_ind(end) > n_images
    % Truncate for last task.
    batch_ind = batch_ind(1:n_images - batch_ind(1) + 1);
end

% ------------------------------------------------------------------------------

% Output specifications.

% Specify output format for synthetic dark output images.
output_format = '.png';

% Determine initial part of the path to output images.
output_subdirectory =...
    strcat(datasets_source_RGB_directory_prefixes(dataset_source),...
    dataset_source_split,...
    datasets_stylized_list_file_infixes(dataset_stylized), CycleGAN_configs,...
    '_upsampled');
output_directory = fullfile(output_root_directory, output_subdirectory);

dataset_source_subdir_depth = datasets_source_subdir_depth(dataset_source);

% ------------------------------------------------------------------------------

% Run joint bilateral upsampling on current batch using the specified settings.
joint_color_bilateral_upsampling_batch(stylized_full_file_names(batch_ind),...
    source_full_file_names(batch_ind), bilateral_parameters,...
    output_directory, dataset_source_subdir_depth, input_suffix,...
    output_suffix, output_format);

end

