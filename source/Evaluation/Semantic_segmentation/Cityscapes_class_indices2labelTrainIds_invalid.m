function image_labelTrainIds_invalid =...
    Cityscapes_class_indices2labelTrainIds_invalid(image_class_indices_invalid)
%CITYSCAPES_CLASS_INDICES2LABELTRAINIDS_INVALID  Convert image with indices of
%Cityscapes evaluation classes (including invalid parts with index of 0) to
%image of labels in train ID format, where invalid parts assume the value of
%255.

image_labelTrainIds_invalid = image_class_indices_invalid;
image_labelTrainIds_invalid(image_class_indices_invalid == 0) = 255;
image_labelTrainIds_invalid(image_class_indices_invalid > 0) =...
    image_labelTrainIds_invalid(image_class_indices_invalid > 0) - 1;

end

