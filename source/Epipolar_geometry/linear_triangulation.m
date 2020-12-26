% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function  [XS, err] = linear_triangulation(P1, x1s, P2, x2s)
% Input:
%   P1      - rotation and translation of first camera most likly to be [eye(3), zeros(3,1)]
%   x1s     - point correspondences of first camera
%   P2      - rotation and translation of second camera relative to first camera
%   x2s     - points correspondences of second camera
%
% Return
%   XS      - 3d points in main coordinate frame
%

XS  = zeros(4, size(x1s,2));
err = zeros(1, size(x1s,2));

for k = 1:size(x1s,2)
    r1 = x1s(1, k)*P1(3,:) - P1(1,:);
    r2 = x1s(2, k)*P1(3,:) - P1(2,:);
    
    r3 = x2s(1, k)*P2(3,:) - P2(1,:);
    r4 = x2s(2, k)*P2(3,:) - P2(2,:);
    
    A = [r1; r2; r3; r4];
    [U S V] = svd(A);
    
    XS(:,k) = V(:,end)./V(4,end);
    err(1, k) = S(end, end);
end

end