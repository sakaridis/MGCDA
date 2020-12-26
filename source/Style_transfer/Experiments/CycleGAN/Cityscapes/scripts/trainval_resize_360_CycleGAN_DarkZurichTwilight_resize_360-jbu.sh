# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Define directories.
SOURCE_DIR="../../../.." # Relative to current working directory, assuming it coincides with the directory of the current script.
DATASET_SOURCE_ROOT_DIR="../../data/Cityscapes" # Relative to ${SOURCE_DIR} from which the experiment is executed.
DATASET_STYLIZED_ROOT_DIR="../../output/Cityscapes" # Relative to ${SOURCE_DIR} from which the experiment is executed.
OUTPUT_ROOT_DIR="../../output/Cityscapes" # Relative to ${SOURCE_DIR} from which the experiment is executed.

# Parameters.
IMAGES_PER_TASK="3475"
DATASET_DAY="Cityscapes"
DATASET_DAY_SPLIT="trainval"
DATASET_STYLIZED_NIGHT="Dark_Cityscapes"
CYCLEGAN_CONFIGS="DarkZurichTwilight_resize_360"
INPUT_SUFFIX="_resize_360_fake_B"
OUTPUT_SUFFIX="_fake_B"

# Change directory to that of the upsampling script.
cd ${SOURCE_DIR}

# Run upsampling.
matlab -nodesktop -nodisplay -nosplash -r "joint_color_bilateral_upsampling_for_dataset(1, ${IMAGES_PER_TASK}, '${DATASET_DAY}', '${DATASET_DAY_SPLIT}', '${DATASET_STYLIZED_NIGHT}', '${DATASET_SOURCE_ROOT_DIR}', '${DATASET_STYLIZED_ROOT_DIR}', '${CYCLEGAN_CONFIGS}', '${INPUT_SUFFIX}', '${OUTPUT_SUFFIX}', '${OUTPUT_ROOT_DIR}'); exit;"

# Restore pwd.
cd Experiments/CycleGAN/Cityscapes/scripts
