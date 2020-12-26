% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [F, n_alphas] = fundamental_7point(x1s, x2s)
%FUNDAMENTAL_7POINT  Compute the fundamental matrix using the 7-point algorithm.
%
% INPUTS:
%
% 	x1s, x2s 	Correspondences between seven pairs of 2D points. Sizes: 3-by-7
%
% OUTPUTS:
%
% 	F 			3D matrix containing the computed fundamental matrices as its
%               pages
%
%   n_alphas    number of solutions for fundamental matrix given the seven input
%               correspondences

% Normalize points in both images.
[nx1s, T1] = normalizePoints2d(x1s);
[nx2s, T2] = normalizePoints2d(x2s);

% Compute matrix A in the nullspace of which F belongs.
A = zeros(7, 9);
for i = 1:7
    %Fill i-th row of A
    A(i, :) = reshape(nx1s(:, i) * nx2s(:, i).', 1, 9);
end

% Compute the fundamental matrix as a linear combination of the two elements of
% the basis of the right null space of A, under the singularity constraint.
[~, ~, V_A] = svd(A);
f1 = V_A(:, 8);
f2 = V_A(:, 9);
F1 = (reshape(f1, 3, 3)).';
F2 = (reshape(f2, 3, 3)).';

% Calculate the coefficients of the third-order polynomial the root of which
% defines the coefficients of the above linear combination.
c_3 = sum(...
    [F1(1, 1) * F1(2, 2) * F1(3, 3);
     -F1(1, 1) * F1(2, 3) * F1(3, 2);
     -F1(1, 1) * F1(2, 2) * F2(3, 3);
     -F1(1, 1) * F1(3, 3) * F2(2, 2);
     F1(1, 1) * F1(2, 3) * F2(3, 2);
     F1(1, 1) * F1(3, 2) * F2(2, 3);
     F1(1, 1) * F2(2, 2) * F2(3, 3);
     -F1(1, 1) * F2(2, 3) * F2(3, 2);% End line 1 c_3
     -F1(2, 2) * F1(3, 3) * F2(1, 1);
     F1(2, 3) * F1(3, 2) * F2(1, 1);
     F1(2, 2) * F2(1, 1) * F2(3, 3);
     F1(3, 3) * F2(1, 1) * F2(2, 2);
     -F1(2, 3) * F2(1, 1) * F2(3, 2);
     -F1(3, 2) * F2(1, 1) * F2(2, 3);
     -F2(1, 1) * F2(2, 2) * F2(3, 3);
     F2(1, 1) * F2(2, 3) * F2(3, 2);% End line 2 c_3
     F1(1, 2) * F1(2, 3) * F1(3, 1);
     -F1(1, 2) * F1(2, 1) * F1(3, 3);
     -F1(1, 2) * F1(2, 3) * F2(3, 1);
     -F1(1, 2) * F1(3, 1) * F2(2, 3);
     F1(1, 2) * F1(2, 1) * F2(3, 3);
     F1(1, 2) * F1(3, 3) * F2(2, 1);
     F1(1, 2) * F2(2, 3) * F2(3, 1);
     -F1(1, 2) * F2(2, 1) * F2(3, 3);% End line 3 c_3
     -F1(2, 3) * F1(3, 1) * F2(1, 2);
     F1(2, 1) * F1(3, 3) * F2(1, 2);
     F1(2, 3) * F2(1, 2) * F2(3, 1);
     F1(3, 1) * F2(1, 2) * F2(2, 3);
     -F1(2, 1) * F2(1, 2) * F2(3, 3);
     -F1(3, 3) * F2(1, 2) * F2(2, 1);
     -F2(1, 2) * F2(2, 3) * F2(3, 1);
     F2(1, 2) * F2(2, 1) * F2(3, 3);% End line 4 c_3
     F1(1, 3) * F1(2, 1) * F1(3, 2);
     -F1(1, 3) * F1(2, 2) * F1(3, 1);
     -F1(1, 3) * F1(2, 1) * F2(3, 2);
     -F1(1, 3) * F1(3, 2) * F2(2, 1);
     F1(1, 3) * F1(2, 2) * F2(3, 1);
     F1(1, 3) * F1(3, 1) * F2(2, 2);
     F1(1, 3) * F2(2, 1) * F2(3, 2);
     -F1(1, 3) * F2(2, 2) * F2(3, 1);% End line 5 c_3
     -F1(2, 1) * F1(3, 2) * F2(1, 3);
     F1(2, 2) * F1(3, 1) * F2(1, 3);
     F1(2, 1) * F2(1, 3) * F2(3, 2);
     F1(3, 2) * F2(1, 3) * F2(2, 1);
     -F1(2, 2) * F2(1, 3) * F2(3, 1);
     -F1(3, 1) * F2(1, 3) * F2(2, 2);
     -F2(1, 3) * F2(2, 1) * F2(3, 2);
     F2(1, 3) * F2(2, 2) * F2(3, 1)]);% End line 6 c_3

c_2 = sum(...
    [F1(1, 1) * F1(2, 2) * F2(3, 3);
     F1(1, 1) * F1(3, 3) * F2(2, 2);
     -F1(1, 1) * F1(2, 3) * F2(3, 2);
     -F1(1, 1) * F1(3, 2) * F2(2, 3);
     -2 * F1(1, 1) * F2(2, 2) * F2(3, 3);
     2 * F1(1, 1) * F2(2, 3) * F2(3, 2);
     F1(2, 2) * F1(3, 3) * F2(1, 1);% End line 1 c_2
     -F1(2, 3) * F1(3, 2) * F2(1, 1);
     -2 * F1(2, 2) * F2(1, 1) * F2(3, 3);
     -2 * F1(3, 3) * F2(1, 1) * F2(2, 2);
     2 * F1(2, 3) * F2(1, 1) * F2(3, 2);
     2 * F1(3, 2) * F2(1, 1) * F2(2, 3);
     3 * F2(1, 1) * F2(2, 2) * F2(3, 3);
     -3 * F2(1, 1) * F2(2, 3) * F2(3, 2);% End line 2 c_2
     F1(1, 2) * F1(2, 3) * F2(3, 1);
     F1(1, 2) * F1(3, 1) * F2(2, 3);
     -F1(1, 2) * F1(2, 1) * F2(3, 3);
     -F1(1, 2) * F1(3, 3) * F2(2, 1);
     -2 * F1(1, 2) * F2(2, 3) * F2(3, 1);
     2 * F1(1, 2) * F2(2, 1) * F2(3, 3);
     F1(2, 3) * F1(3, 1) * F2(1, 2);% End line 3 c_2
     -F1(2, 1) * F1(3, 3) * F2(1, 2);
     -2 * F1(2, 3) * F2(1, 2) * F2(3, 1);
     -2 * F1(3, 1) * F2(1, 2) * F2(2, 3);
     2 * F1(2, 1) * F2(1, 2) * F2(3, 3);
     2 * F1(3, 3) * F2(1, 2) * F2(2, 1);
     3 * F2(1, 2) * F2(2, 3) * F2(3, 1);
     -3 * F2(1, 2) * F2(2, 1) * F2(3, 3);% End line 4 c_2
     F1(1, 3) * F1(2, 1) * F2(3, 2);
     F1(1, 3) * F1(3, 2) * F2(2, 1);
     -F1(1, 3) * F1(2, 2) * F2(3, 1);
     -F1(1, 3) * F1(3, 1) * F2(2, 2);
     -2 * F1(1, 3) * F2(2, 1) * F2(3, 2);
     2 * F1(1, 3) * F2(2, 2) * F2(3, 1);
     F1(2, 1) * F1(3, 2) * F2(1, 3);% End line 5 c_2
     -F1(2, 2) * F1(3, 1) * F2(1, 3);
     -2 * F1(2, 1) * F2(1, 3) * F2(3, 2);
     -2 * F1(3, 2) * F2(1, 3) * F2(2, 1);
     2 * F1(2, 2) * F2(1, 3) * F2(3, 1);
     2 * F1(3, 1) * F2(1, 3) * F2(2, 2);
     3 * F2(1, 3) * F2(2, 1) * F2(3, 2);
     -3 * F2(1, 3) * F2(2, 2) * F2(3, 1)]);% End line 6 c_2

c_1 = sum(...
    [F1(1, 1) * F2(2, 2) * F2(3, 3);
     -F1(1, 1) * F2(2, 3) * F2(3, 2);
     F1(2, 2) * F2(1, 1) * F2(3, 3);
     F1(3, 3) * F2(1, 1) * F2(2, 2);
     -F1(2, 3) * F2(1, 1) * F2(3, 2);
     -F1(3, 2) * F2(1, 1) * F2(2, 3);
     -3 * F2(1, 1) * F2(2, 2) * F2(3, 3);
     3 * F2(1, 1) * F2(2, 3) * F2(3, 2);% End line 1 c_1
     F1(1, 2) * F2(2, 3) * F2(3, 1);
     -F1(1, 2) * F2(2, 1) * F2(3, 3);
     F1(2, 3) * F2(1, 2) * F2(3, 1);
     F1(3, 1) * F2(1, 2) * F2(2, 3);
     -F1(2, 1) * F2(1, 2) * F2(3, 3);
     -F1(3, 3) * F2(1, 2) * F2(2, 1);
     -3 * F2(1, 2) * F2(2, 3) * F2(3, 1);
     3 * F2(1, 2) * F2(2, 1) * F2(3, 3);% End line 2 c_1
     F1(1, 3) * F2(2, 1) * F2(3, 2);
     -F1(1, 3) * F2(2, 2) * F2(3, 1);
     F1(2, 1) * F2(1, 3) * F2(3, 2);
     F1(3, 2) * F2(1, 3) * F2(2, 1);
     -F1(2, 2) * F2(1, 3) * F2(3, 1);
     -F1(3, 1) * F2(1, 3) * F2(2, 2);
     -3 * F2(1, 3) * F2(2, 1) * F2(3, 2);
     3 * F2(1, 3) * F2(2, 2) * F2(3, 1)]);% End line 3 c_1

c_0 = sum(...
    [F2(1, 1) * F2(2, 2) * F2(3, 3);
     -F2(1, 1) * F2(2, 3) * F2(3, 2);
     F2(1, 2) * F2(2, 3) * F2(3, 1);
     -F2(1, 2) * F2(2, 1) * F2(3, 3);
     F2(1, 3) * F2(2, 1) * F2(3, 2);
     -F2(1, 3) * F2(2, 2) * F2(3, 1)]);

% Find the roots of the third-order polynomial.
alphas = roots([c_3, c_2, c_1, c_0]);

% Isolate the real roots, which are relevant for the fundamental matrix.
alphas_real = alphas(~(abs(imag(alphas)) > 0));
n_alphas = size(alphas_real, 1);

% Get the fundamental matrix (or matrices) corresponding to the identified
% solutions of the equation stemming from the singularity constraint.
F_n = zeros(3, 3, n_alphas);
for i = 1:n_alphas
    F_n(:, :, i) = alphas_real(i) * F1 + (1 - alphas_real(i)) * F2;
end

% Denormalize to get the final version of the fundamental matrix.
F = zeros(3, 3, n_alphas);
for i = 1:n_alphas
    F(:, :, i) = T2.' * F_n(:, :, i) * T1;
end

end