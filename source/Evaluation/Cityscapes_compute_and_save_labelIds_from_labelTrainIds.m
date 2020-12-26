% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function Cityscapes_compute_and_save_labelIds_from_labelTrainIds(...
    labelTrainIds_directory, labelIds_directory)

output_format = '.png';

current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, '..', 'utilities'));
file_names = file_full_names_in_directory(strcat(labelTrainIds_directory,...
    filesep));
number_of_images = length(file_names);

% Create output directory where modified ground truth images will be saved, if
% it does not already exist.
if exist(labelIds_directory) ~= 7
    mkdir(labelIds_directory);
end

% Loop over all input ground truth images to compute and save the modified
% ground truth images in Cityscapes format.
for i = 1:number_of_images
    % Transform the labels.
    image_labelTrainIds = imread(file_names{i});
    image_labelIds = cityscapes_labelTrainIds2labelIds(image_labelTrainIds);
    
    % Save the label image with label IDs in the output directory.
    [~, image_labelIds_name] = fileparts(file_names{i});
    imwrite(image_labelIds, fullfile(labelIds_directory,...
        strcat(image_labelIds_name, output_format)));
end

end
