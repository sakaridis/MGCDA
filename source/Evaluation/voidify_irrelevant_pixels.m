% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function voidified_label_image = voidify_irrelevant_pixels(label_image,...
    void_mask, void_label)
%VOIDIFY_IRRELEVANT_PIXELS  Set the labels of pixels that are irrelevant for
%current evaluation to void, so that they are ignored during evaluation.

voidified_label_image = label_image;
voidified_label_image(void_mask) = void_label;

end

