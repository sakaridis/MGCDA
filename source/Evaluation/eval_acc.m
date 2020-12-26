% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [mean_IoU, IoU, mean_IoU_images] =...
    eval_acc(data_name, data_root, gt_list, save_gray_folder, pred_suffix,...
    save_root, save_flag)

% Inputs:
%
% - data_name: string containing the name of the dataset that is used for
%   evaluation. E.g. 'cityscapes', 'dark_zurich'
%
% - data_root: path to root directory of dataset relative to the directory of
%   this script
%
% - gt_list: relative path (w.r.t. the directory of this script) to .txt file
%   with list of GT paths for examined dataset, where the paths are relative to
%   data_root
%
% - save_gray_folder: directory with evaluated predictions. All PNG images in
%   this directory should correspond to prediction files, in label train ID
%   format.
%
% - pred_suffix: suffix for prediction files
%
% - save_root: full path to directory where result files are saved.
%
% - save_flag: boolean flag specifying whether outputs are saved or not.

current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, 'Semantic_segmentation'));
list = importdata(fullfile(current_script_directory, gt_list));
if strcmp(data_name, 'dark_zurich')
    list = fullfile(data_root, 'gt', strcat(list, '_gt_labelTrainIds.png'));
else
    list = fullfile(data_root, list);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Evaluation - aggregate results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load Cityscapes evaluation classes.
class_names = cityscapes_evaluation_classes();
n_classes = length(class_names);

% initialize statistics
cnt=0;
area_intersection = double.empty;
area_union = double.empty;
pixel_accuracy = double.empty;
pixel_correct = double.empty;
pixel_labeled = double.empty;

% main loop
for i = 1:numel(list)
    % check file existence
    fileAnno = list{i};
    strPred = strsplit(fileAnno, filesep);
    strPred = strPred{end};
    if strcmp(data_name,'cityscapes')
        strPred = strrep(strPred, '_gtFine_labelTrainIds', pred_suffix);
        strPred = strrep(strPred, '_gtCoarse_labelTrainIds', pred_suffix);
    end
    if strcmp(data_name, 'bdd100k')
        strPred = strrep(strPred, '_train_id.png', pred_suffix);
    end
    if strcmp(data_name, 'dark_zurich')
        strPred = strrep(strPred, '_gt_labelTrainIds', pred_suffix);
    end
    filePred = fullfile(save_gray_folder, strPred);
    if ~exist(filePred, 'file')
        fprintf('Prediction file [%s] does not exist!\n', filePred);
        continue;
    end

    % read in prediction and label
    imPred = imread(filePred);
    imAnno = imread(fileAnno);
    imAnno = imAnno + 1;
    if strcmp(data_name, 'cityscapes') || strcmp(data_name, 'bdd100k') ||...
            strcmp(data_name, 'dark_zurich')
    	imPred = imPred + 1;
    end
    imAnno(imAnno==255) = 0;
    imPred = imresize(imPred,[size(imAnno,1), size(imAnno,2)],'nearest');
    
    % check image size
    if size(imPred, 3) ~= 1
        fprintf('Label image [%s] should be a gray-scale image!\n', filePred);
        continue;
    end
    if size(imPred, 1)~=size(imAnno, 1) || size(imPred, 2)~=size(imAnno, 2)
        fprintf(...
            'Label image [%s] should have the same size as label image! Resizing...\n',...
            filePred);
        imPred = imresize(imPred, size(imAnno));
    end

    % compute IoU
    cnt = cnt + 1;
    [area_intersection(:,cnt), area_union(:,cnt)] =...
        intersectionAndUnion(imPred, imAnno, n_classes);

    % compute pixel-wise accuracy
    [pixel_accuracy(i), pixel_correct(i), pixel_labeled(i)] =...
        pixelAccuracy(imPred, imAnno);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Report global performance and save results to files.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IoU = sum(area_intersection,2)./sum(area_union,2);
IoU(isnan(IoU)) = 1;

mean_IoU = mean(IoU);
accuracy = sum(pixel_correct)/sum(pixel_labeled);

fprintf('==== Summary IoU ====\n');
for i = 1:n_classes
    fprintf('%3d %16s: %.4f\n', i, class_names{i}, IoU(i));
end
fprintf('Mean IoU over %d classes: %.2f\n', n_classes, 100 * mean_IoU);
fprintf('Pixel accuracy: %.2f\n', 100 * accuracy);

% Write IoU scores for all classes and frequent classes to .txt files in LaTeX
% table format.
if save_flag
    mkdir(save_root);
    dlmwrite(fullfile(save_root, 'IoU_all.txt'), 100 * IoU.',...
        'delimiter', '&', 'precision', '%.1f');
    dlmwrite(fullfile(save_root, 'mean_IoU_all.txt'), 100 * mean_IoU,...
        'precision', '%.1f');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Report performance per image.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mean_IoU_images = mean_IoU_per_image(area_intersection, area_union);

% Write per-image mean IoU scores to .txt files in LaTeX table format.
if save_flag
    dlmwrite(fullfile(save_root, 'mean_IoUs_images.txt'),...
        100 * mean_IoU_images.', 'precision', '%.2f');
end

end


