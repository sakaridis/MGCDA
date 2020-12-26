% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function test_RefineNet(model_path, imdb_test, results_dir, GPU_ID)

% NOTE: At present, this script runs properly only if its directory coincides
% with the current working directory.

% Set up MatConvNet.
addpath('./my_utils');
dir_matConvNet = '../libs/matconvnet/matlab';
run(fullfile(dir_matConvNet, 'vl_setupnn.m'));

run_config = [];
ds_config = [];

% Specify available GPU to MatConvNet.
if ischar(GPU_ID)
    GPU_ID = str2double(GPU_ID);
end
run_config.use_gpu = true;
% 1-based indexing of GPU devices in MATLAB.
run_config.gpu_idx = GPU_ID + 1;

% Path to the trained model that is being tested.
run_config.trained_model_path = model_path;

% All examined datasets have the same set of classes as Cityscapes.
ds_config.class_info = gen_class_info_cityscapes();

% Depending on the dataset that is used for testing, specify:
% 1) the proper function for generating dataset information.
% 2) the range of dimensions for the images in the dataset.
% 3) the set of testing scales, encompassing the case of multiscale testing.
% 4) the full name of the dataset.
if contains(imdb_test, 'Dark_Cityscapes')
        gen_ds_info_fn = @my_gen_ds_info_Dark_Cityscapes;
        run_config.input_img_short_edge_min = 1000;
        run_config.input_img_short_edge_max = 1100;
        run_config.input_img_scale = 0.8;
elseif strcmp(imdb_test, 'Dark_Zurich_day')
        gen_ds_info_fn = @my_gen_ds_info_Dark_Zurich_day;
        run_config.input_img_short_edge_min = 1000;
        run_config.input_img_short_edge_max = 1100;
        run_config.input_img_scale = 0.8;
elseif strcmp(imdb_test, 'Dark_Zurich_twilight')
        gen_ds_info_fn = @my_gen_ds_info_Dark_Zurich_twilight;
        run_config.input_img_short_edge_min = 1000;
        run_config.input_img_short_edge_max = 1100;
        run_config.input_img_scale = 0.8;
elseif strcmp(imdb_test, 'Dark_Zurich_night')
        gen_ds_info_fn = @my_gen_ds_info_Dark_Zurich_night;
        run_config.input_img_short_edge_min = 1000;
        run_config.input_img_short_edge_max = 1100;
        run_config.input_img_scale = 0.8;
elseif strcmp(imdb_test, 'Dark_Zurich_test')
        gen_ds_info_fn = @my_gen_ds_info_Dark_Zurich_test;
        run_config.input_img_short_edge_min = 1000;
        run_config.input_img_short_edge_max = 1100;
        run_config.input_img_scale = 0.8;
elseif strcmp(imdb_test, 'Dark_Zurich_test_anon')
        gen_ds_info_fn = @my_gen_ds_info_Dark_Zurich_test_anon;
        run_config.input_img_short_edge_min = 1000;
        run_config.input_img_short_edge_max = 1100;
        run_config.input_img_scale = 0.8;
elseif strcmp(imdb_test, 'Dark_Zurich_testRefDay')
        gen_ds_info_fn = @my_gen_ds_info_Dark_Zurich_testRefDay;
        run_config.input_img_short_edge_min = 1000;
        run_config.input_img_short_edge_max = 1100;
        run_config.input_img_scale = 0.8;
elseif strcmp(imdb_test, 'Dark_Zurich_val')
        gen_ds_info_fn = @my_gen_ds_info_Dark_Zurich_val;
        run_config.input_img_short_edge_min = 1000;
        run_config.input_img_short_edge_max = 1100;
        run_config.input_img_scale = 0.8;
elseif strcmp(imdb_test, 'Dark_Zurich_val_anon')
        gen_ds_info_fn = @my_gen_ds_info_Dark_Zurich_val_anon;
        run_config.input_img_short_edge_min = 1000;
        run_config.input_img_short_edge_max = 1100;
        run_config.input_img_scale = 0.8;
elseif strcmp(imdb_test, 'BDD100K_night_trainval_correct')
        gen_ds_info_fn = @my_gen_ds_info_BDD100K_night_trainval_correct;
        run_config.input_img_short_edge_min = 300;
        run_config.input_img_short_edge_max = 960;
        run_config.input_img_scale = 0.8;
elseif strcmp(imdb_test, 'Nighttime_Driving')
        gen_ds_info_fn = @my_gen_ds_info_Nighttime_Driving;
        run_config.input_img_short_edge_min = 1000;
        run_config.input_img_short_edge_max = 1100;
        run_config.input_img_scale = 0.8;
end

% Only generate predictions for test dataset, without evaluating against ground
% truth; ground truth annotations are not required.
run_config.run_evaonly = true;
ds_config.use_dummy_gt = true;
run_config.use_dummy_gt = ds_config.use_dummy_gt;

% Configure generation of information for test dataset.
ds_config.ds_name = imdb_test;
ds_config.gen_ds_info_fn = gen_ds_info_fn;
ds_config.ds_info_cache_dir = fullfile('../datasets', ds_config.ds_name);
ds_config.use_custom_data = false;
ds_info = gen_dataset_info(ds_config);

% Directory to save predictions.
run_config.root_cache_dir = results_dir;
mkdir_notexist(run_config.root_cache_dir);

[~, run_config.model_name] = fileparts(model_path);
% Retrieve directory and name of this script.
run_dir_name = fileparts(mfilename('fullpath'));
[~, run_dir_name] = fileparts(run_dir_name);
run_config.run_dir_name = run_dir_name;
run_config.run_file_name = mfilename();

% Training and testing configurations.
run_config.gen_net_opts_fn = @gen_net_opts_model_type1;
train_opts = run_config.gen_net_opts_fn(run_config, ds_info.class_info);
imdb = my_gen_imdb(train_opts, ds_info);
% Mean value for all channels; can be modified according to statistics of
% training set.
data_norm_info = [];
data_norm_info.image_mean = 128;
imdb.ref.data_norm_info = data_norm_info;

if run_config.use_gpu
	gpu_num = gpuDeviceCount;
	if gpu_num >= 1
		gpuDevice(run_config.gpu_idx);
    else
        error('no gpu found!');
	end
end

[net_config, net_exp_info] = prepare_running_model(train_opts);

% Test the specified RefineNet model and generate predictions in RefineNet
% format: color images, plus .mat files that include a |mask_data| field
% holding the prediction in train IDs format.
my_net_tool(train_opts, imdb, net_config, net_exp_info);


fprintf('\n\n--------------------------------------------------\n\n');
disp('All predictions are generated.');
fprintf('\n\n--------------------------------------------------\n\n');

end


