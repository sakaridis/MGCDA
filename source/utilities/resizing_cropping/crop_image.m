% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function I_crop = crop_image(I, crop_coords)

% Check that input rectangle coordinates are valid.
[H, W, C] = size(I);
i_a = crop_coords(1);
j_a = crop_coords(2);
i_b = crop_coords(3);
j_b = crop_coords(4);
assert(i_a >= 1 && j_a >= 1 && i_b <= H && j_b <= W && i_a < i_b && j_a < j_b,...
    'Specified crop coordinates do not fit in the image or do not define a valid crop.');

% Crop.
if C == 1
    % Binary or grayscale images.
    I_crop = I(i_a:i_b, j_a:j_b);
else
    % Multi-channel (color) images.
    I_crop = [];
    for c = 1:C
        I_crop = cat(3, I_crop, I(i_a:i_b, j_a:j_b, c));
    end
end

end




















