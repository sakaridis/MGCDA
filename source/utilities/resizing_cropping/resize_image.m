% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function I_rsz = resize_image(I, n_rows_output, n_cols_output)
%RESIZE_IMAGE  Resize image to specified output dimensions using bilinear
%interpolation.
%
%   INPUTS:
%
%   -|I|: input image to be resized.
%
%   -|n_rows_output|: number of rows of resized output.
%
%   -|n_cols_output|: number of columns of resized output.
%
%   OUTPUT:
%
%   -|I_rsz|: resized image to specified number of rows and columns.

I_rsz = imresize(I, [n_rows_output n_cols_output], 'bilinear');

end

