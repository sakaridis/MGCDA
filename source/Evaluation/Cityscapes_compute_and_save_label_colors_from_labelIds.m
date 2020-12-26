% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function Cityscapes_compute_and_save_label_colors_from_labelIds(...
    labelIds_directory, label_colors_directory)

output_format = '.png';

current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, '..', 'utilities'));
file_names = file_full_names_in_directory(strcat(labelIds_directory,...
    filesep));
number_of_images = length(file_names);

% Create output directory where modified ground truth images will be saved, if
% it does not already exist.
if exist(label_colors_directory) ~= 7
    mkdir(label_colors_directory);
end

% Loop over all input ground truth images to compute and save the modified
% ground truth images in Cityscapes format.
for i = 1:number_of_images
    % Transform the labels.
    image_labelIds = imread(file_names{i});
    image_label_colors = cityscapes_labelIds2colors(image_labelIds);
    
    % Save the label image with label IDs in the output directory.
    [~, image_label_colors_name] = fileparts(file_names{i});
    imwrite(image_label_colors, fullfile(label_colors_directory,...
        strcat(image_label_colors_name, output_format)));
end

end
