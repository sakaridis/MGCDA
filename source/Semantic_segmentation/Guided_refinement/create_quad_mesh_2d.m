% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function quads = create_quad_mesh_2d(I_dil)
%CREATE_QUAD_MESH_2D  Defines quads of pixel grid refined to a 2D shape.
%   Input:
%       |I_dil|: binary image of the same size as the original image of the
%       deformed 2D shape, which is true inside the shape and at pixels that are
%       neighbors to the shape in the 8-neighborhood sense
%
%   Output:
%       |quads|: l-by-4 matrix, each row of which contains the indices of the
%       pixels that form a quad. These indices refer to the true part of
%       |I_dil|.

[height, width, ~] = size(I_dil);

% Identify pixels that constitute the origin of some quad.
I_padded = padarray(I_dil, [1 1], 'post');
I_quad_origins =...
    I_dil & I_padded(1:(end - 1), 2:end) &...
    I_padded(2:end, 1:(end - 1)) & I_padded(2:end, 2:end);

% Define mesh using indices of the original, full image.
[row_subs, col_subs] = find(I_quad_origins);
quads_full_I = sub2ind([size(I_dil, 1), size(I_dil, 2)],...
    [row_subs, row_subs + 1, row_subs + 1, row_subs],...
    [col_subs, col_subs, col_subs + 1, col_subs + 1]);

% Recover pixel indices in the grid that is refined to the shape.
inds = find(I_dil);
indices_shape = zeros(height * width, 1);
indices_shape(inds) = 1:size(inds, 1);

% Redefine mesh using indices of the refined image.
quads = indices_shape(quads_full_I);

end

