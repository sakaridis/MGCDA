% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function matches = nearest_neighbor_feature_matching(descriptors_1,...
    descriptors_2, nn_to_2nn_ratio, theta_rel)
%NEAREST_NEIGHBOR_FEATURE_MATCHING  Match points from view no. 2 to view no. 1.

% Select values for the two thresholds that correspond to an equal level of
% selectivity for both criteria.

% Add required paths.
current_script_full_name = mfilename('fullpath');
current_script_directory = fileparts(current_script_full_name);
addpath(fullfile(current_script_directory, '..', 'utilities'));

N_1 = size(descriptors_1, 2);
N_2 = size(descriptors_2, 2);

% Compute pairwise distances for all pairs of feature vectors across the two
% images.
pairwise_dists_sq = squared_euclidean_distances_exact(descriptors_1.',...
    descriptors_2.');

% Find nearest neighbors.
[dists_sq_nn, row_subs_nn] = min(pairwise_dists_sq);
indices_nn = sub2ind([N_1, N_2], row_subs_nn, 1:N_2);

% Find nearest neighbors in the opposite direction (source to target view) so as
% to eliminate many-to-one matches.
[~, col_subs_nn_inv] = min(pairwise_dists_sq, [], 2);
accepted_unique = col_subs_nn_inv(row_subs_nn).' == 1:N_2;

% Increase distances of nearest neighbors by a factor equal to the inverse of
% the ratio parameter. Iff the arg minimum is preserved, the candidate match
% satisfies the ratio criterion.
pairwise_dists_sq(indices_nn) = dists_sq_nn * (1 / nn_to_2nn_ratio ^ 2);
[~, row_subs_nn_or_2nn] = min(pairwise_dists_sq);
accepted_ratio = row_subs_nn == row_subs_nn_or_2nn;

% Compare distances of nearest neighbors to the distance of the best match, i.e.
% the smallest distance between all candidate pairs. Iff the distance is smaller
% or equal to a multiple of the smallest match distance, the candidate match
% satisfies this criterion.
dist_sq_nn_min = min(dists_sq_nn);
accepted_rel = dists_sq_nn <= theta_rel * dist_sq_nn_min;

% Matches are determined by candidates that satisfy both criteria.
is_matched_2 = accepted_unique & accepted_ratio & accepted_rel;
P = sum(is_matched_2);
matches = zeros(2, P);
matches(2, :) = find(is_matched_2);
matches(1, :) = row_subs_nn(is_matched_2);

end

