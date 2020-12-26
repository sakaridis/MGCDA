% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function train_RefineNet_finetuning_union(configurations_synthetic,...
    configurations_real, relative_weight_synthetic, training_epochs,...
    pretrained_model_path, results_dir, GPU_ID, condition_type)

% NOTE: At present, this script runs properly only if its directory coincides
% with the current working directory.

if ~exist('condition_type', 'var')
    condition_type = 'night';
end

% Fix random seed for reproducibility.
rng('default');

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

% Path to the pre-trained model that is used as initialization for the
% fine-tuning process.
run_config.trained_model_path = pretrained_model_path;

% Form the name of the fine-tuned model from the path to its output directory.
[~, run_config.model_name] = fileparts(results_dir);

% Function for generating dataset information.
gen_ds_info_fn = @my_gen_ds_info_union_Dark_Cityscapes_Dark_Zurich;

% Specify the range of dimensions for images in the dataset.
run_config.input_img_short_edge_min = 450;
run_config.input_img_short_edge_max = 1100;
run_config.input_img_scale = 1;

% Ground-truth annotations are required for minimizing the loss.
run_config.run_evaonly = false;
ds_config.use_dummy_gt = false;
run_config.use_dummy_gt = ds_config.use_dummy_gt;

% Configure generation of information for dataset.
ds_config.instance_config_synthetic = configurations_synthetic;
ds_config.instance_config_real = configurations_real;
ds_config.relative_weight_synthetic = relative_weight_synthetic;
configurations_real_split = strsplit(configurations_real, '_');
ds_config.ds_name = strjoin({'Union_Dark_Cityscapes',...
    configurations_synthetic, 'Dark_Zurich',...
    configurations_real_split{1}, 'labels',...
    strjoin(configurations_real_split(2:end), '_'), 'w',...
    num2str(round(relative_weight_synthetic))}, '_');
if length(ds_config.ds_name) > 255
    ds_config.ds_name = strjoin({'Union_Dark_Cityscapes',...
        configurations_synthetic, 'DZ',...
        configurations_real_split{1}, 'labels',...
        strjoin(configurations_real_split(2:end), '_'), 'w',...
        num2str(round(relative_weight_synthetic))}, '_');
end
ds_config.gen_ds_info_fn = gen_ds_info_fn;
ds_config.ds_info_cache_dir = fullfile('../datasets', ds_config.ds_name);
ds_config.use_custom_data = false;
ds_info = gen_dataset_info(ds_config);

% Directory to save artifacts of training experiment.
run_config.root_cache_dir = results_dir;
mkdir_notexist(run_config.root_cache_dir);

% Retrieve directory and name of this script.
run_dir_name = fileparts(mfilename('fullpath'));
[~, run_dir_name] = fileparts(run_dir_name);
run_config.run_dir_name = run_dir_name;
run_config.run_file_name = mfilename();

% ------------------------------------------------------------------------------

fprintf('\n\n--------------------------------------------------\n\n');
disp('run network');

% Training configurations.

run_config.learning_rate = 5e-5;
run_config.epoch_num = training_epochs;
% Turn on this option to cache all data into memory.
run_config.cache_data_mem = false;
run_config.crop_box_size = 600;
run_config.eva_run_step = 40;
run_config.snapshot_step = 2;
% Use ResNet-101 as the backbone of the network, since the pre-trained RefineNet
% model also has this particular architectural feature.
run_config.init_resnet_layer_num = 101;

run_config.gen_network_fn = @gen_network_main;
run_config.gen_net_opts_fn = @gen_net_opts_model_type1;
train_opts = run_config.gen_net_opts_fn(run_config, ds_info.class_info);
imdb = my_gen_imdb(train_opts, ds_info);

% Mean value for each of the RGB channels to be subtracted from the input image.
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

% Fine-tuned the specified pre-trained RefineNet model and save snapshots in
% RefineNet format: .mat files of two types; net-config*.mat for model weights
% and exp-info*.mat for meta-information on the pre-trained model state.
my_net_tool(train_opts, imdb, net_config, net_exp_info);


fprintf('\n\n--------------------------------------------------\n\n');
disp('results are saved in:');
disp(run_config.root_cache_dir);


end


