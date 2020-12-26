% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function RefineNet_convert_ID_predictions_to_images(ID_predictions_directory,...
    images_directory)

output_format = '.png';

current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, '..', 'utilities'));
file_names = file_full_names_in_directory(strcat(ID_predictions_directory,...
    filesep));
number_of_images = length(file_names);

% Create output directory where prediction images will be saved, if it does not
% already exist.
if exist(images_directory) ~= 7
    mkdir(images_directory);
end

% Loop over all input .mat files to retrieve predicted IDs and save them as
% images in |images_directory|.
for i = 1:number_of_images
    % Loads |data_obj| variable into workspace.
    load(file_names{i});
    
    % Prediction is stored in |mask_data| field of |data_obj|.
    ID_prediction = data_obj.mask_data;
    
    % Save the prediction as an image.
    [~, image_name] = fileparts(file_names{i});
    imwrite(ID_prediction, fullfile(images_directory, strcat(image_name,...
        output_format)));
end

end
