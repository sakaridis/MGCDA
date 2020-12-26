% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [P, X] = decompose_essential(E, x1s, x2s)

W = [0, -1, 0;
     1,  0, 0;
     0,  0, 1];

 % Perform SVD on the essential matrix.
[U, ~, V] = svd(E);

% Extract translation orientation.
t = U(:, 3);

% Extract possible rotations.
R1 = U * W * V.';
R2 = U * W.' * V.';

if det(R1) < 0
    R1 = -R1;
end

if det(R2) < 0
    R2 = -R2;
end

P1 = eye(4);

% Four possible solutions, by combining the sign ambiguity of the translation
% and the twisted pair ambiguity of the rotation.
Ps = {[R1, t; 0, 0, 0, 1],...
      [R1, -t; 0, 0, 0, 1],...
      [R2, t; 0, 0, 0, 1],...
      [R2, -t; 0, 0, 0, 1]};

% Resolve ambiguity by checking which case has most 3D points in front of both
% cameras. Need to triangulate for this purpose.
counts = zeros(1, 4);
Xs = cell(1, 4);
for k = 1:size(Ps, 2)
    Xs{k} = linear_triangulation(P1, x1s, Ps{k}, x2s);
    
    p1X = P1 * Xs{k};
    p2X = Ps{k} * Xs{k};
    
    counts(k) = sum(p1X(3, :) >= 0 & p2X(3, :) >= 0);
end

[~, i] = max(counts);
P = Ps{i};

% NOTE: X is not correct if the x1s and x2s are not in normalized image
% coordinates (not in original pixel coordinates).
X = Xs{i};

end