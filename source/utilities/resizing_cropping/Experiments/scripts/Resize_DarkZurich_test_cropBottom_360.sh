# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Parameters.
DATASET_SPLIT="test"
DATASET_VERSION="rgb_crop_bottom"
RESIZE_ROWS="360"
RESIZE_COLS="720"
RESIZE_ATTRIBUTES="${RESIZE_ROWS}"
INPUT_ROOT_DIR="../../../output/Dark_Zurich"
OUTPUT_ROOT_DIR="../../../output/Dark_Zurich"
IMAGES_PER_TASK="302"

# Change directory to that containing the resizing script.
cd ../..

# Resizing script.
matlab -nodesktop -nodisplay -nosplash -r "Resize_DarkZurich(1, '${DATASET_SPLIT}', '${DATASET_VERSION}', [${RESIZE_ROWS}, ${RESIZE_COLS}], '${RESIZE_ATTRIBUTES}', '${INPUT_ROOT_DIR}', '${OUTPUT_ROOT_DIR}', ${IMAGES_PER_TASK}); exit;"

# Restore initial directory.
cd Experiments/scripts
