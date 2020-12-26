% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function image_labelIds = cityscapes_labelTrainIds2labelIds(image_labelTrainIds)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Exploit the fact that label train IDs assume consecutive integer values
% starting from 0, in order to use them as indices of the vector
% |label_ids_eval| which contains the values of label IDs.
label_ids_eval = uint8([7,8,11,12,13,17,19,20,21,22,23,24,25,26,27,28,31,32,33, zeros(1, 256 - 19)]);
image_labelIds = label_ids_eval(image_labelTrainIds + 1);

end

