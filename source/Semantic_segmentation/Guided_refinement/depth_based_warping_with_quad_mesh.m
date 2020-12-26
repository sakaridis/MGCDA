% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function S_1_warped = depth_based_warping_with_quad_mesh(depth_1, K_1, K_2,...
    R, t_abs, H_2, W_2, S_1)
%DEPTH_BASED_WARPING_WITH_QUAD_MESH  Warp soft semantic prediction from view 1
%to view 2 using a dense depth map for view 1, intrinsic and extrinsic camera
%parameters and a forward warping scheme with a dense quadrangular mesh defined
%on view 1.
%

% ------------------------------------------------------------------------------
% Establish per-pixel correspondences from source to target view.
% ------------------------------------------------------------------------------

[H_1, W_1] = size(depth_1);

% Construct pixel grid in the first view.
[j_1, i_1] = meshgrid(1:W_1, 1:H_1);

% Get homogeneous coordinates of pixel grid in proper dimensions for subsequent
% operations.
coords_1_pixel = cat(3, j_1, i_1, ones(H_1, W_1));
coords_1_pixel = shiftdim(coords_1_pixel, 2);
coords_1_pixel = reshape(coords_1_pixel, [3, H_1 * W_1]);

% Backproject 2D image points to 3D space using the estimated depth map.
coords_1_normalized = K_1 ^ -1 * coords_1_pixel;
depth_1_vectorized = depth_1(:);
X_dense = (depth_1_vectorized.') .* coords_1_normalized;
X_dense_hom = [X_dense; ones(1, H_1 * W_1)];

% Reproject the obtained 3D points to the second view using the estimated
% intrinsics and extrinsics for that view. Determine which points lie very close
% to the image plane in the second view.
thresh_z = 0.1;
coords_2_pixel = K_2 * ([R, t_abs] * X_dense_hom);
is_projection_ill_cond = (abs(coords_2_pixel(3, :)) < thresh_z).';
coords_2_pixel = coords_2_pixel ./ coords_2_pixel(3, :);

% ------------------------------------------------------------------------------
% Warp soft predictions from source to target view.
% ------------------------------------------------------------------------------

% Contruct pixel grid in the second view.
[j_2, i_2] = meshgrid(1:W_2, 1:H_2);
pixel_grid_2_vectorized = [j_2(:), i_2(:)];

% Construct quadrangular mesh for the first view.
quads = create_quad_mesh_2d(true(H_1, W_1));

% Form vertex matrix for quadrangular mesh based on the established per-pixel
% correspondences.
verts = coords_2_pixel(1:2, :).';

% Determine which polygons contain each pixel in the second view.
quad_inclusions_2 = pixels_in_polygonal_mesh(pixel_grid_2_vectorized, verts,...
    quads, is_projection_ill_cond, H_2, W_2);

% Disambiguate polygon membership for pixels that are contained in two or more
% polygons based on depth values of polygon vertices.
[quad_assignments_2, ~] = assign_quads_to_pixels(quads, quad_inclusions_2,...
    depth_1, verts);

% Compute weights for quad mesh interpolation.
[w_bilinear, disocclusion_mask_vectorized] =...
    weights_bilinear_except_disocclusions(pixel_grid_2_vectorized,...
    verts, quads, quad_assignments_2, depth_1_vectorized);

% Perform the warping.
% Assumption: prediction in the first view has the same dimensions as that in
% the second view.
[~, ~, n_classes] = size(S_1);
S_1_warped_init = S_1;
S_1_warped_init_vectorized = reshape(S_1_warped_init, H_2 * W_2, n_classes);

S_1_vectorized = reshape(S_1, H_1 * W_1, n_classes);

S_1_warped_vectorized = warp_soft_prediction(S_1_vectorized,...
    S_1_warped_init_vectorized, disocclusion_mask_vectorized, quads,...
    quad_assignments_2, w_bilinear);

S_1_warped = reshape(S_1_warped_vectorized, H_2, W_2, n_classes);

end

