# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Arguments:
# 1: synthetic dataset configurations as an underscore-delimited string.
# 2: real dataset configurations as an underscore-delimited string.
# 3: initialization configurations as an underscore-delimited string encoding initial model base name.
# 4: relative weight of each individual synthetic image to each individual real image.
# 5: number of training epochs.
# 6: number of epochs for initialization snapshot.

# Decode initialization configurations.
init_configs=($(echo ${3} | tr "_" "\n"))

# Decode dataset configurations.
synthetic_configurations=($(echo ${1} | tr "_" "\n"))
real_configurations=($(echo ${2} | tr "_" "\n"))

# Define variables.
snapshot_prefix="refinenet_res101_cityscapes_"
RefineNet_source_dir="../../../../refinenet/main"
output_root_dir="../../../../output/RefineNet/Union_Cityscapes_Dark_Zurich" # Relative to ${RefineNet_source_dir}.
original_model_dir="../../../../output/RefineNet/Cityscapes" # Relative to ${RefineNet_source_dir}.

# Form names for initial snapshot and trained snapshot based on specified initialization configurations.
if [ ${init_configs[0]} = "DarkCityscapes" ]
then
    init_root_dir="${output_root_dir}"
    # Full path to initial RefineNet model, the weights of which are used as a starting point for the current training.
    snapshot_initial="${init_root_dir}/${snapshot_prefix}${3}_epoch_${6}.mat"
    # Base name for trained snapshot.
    init_configs_per_dataset=($(echo ${3} | sed 's/_DarkZurich_/ /g'))
    init_configs_synthetic="${init_configs_per_dataset[0]}"
    init_configs_real="${init_configs_per_dataset[1]}"
    real_configs_components=($(echo ${2} | sed 's/_refinenet_/ /g'))
    # If the initial snapshot is also used to get the labels of the real dataset, simplify the field of the trained snapshot's name pertaining to the labels of the real dataset to "adaptedPrev".
    if [ ${real_configs_components[1]} = ${3} ]
    then
        snapshot="${snapshot_prefix}${init_configs_synthetic}_${synthetic_configurations[3]}_${synthetic_configurations[2]}_DarkZurich_${init_configs_real}_${real_configurations[0]}_labels_adaptedPrev_w_${4}"
    fi
    # If the initial snapshot is also used to get the labels of the real dataset, but the daytime-dynamic-geometrically-refined version of these is used, simplify the field of the trained snapshot's name pertaining to the labels of the real dataset to "adaptedPrevGeoRefDyn".
    if [ "${real_configs_components[1]}" = "${3}_geoRefDynDay" ]
    then
        snapshot="${snapshot_prefix}${init_configs_synthetic}_${synthetic_configurations[3]}_${synthetic_configurations[2]}_DarkZurich_${init_configs_real}_${real_configurations[0]}_labels_adaptedPrevGeoRefDyn_w_${4}"
    fi
    # If the initial snapshot is also used to get the labels of the real dataset, but the daytime-refined version of these is used, simplify the field of the trained snapshot's name pertaining to the labels of the real dataset to "adaptedPrevRefined".
    if [ "${real_configs_components[1]}" = "${3}_refinedDay" ]
    then
        snapshot="${snapshot_prefix}${init_configs_synthetic}_${synthetic_configurations[3]}_${synthetic_configurations[2]}_DarkZurich_${init_configs_real}_${real_configurations[0]}_labels_adaptedPrevRefined_w_${4}"
    fi
    # If the initial snapshot is also used to get the labels of the real dataset, but the daytime-dynamic-refined version of these is used, simplify the field of the trained snapshot's name pertaining to the labels of the real dataset to "adaptedPrevRefDyn".
    if [ "${real_configs_components[1]}" = "${3}_refDynDay" ]
    then
        snapshot="${snapshot_prefix}${init_configs_synthetic}_${synthetic_configurations[3]}_${synthetic_configurations[2]}_DarkZurich_${init_configs_real}_${real_configurations[0]}_labels_adaptedPrevRefDyn_w_${4}"
    fi
else
    # First adaptation step, initialized with original RefineNet model.
    # Full path to initial RefineNet model, the weights of which are used as a starting point for the current training.
    init_root_dir="${original_model_dir}"
    snapshot_initial="${init_root_dir}/${snapshot_prefix}${3}.mat"
    # Base name for trained snapshot.
    snapshot="${snapshot_prefix}DarkCityscapes_${synthetic_configurations[3]}_${synthetic_configurations[2]}_DarkZurich_${real_configurations[0]}_labels_${3}_w_${4}"
fi

# Directory for storing artifacts of training the model.
output_dir="${output_root_dir}/${snapshot}" # Relative to ${RefineNet_source_dir}.

# Place initial weights and meta-info at the directory that is expected by RefineNet for fine-tuning.
init_info_dir="${output_dir}/model_cache/snapshot" # Relative to ${RefineNet_source_dir}.

current_script_dir=$(pwd)
cd ${RefineNet_source_dir}

mkdir -p ${init_info_dir}
cp ${snapshot_initial} ${init_info_dir}/net-config-snapshot.mat
cp ${original_model_dir}/exp-info-snapshot.mat ${init_info_dir}

# Set paths for RefineNet.
source setpath.sh

# Fine-tune.
/usr/sepp/bin/matlab-2016b -nodesktop -nodisplay -nosplash -r "train_RefineNet_finetuning_union('${1}', '${2}', ${4}, ${5}, '${snapshot_initial}', '${output_dir}', 0, 'night'); exit;"

# Copy final model to standard location for resulting models.
cp ${output_dir}/model_cache/epoch_${5}/net-config-epoch-${5}.mat ${output_root_dir}/${snapshot}_epoch_${5}.mat
cd ${current_script_dir}

echo Training completed at: `date`


