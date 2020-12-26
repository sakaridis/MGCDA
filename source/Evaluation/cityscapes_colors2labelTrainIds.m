% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function image_labelTrainIds = cityscapes_colors2labelTrainIds(image_label_colors)

label_colors_eval = [128,64,128;244,35,232;70,70,70;102,102,156;190,153,153;
    153,153,153;250,170,30;220,220,0;107,142,35;152,251,152;70,130,180;
    220,20,60;255,0,0;0,0,142;0,0,70;0,60,100;0,80,100;0,0,230;119,11,32;
    0,0,0];

label_colors_inds = sub2ind([256, 256, 256], label_colors_eval(:, 1) + 1,...
    label_colors_eval(:, 2) + 1, label_colors_eval(:, 3) + 1);

train_IDs = uint8([0:18, 255].');

label_colors_2_label_train_IDs = containers.Map(label_colors_inds, train_IDs);

[H, W, ~] = size(image_label_colors);

image_red = image_label_colors(:, :, 1);
image_green = image_label_colors(:, :, 2);
image_blue = image_label_colors(:, :, 3);

cell_vector_labelTrainIds = values(label_colors_2_label_train_IDs,...
    num2cell(sub2ind([256, 256, 256], uint16(image_red(:)) + 1,...
    uint16(image_green(:)) + 1, uint16(image_blue(:)) + 1)));

image_labelTrainIds = reshape(cell2mat(cell_vector_labelTrainIds), [H, W]);

end