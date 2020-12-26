% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [nxs, T] = normalizePoints2d(x1s)
% Normalization of 2d-pts
% Inputs: 
%           x1s = homogeneous 2d points
% Outputs:
%           nxs = normalized points
%           T = normalization matrix

%first compute centroid - its 3rd coordinate being equal to 1
centroid = mean(x1s, 2);

%and subtract it from initial coordinates - all new points
% have their 3rd coordinate equal to 0 (A)
x1s_tr = x1s - centroid;

%then, compute scale - can do calculations using whole x1s_tr
%due to (A)
scale = sqrt(2) / mean(sqrt(sum(x1s_tr .^ 2)));

%create T transformation matrix
T = [scale, 0, -scale * centroid(1);
     0, scale, -scale * centroid(2);
     0, 0, 1];
 
%normalize the points according to the transformation
nxs = T * x1s;
 
end