% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function image_label_colors = cityscapes_labelTrainIds2colors(image_labelTrainIds)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Exploit the fact that label train IDs assume consecutive integer values
% starting from 0, in order to use them as indices of the vectors which contain
% the R, G and B values of label colors.
label_colors_eval = [128,64,128;244,35,232;70,70,70;102,102,156;190,153,153;
    153,153,153;250,170,30;220,220,0;107,142,35;152,251,152;70,130,180;
    220,20,60;255,0,0;0,0,142;0,0,70;0,60,100;0,80,100;0,0,230;119,11,32;
    zeros(256 - 19, 3)];
labels_red = uint8(label_colors_eval(:, 1).');
labels_green = uint8(label_colors_eval(:, 2).');
labels_blue = uint8(label_colors_eval(:, 3).');

image_label_colors(:, :, 1) = labels_red(image_labelTrainIds + 1);
image_label_colors(:, :, 2) = labels_green(image_labelTrainIds + 1);
image_label_colors(:, :, 3) = labels_blue(image_labelTrainIds + 1);

end