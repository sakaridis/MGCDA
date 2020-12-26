% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function addpath_relative_to_caller(caller_filename, relative_path)
%ADDPATH_RELATIVE_TO_CALLER  Add directory to MATLAB search path, using its
%relative path with respect to the function which has called the present
%function.
%
%   INPUTS:
%
%   -|caller_filename|: full path to caller function, obtained with |mfilename|.
%
%   -|relative_path|: path of the directory to be added relative to the
%    directory of the caller function.

caller_path = fileparts(caller_filename);
addpath(fullfile(caller_path, relative_path));

end

