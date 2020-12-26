% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
% Stage-1: using a fixed learning rate for training until the performance
% get stable on the validation set. You need to manually stop the running of this training code.

% Stage-2: chose one cached model, initialize from this model, and using a
% lower learning rate (e.g., multiplied by 0.1) to perform further training. 

% For example, using the following setting for loading an existed model and
% using a lower learning rate:
% run_config.trained_model_path='../cache_data/voc2012_trainval/model_20161219094311_example/model_cache/epoch_70';
% run_config.learning_rate=5e-5;

% Please refer to the following demo file for perform further training with lower learning rate:
% demo_refinenet_train_reduce_learning_rate.m


% 4. Verify your trained model with performance evaluation:

% This demo file shows the training on the original PASCAL VOC 2012 dataset for semantic segmentation.
% This dataset consists of 1464 training images and 1449 validation images. 
% For this dataset, the training will take around 3 days using a Titan-X card, 
% including the training with a decreased learning rate.

function train_RefineNet_finetuning(experiment_configurations,...
    training_epochs, pretrained_model_path, results_dir, GPU_ID, condition_type, dataset_type)

% NOTE: At present, this script runs properly only if its directory coincides
% with the current working directory.

% Necessary check for backwards compatibility with scripts for experiments on
% fog.
if ~exist('condition_type', 'var')
    condition_type = 'fog';
end

if ~exist('dataset_type', 'var')
    dataset_type = 'synthetic';
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

% update the model name when reducing learning rate for training, e.g.,
% model_name='model_20161219094311_example_epoch70_low_learn_rate';

% Form the name of the fine-tuned model from the path to its output directory.
[~, run_config.model_name] = fileparts(results_dir);

% Function for generating dataset information.
switch condition_type
    case 'fog'
        gen_ds_info_fn = @my_gen_ds_info_Foggy_Cityscapes;
        ds_config.ds_name = strcat('Foggy_Cityscapes_',...
            experiment_configurations);
    case 'night'
        switch dataset_type
            case 'synthetic'
                gen_ds_info_fn = @my_gen_ds_info_Dark_Cityscapes;
                ds_config.ds_name = strcat('Dark_Cityscapes_',...
                    experiment_configurations);
            case 'real'
                gen_ds_info_fn = @my_gen_ds_info_Dark_Zurich;
                ds_config.ds_name = strcat('Dark_Zurich_',...
                    experiment_configurations);
        end
end

% Specify the range of dimensions for images in the dataset.
run_config.input_img_short_edge_min = 450;
run_config.input_img_short_edge_max = 1100;
run_config.input_img_scale = 1;

% Ground-truth annotations are required for minimizing the loss.
run_config.run_evaonly = false;
ds_config.use_dummy_gt = false;
run_config.use_dummy_gt = ds_config.use_dummy_gt;

% Configure generation of information for test dataset.
ds_config.instance_config = experiment_configurations;
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
run_config.eva_run_step = 10;
run_config.snapshot_step = 2;
% Use ResNet-101 as the backbone of the network, since the pre-trained RefineNet
% model also has this particular architectural feature.
run_config.init_resnet_layer_num = 101;

run_config.gen_network_fn = @gen_network_main;
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

% Fine-tuned the specified pre-trained RefineNet model and save snapshots in
% RefineNet format: .mat files of two types; net-config*.mat for model weights
% and exp-info*.mat for meta-information on the pre-trained model state.
my_net_tool(train_opts, imdb, net_config, net_exp_info);


fprintf('\n\n--------------------------------------------------\n\n');
disp('results are saved in:');
disp(run_config.root_cache_dir);


end


