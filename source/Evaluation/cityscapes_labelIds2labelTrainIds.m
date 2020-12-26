% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function image_labelTrainIds = cityscapes_labelIds2labelTrainIds(image_labelIds)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

label_train_ids = uint8([255,255,255,255,255,255,255,0,1,255,255,2,3,4,...
    255,255,255,5,255,6,7,8,9,10,11,12,13,14,15,255,255,16,17,18]);
image_labelTrainIds = label_train_ids(image_labelIds + 1);

end