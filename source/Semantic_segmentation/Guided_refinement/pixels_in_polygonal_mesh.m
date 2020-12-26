% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function inclusions = pixels_in_polygonal_mesh(query_points, mesh_vertices,...
    mesh_polygons, are_vertices_invalid, H, W)
%PIXELS_IN_POLYGONAL_MESH  Determine elements of a mesh which include each point
%from a set of input query points.
%
% INPUTS
%
%   query_points        M-by-2 matrix containing 2D points as rows
%
%   mesh_vertices       N-by-2 matrix containing mesh vertices as rows
%
%   mesh_polygons       F-by-P matrix, where P is the number of vertices in the
%                       polygons of the mesh. It contains polygons as sets of
%                       vertex indices
%
%  are_vertices_invalid N-by-1 vector containing binary values which indicate
%                       whether a vertex should be used for inclusion of pixels
%                       in its related polygons or not
%
% OUTPUT
%
%   inclusions      1-by-M cell array, where each cell contains a list of
%                   polygons which include the corresponding point

M = size(query_points, 1);
F = size(mesh_polygons, 1);

% Initialize cell array containing point inclusions in mesh elements.
inclusions = cell(1, M);

for i = 1:F
    % Disregard polygons for which any vertex is "invalid".
    if any(are_vertices_invalid(mesh_polygons(i, :)))
        continue;
    end
    
    current_polygon_vertices = mesh_vertices(mesh_polygons(i, :), :);
    
    % Constrain the pixels to be queried based on the restricting rectangle of
    % the polygon.
    x_min = min(current_polygon_vertices(:, 1));
    x_max = max(current_polygon_vertices(:, 1));
    y_min = min(current_polygon_vertices(:, 2));
    y_max = max(current_polygon_vertices(:, 2));
    
    xs = max(ceil(x_min), 1):min(floor(x_max), W);
    ys = max(ceil(y_min), 1):min(floor(y_max), H);
    
    if isempty(xs) || isempty(ys)
        continue;
    end
    
    [J, I] = meshgrid(xs, ys);
    J = J(:);
    I = I(:);
    inds_candidate = sub2ind([H, W], I, J);
    
    current_inclusion = inpolygon(J, I, current_polygon_vertices(:, 1),...
        current_polygon_vertices(:, 2));
    
    current_inclusion_inds = inds_candidate(current_inclusion);
    
    
    % Add current polygon to inclusions for the points that it includes.
    for j = 1:size(current_inclusion_inds, 1)
        inclusions{current_inclusion_inds(j)} =...
            [inclusions{current_inclusion_inds(j)}, i];
    end
    
end

end

