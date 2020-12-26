% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
% show feature matches between two images
%
% Input:
%   I_1             - n x m color image 
%   I_2             - n x m color image 
%   points_1        - 2 x k matrix, holding keypoint coordinates of first image
%   points_2        - 2 x k matrix, holding keypoint coordinates of second image
%   points_1_color  - color for plotting keypoints in first image
%   points_2_color  - color for plotting keypoints in second image
%   lines_style     - line style for plotting matches (optional)
function show_matches(I_1, I_2, points_1, points_2, points_1_color,...
    points_2_color, lines_style)

I_1_2_cat = [I_1, I_2];
[H, W, ~] = size(I_1);

points_2_shifted = points_2 + [W; 0];

figure;
imshow(I_1_2_cat);
hold on;
plot(points_1(1, :), points_1(2, :),...
    'o', 'MarkerFaceColor', points_1_color,...
    'MarkerEdgeColor', points_1_color);
plot(points_2_shifted(1, :), points_2_shifted(2, :),...
    'o', 'MarkerFaceColor', points_2_color,...
    'MarkerEdgeColor', points_2_color);
plot([points_1(1, :); points_2_shifted(1, :)],...
    [points_1(2, :); points_2_shifted(2, :)],...
    lines_style);

end