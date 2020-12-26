% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function Cityscapes_compute_and_save_labelTrainIds_from_label_colors(...
    label_colors_directory, labelTrainIds_directory)

output_format = '.png';

current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, '..', 'utilities'));
file_names = file_full_names_in_directory(strcat(label_colors_directory,...
    filesep));
number_of_images = length(file_names);

% Create output directory where modified ground truth images will be saved, if
% it does not already exist.
if exist(labelTrainIds_directory) ~= 7
    mkdir(labelTrainIds_directory);
end

% Loop over all input ground truth images to compute and save the modified
% ground truth images in Cityscapes format.
for i = 1:number_of_images
    % Transform the labels.
    image_label_colors = imread(file_names{i});
    image_labelTrainIds =...
        cityscapes_colors2labelTrainIds(image_label_colors);
    
    % Save the label image with label colors in the output directory.
    [~, image_colors_name] = fileparts(file_names{i});
    imwrite(image_labelTrainIds, fullfile(labelTrainIds_directory,...
        strcat(image_colors_name, output_format)));
end

end
