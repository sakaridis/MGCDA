% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function CIELAB_image_unit_range = RGB_to_CIELAB_unit_range(RGB_image)
%RGB_TO_CIELAB_UNIT_RANGE  Convert RGB image with values in [0, 1] range to
%CIELAB image where the three channels L*, a* and b* are uniformly rescaled and
%the two latter are subsequently shifted so that all three channels assume
%nonnegative values and the original range [0, 100] of L* values is mapped to
%[0, 1].

% Conversion to CIELAB.
CIELAB_image = rgb2lab(RGB_image);

% Normalization (not affecting ratios of Euclidean distances between pairs of
% points in the color space):
% 1) Rescale all three channels by the same factor, so that the original range
%    of the L* channel is mapped to the [0, 1] interval.
L_star_range_standard = 100;
CIELAB_image_rescaled = (1 / L_star_range_standard) * CIELAB_image;
% 2) Shift a* and b* channels so that their minimum value is zero.
a_star_rescaled = CIELAB_image_rescaled(:, :, 2);
a_star_normalized = a_star_rescaled - min(a_star_rescaled(:));
b_star_rescaled = CIELAB_image_rescaled(:, :, 3);
b_star_normalized = b_star_rescaled - min(b_star_rescaled(:));
CIELAB_image_unit_range = cat(3, CIELAB_image_rescaled(:, :, 1),...
    a_star_normalized, b_star_normalized);

end

