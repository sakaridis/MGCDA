% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function ds_info = my_gen_ds_info_Dark_Zurich(ds_config)

ds_dir =...
    '/scratch_net/slap_second/csakarid/Nighttime/data/GoPro';

% Requires modifying root caller!
ds_instance_config_string = ds_config.instance_config;
ds_instance_configs = strsplit(ds_instance_config_string, '_');

% Dark Zurich with specified configurations.
train_idx_file = fullfile(ds_dir, 'lists_file_names',...
    strjoin({'RGB', ds_instance_config_string, 'filenames.txt'}, '_'));
fid = fopen(train_idx_file);
train_full_file_names = textscan(fid, '%s');
train_full_file_names = train_full_file_names{1};
fclose(fid);

% Assuming that split is specified at substring 1 and segmentation at substring
% 6.
GT_train_idx_file = fullfile(ds_dir, 'lists_file_names',...
    strjoin({'labels', ds_instance_configs{1}, ds_instance_configs{6},...
    'filenames.txt'}, '_'));
fid = fopen(GT_train_idx_file);
GT_train_full_file_names = textscan(fid, '%s');
GT_train_full_file_names = GT_train_full_file_names{1};
fclose(fid);

% Validation set is identical to training set. This trick is done to avoid an
% empty validation set which results in assertion error when using the default
% RefineNet training script.
val_full_file_names = train_full_file_names;
GT_val_full_file_names = GT_train_full_file_names;


train_num = size(train_full_file_names, 1);
img_full_file_names = cat(1, train_full_file_names, val_full_file_names);
GT_full_file_names = cat(1, GT_train_full_file_names, GT_val_full_file_names);
img_num = length(img_full_file_names);

img_files = cell(img_num, 1);
mask_files = cell(img_num, 1);
img_names = cell(img_num, 1);
% The first half of |data_dirs| corresponds to RGB images and the second one to
% annotations.
data_dirs = cell(1, 2 * img_num);

for t_idx=1:img_num
    current_image_file_name = img_full_file_names{t_idx};
    [data_dirs{t_idx}, img_names{t_idx}, ext] =...
        fileparts(current_image_file_name);
    img_files{t_idx} = strcat(img_names{t_idx}, ext);
    
    current_GT_file_name = GT_full_file_names{t_idx};
    [data_dirs{img_num + t_idx}, mask_name, ext] =...
        fileparts(current_GT_file_name);
    mask_files{t_idx} = strcat(mask_name, ext);
end

train_idxes = 1:train_num;
val_idxes = train_num + 1:img_num;

ds_info=[];

ds_info.img_names = img_names;
ds_info.img_files = img_files;
ds_info.mask_files = mask_files;

ds_info.train_idxes = uint32(train_idxes.');
ds_info.test_idxes = uint32(val_idxes.');

% ATTENTION! The uint16 statement below will not work for datasets with more
% than 65536 images.
data_dir_idxes_img = uint16((1:img_num).');
data_dir_idxes_mask = uint16(img_num + (1:img_num).');
ds_info.data_dir_idxes_img = data_dir_idxes_img;
ds_info.data_dir_idxes_mask = data_dir_idxes_mask;
ds_info.data_dirs = data_dirs;
ds_info.ds_dir = ds_dir;

ds_info.class_info = gen_class_info_cityscapes();
ds_info.ds_name = ds_config.ds_name;

% ------------------------------------------------------------------------------

% Include tailored version of the function |process_ds_info_classification|, as
% the generated fields by this function are required during training.
class_info=ds_info.class_info;

class_idxes_mask_dir = fullfile('..', 'datasets', ds_config.ds_name,...
    'my_class_idxes_mask');
mkdir_notexist(class_idxes_mask_dir);

fprintf('generating new annotations encoded by class indices...\n');

class_label_values = class_info.class_label_values;
assert(isa(class_label_values, 'uint8'));

class_num = length(class_label_values);
assert(class_num<2^8);

class_label_values_imgs = cell(img_num, 1);
class_idxes_imgs = cell(img_num, 1);
mask_files=cell(img_num, 1);
pixel_count_classes = zeros(class_num, 1);

assert(~ds_config.use_dummy_gt)
mask_cmap = VOClabelcolormap(256);

for img_idx=1:img_num
    
    mask_data = load_mask_from_ds_info(ds_info, img_idx);

    one_class_label_values = unique(mask_data);
    class_label_values_imgs{img_idx} = one_class_label_values;

    class_idxes_mask_data = zeros(size(mask_data), 'uint8');
    tmp_class_exist_flags = false(class_num, 1);

    for tmp_idx=1:length(one_class_label_values)
        
        one_label_value = one_class_label_values(tmp_idx);
        one_class_idx = find(one_label_value == class_label_values, 1);
        assert(~isempty(one_class_idx));

        tmp_sel = mask_data == one_label_value;
        class_idxes_mask_data(tmp_sel) = one_class_idx;

        pixel_count_classes(one_class_idx) =...
            pixel_count_classes(one_class_idx) + nnz(tmp_sel);

        tmp_class_exist_flags(one_class_idx) = true;

    end

    class_idxes_imgs{img_idx} = find(tmp_class_exist_flags);

    mask_file_name = ds_info.mask_files{img_idx};
    [~, mask_file_name] = fileparts(mask_file_name);
       
    % Save as indexed PNG image, where 1-based train IDs |class_idxes_mask_data|
    % are the indices of the colormap |mask_cmap|.
    new_mask_file_short=['img_idx_' num2str(img_idx) '_' mask_file_name '.png'];
    new_mask_file = fullfile(class_idxes_mask_dir, new_mask_file_short);
    imwrite(class_idxes_mask_data, mask_cmap, new_mask_file);
    
    if mod(img_idx, 100) == 1
        fprintf('save class_idxes_mask_data(%d/%d), file:%s\n', img_idx,...
            img_num, new_mask_file);
    end
    mask_files{img_idx} = new_mask_file_short;

end

class_idxes_mask_data_info = [];
class_idxes_mask_data_info.mask_files = mask_files;
class_idxes_mask_data_info.data_dirs = {class_idxes_mask_dir};
class_idxes_mask_data_info.data_dir_idxes_mask = ones(img_num, 1, 'uint8');

ds_info.class_idxes_mask_data_info = class_idxes_mask_data_info;
ds_info.class_idxes_imgs = class_idxes_imgs;

end


