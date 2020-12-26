% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [w_bilinear, disocclusion_mask] =...
    weights_bilinear_except_disocclusions(pixel_grid,...
    mesh_vertices, quads, quad_assignments, depth)
%WEIGHTS_BILINEAR_EXCEPT_DISOCCLUSIONS  Computes weights for bilinear
%interpolation inside quads, distinguishing pixels in disoccluded areas and
%disregarding the occluder.
%
%   Inputs:
%
%       |pixel_grid|: M-by-2 matrix containing pixel positions in its rows.
%
%       |mesh_vertices|: N-by-2 matrix holding locations of warped pixels of
%       original image
%
%       |quads|: l-by-4 matrix, each row of which contains the indices of the
%       pixels that form a quad
%
%       |quad_assignments|: 1-by-M cell array containing the assigned quad for
%       each pixel of the |pixel_grid|, if any assignment has been performed.
%
%       |depth|: N-by-1 vector with depth values for mesh vertices.
%
%   Output:
%       |w_bilinear|: 1-by-M cell array, where each cell contains the
%       interpolation weights for the respective pixel.

S_inv = [1, 0, 0, 0;
        -1, 1, 0, 0;
        -1, 0, 0, 1;
        1, -1, 1, -1];

verts_x = mesh_vertices(:, 1);
quad_verts_x = verts_x(quads).';
verts_y = mesh_vertices(:, 2);
quad_verts_y = verts_y(quads).';

alphas = S_inv * quad_verts_x;
betas = S_inv * quad_verts_y;

% Precompute quantities used in computation of bilinear interpolation
% coefficients.
as = alphas(4, :) .* betas(3, :) - alphas(3, :) .* betas(4, :);
bs_common = alphas(2, :) .* betas(3, :) + alphas(4, :) .* betas(1, :)...
    - alphas(3, :) .* betas(2, :) - alphas(1, :) .* betas(4, :);
cs_common = alphas(2, :) .* betas(1, :) - alphas(1, :) .* betas(2, :);


% Compute the weights for bilinear interpolation to be used for warping soft
% semantic predictions to target view.
M = size(pixel_grid, 1);
w_bilinear = cell(1, M);

% Factor for comparing side lengths of examined quads.
k = 5;

% Register type of interpolation (bilinear, disocclusion or none) in a mask.
disocclusion_mask = zeros(M, 1);

for i = 1:M
    x = pixel_grid(i, 1);
    y = pixel_grid(i, 2);
    
    % If the pixel is assigned to a quad, compute weights. Otherwise leave
    % weights empty.
    if size(quad_assignments{i}, 2) > 0
        
        current_quad = quad_assignments{i};
        
        current_verts = mesh_vertices(quads(current_quad, :), :);
        
        a = as(current_quad);
        b = bs_common(current_quad) + x * betas(4, current_quad)...
            - y * alphas(4, current_quad);
        c = cs_common(current_quad) + x * betas(2, current_quad)...
            - y * alphas(2, current_quad);
        d = b^2 - 4*a*c;
        assert(d >= 0,...
            'Discriminant for solving bilinear weights is negative!');
        m = (-b + [sqrt(d), -sqrt(d)]) / (2 * a);
        l = (x - alphas(1, current_quad) - alphas(3, current_quad) * m)...
            ./ (alphas(2, current_quad) + alphas(4, current_quad) * m);
        
        margin_m = max(max(m - 1, 0), max(-m, 0));
        margin_l = max(max(l - 1, 0), max(-l, 0));
        
        [~, ind] = min(margin_m + margin_l);
        m = m(ind);
        l = l(ind);
        
        m = min(max(m, 0), 1);
        l = min(max(l, 0), 1);
        
%         are_coeffs_valid = l >= 0 & l <= 1 & m >= 0 & m <= 1;
%         assert(sum(are_coeffs_valid) == 1,...
%             'Bilinear weights are not well defined!');
        
        % Check whether there is a clear binary cut of the quad's vertices, or
        % equivalently whether the second longest side is several times longer
        % than the third longest side.
        side_lengths =...
            sqrt(sum((diff([current_verts; current_verts(1, :)])) .^ 2, 2));
        side_lengths_sorted = sort(side_lengths);
        
        if side_lengths_sorted(3) <= k * side_lengths_sorted(2)
            
            w_bilinear{i} =...
                [(1 - l) * (1 - m), l * (1 - m), l * m, (1 - l) * m];
            
            disocclusion_mask(i) = 1;
        else
            % In these corner cases, a disocclusion is assumed and the weights
            % are not bilinear.
            % On the contrary, we experiment with two formulations:
            % 1) only the vertex with the largest depth value is considered for
            %    the interpolation.
            % 2) only the vertices on the same "side" of the quad with the
            %    vertex that has the largest depth value (with respect to the
            %    cut induced by removing the two longest edges) are considered
            %    for interpolation.
            current_quad_depths_verts = depth(quads(current_quad, :));
            [~, ind_max_depth] = max(current_quad_depths_verts);
            
            is_w_nonzero = zeros(1, 4);
            is_w_nonzero(ind_max_depth) = 1;
            
            % Include vertices in the cut in the counter-clockwise direction.
            j = ind_max_depth;
            while side_lengths(j) < side_lengths_sorted(3)
                is_w_nonzero(mod(j, 4) + 1) = 1;
                j = mod(j, 4) + 1;
            end
            % Include vertices in the cut in the clockwise direction.
            j = ind_max_depth;
            while side_lengths(4 - (mod(4 - j + 1, 4))) < side_lengths_sorted(3)
                is_w_nonzero(4 - (mod(4 - j + 1, 4))) = 1;
                j = 4 - (mod(4 - j + 1, 4));
            end
            
            w_bilinear_help =...
                [(1 - l) * (1 - m), l * (1 - m), l * m, (1 - l) * m];
            w_bilinear_help(~is_w_nonzero) = 0;
            w_bilinear{i} = w_bilinear_help / sum(w_bilinear_help);
            
            disocclusion_mask(i) = 2;
        end
    end
end

end

