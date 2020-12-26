% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [quad_assignments, depth_quads] = assign_quads_to_pixels(quads,...
    quad_inclusions, depth, mesh_vertices)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

depth_quads = mean(depth(quads), 2);

% Initialize assignment with the one-to-many inclusion mapping which needs
% disambiguation.
quad_assignments = quad_inclusions;

M = size(quad_inclusions, 2);

k = 5;

for i = 1:M
    init_assignment = quad_assignments{i};
    c = size(init_assignment, 2);
    
    % Restrict further processing to pixels with two or more competing quads.
    if c >= 2
        % Identify "irregular" quads, i.e., quads with a clear binary cut of the
        % four vertices, or equivalently where the second longest side is
        % several times longer than the third longest side.
        are_quads_irregular = true(1, c);
        for j = 1:c
            current_quad = init_assignment(j);
            current_verts = mesh_vertices(quads(current_quad, :), :);
            
            side_lengths =...
                sqrt(sum((diff([current_verts; current_verts(1, :)])) .^ 2, 2));
            side_lengths_sorted = sort(side_lengths);
            
            if side_lengths_sorted(3) <= k * side_lengths_sorted(2)
                are_quads_irregular(j) = false;
            end
        end
        
        % "Regular" quads have priority for being assigned over "irregular"
        % ones.
        if ~all(are_quads_irregular)
            init_assignment = init_assignment(~are_quads_irregular);
        end
        
        % Assign the current pixel to the candidate polygon with the lowest
        % depth value.
        candidate_quads_depths = depth_quads(init_assignment);
        [~, inds] = sort(candidate_quads_depths);
        quad_assignments{i} = init_assignment(inds(1));
        
    end
end


end

