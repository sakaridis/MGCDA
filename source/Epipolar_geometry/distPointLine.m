% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function d = distPointLine( point, line )

% point: homogeneous 2d point (3-vector) with 3rd entry equal to 1
% line: 2d homogeneous line equation (3-vector)

d = abs(point.' * line)/sqrt(line(1) ^ 2 + line(2) ^ 2);

end