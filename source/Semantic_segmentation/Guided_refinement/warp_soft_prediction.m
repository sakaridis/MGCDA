% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function S_1_warped = warp_soft_prediction(S_1, S_1_warped_init,...
    disocclusion_mask, quads, quad_assignments, weights)
%WARP_SOFT_PREDICTION  Warp soft prediction from source to target view using the
%assignment of target-view pixels to source-view quads with specific weights.
%
% Inputs:
%
%   S_1                 source-view soft prediction as a (H_1 * W_1)-by-C matrix
%
%   S_1_warped_init     initialization of target-view soft prediction as a
%                       (H_2 * W_2)-by-C matrix
%
%   disocclusion_mask   M-by-1 vector, where M = H_2 * W_2, containing the
%                       labels of target-view pixels with respect to presence or
%                       absence of quad assignment and occasion of disocclusion
%
%   quads               F-by-4 matrix, each row of which contains the indices of
%                       the pixels that form a quad in the source view
%
%   quad_assignments    1-by-M cell array containing the assigned quad for each
%                       pixel in the target view, if any assignment has taken
%                       place
%
%   weights             1-by-M cell array, where each cell contains the
%                       interpolation weights for the target-view respective
%                       pixel, if any interpolation takes place

% Initializations.
M = size(S_1_warped_init, 1);
S_1_warped = S_1_warped_init;

% Main loop for warping.
for i = 1:M
    % If the pixel is assigned to a quad, compute warped soft prediction.
    % Otherwise keep the initial value that has been assigned.
    if disocclusion_mask(i) > 0
        current_quad = quad_assignments{i};
        S_1_warped(i, :) =...
            weights{i} * S_1(quads(current_quad, :), :);
    end
end

end

