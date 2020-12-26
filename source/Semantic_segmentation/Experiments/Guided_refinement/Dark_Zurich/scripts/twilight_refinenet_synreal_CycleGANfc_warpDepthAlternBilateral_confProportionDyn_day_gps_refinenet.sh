# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Define directories.
SOURCE_DIR="../../../../Guided_refinement" # Relative to current working directory, assuming it coincides with the directory of the current script.

# Parameters.
IMAGES_PER_TASK="2920"
SUBSET="train"
DATASET_VERSION="rgb_anon"
SPLIT_DARK="twilight"
SPLIT_LIGHT="day"
FEATURE_RESULTS_ROOT_DIR="../../../output/Feature_extraction_and_matching" # Relative to ${SOURCE_DIR}.
FEATURE_METHOD="SURF"
DEPTH_RESULTS_ROOT_DIR="../../../output/Depth_estimation" # Relative to ${SOURCE_DIR}.
DEPTH_METHOD="monodepth2"
MODEL_TYPE="refinenet"
MODEL_CONFIG_DARK="DarkCityscapes_DarkZurichTwilight_CycleGANfc_DarkZurich_day_labels_original_w_1_epoch_10"
MODEL_CONFIG_LIGHT="original"
SEGMENTATION_REFINEMENT_VARIANT="depth_based_warping_with_bilateral_filtering_alternative_and_confidence_proportion_weighting_with_dynamic_class_distinction"
SEGMENTATION_RESULTS_ROOT_DIR="../../../output" # Relative to ${SOURCE_DIR}.

current_script_dir=$(pwd)
cd ${SOURCE_DIR}

# Run guided segmentation refinement.
matlab -nodesktop -nodisplay -nosplash -r "Geometric_segmentation_refinement_Dark_Zurich(1, '${DATASET_VERSION}', '${SUBSET}', '${SPLIT_DARK}', '${SPLIT_LIGHT}', '${FEATURE_RESULTS_ROOT_DIR}', '${FEATURE_METHOD}', '${DEPTH_RESULTS_ROOT_DIR}', '${DEPTH_METHOD}', '${SEGMENTATION_RESULTS_ROOT_DIR}', '${MODEL_TYPE}', '${MODEL_CONFIG_DARK}', '${MODEL_CONFIG_LIGHT}', '${SEGMENTATION_REFINEMENT_VARIANT}', ${IMAGES_PER_TASK}); exit;"

cd ${current_script_dir}
