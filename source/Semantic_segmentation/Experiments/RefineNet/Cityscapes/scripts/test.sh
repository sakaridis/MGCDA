# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Arguments:
# 1: model configurations as an underscore-delimited string encoding model parameters. Examples: original.
# 2: number of training epochs for generating used snapshot.
# 3: image database for testing.
# 4: optional initialization configurations as an underscore-delimited string encoding initial model base name.

# Define variables.
snapshot_prefix="refinenet_res101_cityscapes_"
RefineNet_source_dir="../../../../refinenet/main"
output_root_dir="../../../../output/RefineNet" # Relative to ${RefineNet_source_dir}.

# Decode model configurations.
model_configurations=($(echo ${1} | tr "_" "\n"))

# Form full name for network snapshot.
if [ ${1} == "original" ]
then
    snapshot="${snapshot_prefix}${1}"
else
    if [ -z "${4}" ]
    then
        snapshot="${snapshot_prefix}${1}_epoch_${2}"
    else
        snapshot="${snapshot_prefix}${4}_${model_configurations[4]}_epoch_${2}"
    fi
fi

# Create directory for storing predictions of the model for the test dataset.
predictions_root_dir="${output_root_dir}/${3}/${snapshot}"

# ------------------------------------------------------------------------------
# Testing.
# ------------------------------------------------------------------------------

# Define directory names for label formats in predictions.
train_IDs_dir="labelTrainIds"
IDs_dir="labelIds"
color_dir="color"

# Set paths for RefineNet.
current_script_dir=$(pwd)
cd ${RefineNet_source_dir}
source setpath.sh

# Generate predictions in RefineNet formats: color plus .mat files that include a |mask_data| field holding the prediction in train IDs format.
matlab -nodesktop -nodisplay -nosplash -r "test_RefineNet('${output_root_dir}/Cityscapes/${snapshot}.mat', '${3}', '${predictions_root_dir}', 0); exit;"
cd ${current_script_dir}

# Process existing predictions in train ID and color format and generate predictions in ID format. The target is to have three directories with predictions of the current model, with IDs, train IDs, and color.
RefineNet_color_dir="predict_result_mask"
RefineNet_train_IDs_dir="predict_result_full"

cd ${predictions_root_dir}
mv ${RefineNet_color_dir}/ ${color_dir}/

cd ${current_script_dir}
matlab -nodesktop -nodisplay -nosplash -r "addpath(fullfile('..', '..', '..', '..', '..', 'Evaluation')); RefineNet_convert_ID_predictions_to_images('${predictions_root_dir}/${RefineNet_train_IDs_dir}', '${predictions_root_dir}/${train_IDs_dir}'); Cityscapes_compute_and_save_labelIds_from_labelTrainIds('${predictions_root_dir}/${train_IDs_dir}', '${predictions_root_dir}/${IDs_dir}'); exit;"

echo Testing completed at: `date`

