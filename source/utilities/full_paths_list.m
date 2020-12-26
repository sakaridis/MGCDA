% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function files_full_paths_cell = full_paths_list(root_dir, pattern_dir_command)
%UNTITLED10 Summary of this function goes here
%   Detailed explanation goes here
%   INPUTS:
%   
%   -pattern_dir_command: e.g. '**/*.png' to retrieve all PNG files under
%    root_dir

files_data = dir(fullfile(root_dir, pattern_dir_command));
files_dirs = {files_data(:).folder};
files_names = {files_data(:).name};
files_full_paths_cell = fullfile(files_dirs, files_names);

end

