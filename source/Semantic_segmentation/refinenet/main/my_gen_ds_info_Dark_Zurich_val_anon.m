% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function ds_info = my_gen_ds_info_Dark_Zurich_val_anon(ds_config)

ds_dir = fullfile('..', '..', '..', '..', 'data', 'Dark_Zurich');

% In Dark Zurich test, no image is used for training.
train_full_file_names=cell(0, 1);

val_idx_file = fullfile(ds_dir, 'lists_file_names', 'val_filenames.txt');
fid = fopen(val_idx_file);
val_full_file_names = textscan(fid, '%s');
val_full_file_names = val_full_file_names{1};
fclose(fid);

val_full_file_names = fullfile(ds_dir, 'rgb_anon',...
    strcat(val_full_file_names, '_rgb_anon.png'));

train_num=length(train_full_file_names);
img_full_file_names=cat(1, train_full_file_names, val_full_file_names);
img_num=length(img_full_file_names);

img_files = cell(img_num, 1);
img_names = cell(img_num, 1);
data_dirs = cell(1, img_num);

for t_idx=1:img_num
    current_image_file_name = img_full_file_names{t_idx};
    [data_dirs{t_idx}, img_names{t_idx}, ext] = fileparts(current_image_file_name);
    img_files{t_idx} = strcat(img_names{t_idx}, ext);
end

train_idxes=1:train_num;
val_idxes=train_num+1:img_num;

ds_info=[];

ds_info.img_names = img_names;
ds_info.img_files = img_files;
ds_info.mask_files = [];

ds_info.train_idxes=uint32(train_idxes.');
ds_info.test_idxes=uint32(val_idxes.');

% ATTENTION! The uint16 statement below will not work for datasets with more
% than 65536 images.
data_dir_idxes_img=uint16((1:img_num).');
ds_info.data_dir_idxes_img = data_dir_idxes_img;
ds_info.data_dir_idxes_mask=[];
ds_info.data_dirs=data_dirs;
ds_info.ds_dir = ds_dir;

ds_info.class_info = gen_class_info_cityscapes();
ds_info.ds_name = ds_config.ds_name;
% ds_info = process_ds_info_classification(ds_info, ds_config);

end


