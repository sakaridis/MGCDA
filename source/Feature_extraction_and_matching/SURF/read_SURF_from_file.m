% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function [SURF_points, SURF_descriptors] = read_SURF_from_file(SURF_file)
%READ_SURF_FROM_FILE  Read SURF points and corresponding descriptors from ASCII
%file that follows the SURF format.
%
% INPUT:
%
%   -|SURF_file|: full path to ASCII file with SURF results - N feature points
%    and M features per point.
%
% OUTPUTS:
%
%   -|SURF_points|: 2-by-N matrix, where each column corresponds to the image
%    coordinates of a feature point.
%
%   -|SURF_descriptors|: M-by-N matrix, where each column is the feature vector
%    assigned to the feature point of the corresponding column of |SURF_points|.

% Open the input SURF file for reading.
fid = fopen(SURF_file);

% Read the feature dimensionality (M) from the first line of the file.
M = textscan(fid, '%d\n', 1);
M = M{1} - 1;

% Read the number of feature points from the second line of the file.
N = textscan(fid, '%d\n', 1);
N = N{1};

% Initialize the main matrices to receive the SURF results.
SURF_points = zeros(2, N);
SURF_descriptors = zeros(M, N);

% Main loop for reading the SURFs from the file.
for i = 1:N
    current_input_line = textscan(fid, '%s', 1, 'Delimiter', '\n');
    current_input_line = current_input_line{1};
    current_point_SURF_info = str2num(current_input_line{1});
    SURF_points(:, i) = current_point_SURF_info(1:2);
    SURF_descriptors(:, i) = current_point_SURF_info(7:7 + M - 1);
end

% Close the SURF file after having finished reading.
fclose(fid);

end

