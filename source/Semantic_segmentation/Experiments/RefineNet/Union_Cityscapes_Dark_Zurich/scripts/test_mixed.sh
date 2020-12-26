# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Arguments:
# 1: synthetic training dataset configurations as an underscore-delimited string.
# 2: real training dataset configurations as an underscore-delimited string.
# 3: initialization configurations for tested model as an underscore-delimited string encoding initial model base name.
# 4: relative weight of each individual synthetic image to each individual real image of the complete training dataset.
# 5: number of training epochs for generating used snapshot.
# 6: image database for testing.

# Decode initialization configurations.
init_train_configs=($(echo ${3} | tr "_" "\n"))

# Decode training dataset configurations.
synthetic_train_configs=($(echo ${1} | tr "_" "\n"))
real_train_configs=($(echo ${2} | tr "_" "\n"))

# Define variables.
snapshot_prefix="refinenet_res101_cityscapes_"
RefineNet_source_dir="../../../../refinenet/main"
eval_source_dir="../../../../../Evaluation"
RefineNet_source_dir_relative_to_eval_source_dir="../Semantic_segmentation/refinenet/main"
output_root_dir="../../../../output/RefineNet" # Relative to ${RefineNet_source_dir}.

# Form the full name of the snapshot of the tested model, based on specified initialization configurations.
if [ ${init_train_configs[0]} = "DarkCityscapes" ]
then
    init_train_configs_per_dataset=($(echo ${3} | sed 's/_DarkZurich_/ /g'))
    init_train_configs_synthetic="${init_train_configs_per_dataset[0]}"
    init_train_configs_real="${init_train_configs_per_dataset[1]}"
    real_configs_components=($(echo ${2} | sed 's/_refinenet_/ /g'))
    # If the initial model is also used to get the labels of the real training dataset, simplify the field of the tested snapshot's name pertaining to the labels of the real training dataset to "adaptedPrev".
    if [ ${real_configs_components[1]} = ${3} ]
    then
        snapshot="${snapshot_prefix}${init_train_configs_synthetic}_${synthetic_train_configs[3]}_${synthetic_train_configs[2]}_DarkZurich_${init_train_configs_real}_${real_train_configs[0]}_labels_adaptedPrev_w_${4}_epoch_${5}"
    fi
    # If the initial model is also used to get the labels of the real training dataset, but the daytime-dynamic-geometrically-refined version of these is used, simplify the field of the tested snapshot's name pertaining to the labels of the real training dataset to "adaptedPrevGeoRefDyn".
    if [ "${real_configs_components[1]}" = "${3}_geoRefDynDay" ]
    then
        snapshot="${snapshot_prefix}${init_train_configs_synthetic}_${synthetic_train_configs[3]}_${synthetic_train_configs[2]}_DarkZurich_${init_train_configs_real}_${real_train_configs[0]}_labels_adaptedPrevGeoRefDyn_w_${4}_epoch_${5}"
    fi
    # If the initial model is also used to get the labels of the real training dataset, but the daytime-refined version of these is used, simplify the field of the tested snapshot's name pertaining to the labels of the real training dataset to "adaptedPrevRefined".
    if [ "${real_configs_components[1]}" = "${3}_refinedDay" ]
    then
        snapshot="${snapshot_prefix}${init_train_configs_synthetic}_${synthetic_train_configs[3]}_${synthetic_train_configs[2]}_DarkZurich_${init_train_configs_real}_${real_train_configs[0]}_labels_adaptedPrevRefined_w_${4}_epoch_${5}"
    fi
    # If the initial model is also used to get the labels of the real training dataset, but the daytime-dynamic-refined version of these is used, simplify the field of the tested snapshot's name pertaining to the labels of the real training dataset to "adaptedPrevRefDyn".
    if [ "${real_configs_components[1]}" = "${3}_refDynDay" ]
    then
        snapshot="${snapshot_prefix}${init_train_configs_synthetic}_${synthetic_train_configs[3]}_${synthetic_train_configs[2]}_DarkZurich_${init_train_configs_real}_${real_train_configs[0]}_labels_adaptedPrevRefDyn_w_${4}_epoch_${5}"
    fi
else
    snapshot="${snapshot_prefix}DarkCityscapes_${synthetic_train_configs[3]}_${synthetic_train_configs[2]}_DarkZurich_${real_train_configs[0]}_labels_${3}_w_${4}_epoch_${5}"
fi

# Create directory for storing predictions of the model for the test dataset.
predictions_root_dir="${output_root_dir}/${6}/${snapshot}" # Relative to ${RefineNet_source_dir}.

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
matlab -nodesktop -nodisplay -nosplash -r "test_RefineNet('${output_root_dir}/Union_Cityscapes_Dark_Zurich/${snapshot}.mat', '${6}', '${predictions_root_dir}', 0); exit;"

# Process existing predictions in train ID and color format and generate predictions in ID format. The target is to have three directories with predictions of the current model, with IDs, train IDs, and color.
RefineNet_color_dir="predict_result_mask"
RefineNet_train_IDs_dir="predict_result_full"

cd ${predictions_root_dir}
mv ${RefineNet_color_dir}/ ${color_dir}/

cd ${current_script_dir}/${eval_source_dir}
matlab -nodesktop -nodisplay -nosplash -r "RefineNet_convert_ID_predictions_to_images('${RefineNet_source_dir_relative_to_eval_source_dir}/${predictions_root_dir}/${RefineNet_train_IDs_dir}', '${RefineNet_source_dir_relative_to_eval_source_dir}/${predictions_root_dir}/${train_IDs_dir}'); Cityscapes_compute_and_save_labelIds_from_labelTrainIds('${RefineNet_source_dir_relative_to_eval_source_dir}/${predictions_root_dir}/${train_IDs_dir}', '${RefineNet_source_dir_relative_to_eval_source_dir}/${predictions_root_dir}/${IDs_dir}'); exit;"
cd ${current_script_dir}

echo Testing completed at: `date`

