% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function F_out = transform_fundamental_to_principal_at_origin(F_in, p_1, p_2)
%TRANSFORM_FUNDAMENTAL_TO_PRINCIPAL_AT_ORIGIN  Transform fundamental matrix for
%a change in coordinates so that the (known) principal points lie at the origin.
%
% INPUTS
%
%   F_in    the initial 3-by-3 fundamental matrix
%   p_1     the principal point of the first view as a 2-by-1 vector in the
%           initial coordinates
%   p_2     the principal point of the second view as a 2-by-1 vector in the
%           initial coordinates


F_out = [1, 0, 0; 0, 1, 0; p_2.', 1] * F_in * [eye(2), p_1; 0, 0, 1];

end

