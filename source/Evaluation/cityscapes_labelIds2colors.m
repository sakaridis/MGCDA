% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function image_label_colors = cityscapes_labelIds2colors(image_labelIds)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

label_train_ids_eval = uint8([19,0,0,0,0,0,0,0,1,0,0,2,3,4,0,0,0,5,0,6,7,8,9,...
    10,11,12,13,14,15,0,0,16,17,18]);
image_label_train_ids = label_train_ids_eval(image_labelIds + 1);

label_colors_eval = [128,64,128;244,35,232;70,70,70;102,102,156;190,153,153;
    153,153,153;250,170,30;220,220,0;107,142,35;152,251,152;70,130,180;
    220,20,60;255,0,0;0,0,142;0,0,70;0,60,100;0,80,100;0,0,230;119,11,32;0,0,0];
labels_red = uint8(label_colors_eval(:, 1).');
labels_green = uint8(label_colors_eval(:, 2).');
labels_blue = uint8(label_colors_eval(:, 3).');

image_label_colors(:, :, 1) = labels_red(image_label_train_ids + 1);
image_label_colors(:, :, 2) = labels_green(image_label_train_ids + 1);
image_label_colors(:, :, 3) = labels_blue(image_label_train_ids + 1);

end