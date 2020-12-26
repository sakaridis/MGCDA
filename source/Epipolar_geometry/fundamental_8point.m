% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
% Compute the fundamental matrix using the eight point algorithm
% Input 
% 	x1s, x2s 	Point correspondences
%
% Output
% 	Fh 			Fundamental matrix with the det F = 0 constraint
% 	F 			Initial fundamental matrix obtained from the eight point algorithm
%   e1          Epipole of first image in homogeneous coordinates
%   e2          Epipole of second image in homogeneous coordinates
%
function [Fh, F, e1, e2] = fundamental_8point(x1s, x2s)

%Normalize points in both images
[nx1s, T1] = normalizePoints2d(x1s);
[nx2s, T2] = normalizePoints2d(x2s);

%Compute matrix A whose nullspace is F
A = [];
for i=1:size(nx1s, 2)
    %Fill i-th row of A
    A(i, :) = reshape(nx1s(:, i)*nx2s(:, i)', 1, 9);
end

%Obtain initial linear estimation for "normalized" version Fn
%from S.V.D. of A
[~, ~, VA] = svd(A);
fn = VA(:, end);
Fn = (reshape(fn, 3, 3))';

%Compute S.V.D. of Fn and impose singularity constraint by
%forcing the 3rd singular value to 0
[U, S, V] = svd(Fn);
S(3, 3) = 0;
Fhn = U*S*V';

%Denormalize to get F and Fh
F = T2'*Fn*T1;
Fh = T2'*Fhn*T1;

%Calculate epipoles in both images as right and left
%null-vectors of Fh
[Uh, ~, Vh] = svd(Fh);
e1 = Vh(:, end)/Vh(end, end); %scale properly
e2 = Uh(:, end)/Uh(end, end); %likewise

end