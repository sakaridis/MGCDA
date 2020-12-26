% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [in1, in2, out1, out2, F] = fundamental_RANSAC_7point(xy1, xy2,...
    threshold)
%FUNDAMENTAL_RANSAC_7POINT  RANSAC with 7-point correspondences for automatic
%calculation of the fundamental matrix from noisy measurements containing
%outliers.
%
% INPUTS:
%
%   -|xy1|: 2-by-P matrix containing interest points in the first view as
%    columns.
%
%   -|xy2|: 2-by-P matrix, where each column contains the interest point in the
%    second view that corresponds to its matching interest point in the column
%    with the same index in |xy1|.
%
%   -|threshold|: inlier threshold on the error measure, in pixels.
%
%   -|p|: probability that a pure inlier sample has been examined after the
%    execution of algorithm is completed. Usually set to 0.99 or 0.999

% Homogeneous representation for 2d points to provide proper input for function
% fundamentalMatrix.
P = size(xy1, 2);
xy1 = [xy1; ones(1, P)];
xy2 = [xy2; ones(1, P)];

% Initialize inliers' count, ratio and indices.
inliers_count = 0;
inliers_ratio = 0;
inliers = [];

% Define parameters.
% Sample size: 7 points - minimal sample for calculation of fundamental matrix.
S = 7;

% Set random number generator for reproducibility.
rng('default');

for m = 1:1000
    % Pick sample points at random
    samples = randperm(P);
    samples = samples(1:S);
    
    % Compute fundamental matrix from samples
    [F_tmp, n_solutions] = fundamental_7point(xy1(:, samples), xy2(:, samples));
    
    % Check for inliers wrt temporary F
    for f = 1:n_solutions
        inliers_tmp = [];
        for i = 1:P
            if distPointLine(xy2(:, i), F_tmp(:, :, f) * xy1(:, i)) ^ 2 +...
                    distPointLine(xy1(:, i), F_tmp(:, :, f).' * xy2(:, i)) ^ 2 <...
                    threshold ^ 2
                inliers_tmp = [inliers_tmp, i];
            end
        end
        
        % Update best solution
        if (length(inliers_tmp) > inliers_count)
            inliers_count = length(inliers_tmp);
            inliers_ratio = inliers_count/P;
            inliers = inliers_tmp;
        end
    end
    
end

% Obtain point coordinates for inlying matches
in1 = xy1(1:2, inliers);
in2 = xy2(1:2, inliers);

% Compute least-squares solution based only on inliers 
F = fundamental_8point([in1; ones(1, inliers_count)],...
    [in2; ones(1, inliers_count)]);

% Obtain point coordinates for outlying matches
out1 = xy1(1:2, ~ismember(1:P, inliers));
out2 = xy2(1:2, ~ismember(1:P, inliers));

end


