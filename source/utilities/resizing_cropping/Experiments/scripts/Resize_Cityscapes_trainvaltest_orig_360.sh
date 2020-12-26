# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Parameters.
DATASET_SPLIT="trainvaltest"
RESIZE_ROWS="360"
RESIZE_COLS="720"
RESIZE_ATTRIBUTES="${RESIZE_ROWS}"
INPUT_ROOT_DIR="../../../data/Cityscapes"
OUTPUT_ROOT_DIR="../../../output/Cityscapes"
IMAGES_PER_TASK="5000"

# Change directory to that containing the resizing script.
cd ../..

# Resizing script.
matlab -nodesktop -nodisplay -nosplash -r "Resize_Cityscapes(1, '${DATASET_SPLIT}', [${RESIZE_ROWS}, ${RESIZE_COLS}], '${RESIZE_ATTRIBUTES}', '${INPUT_ROOT_DIR}', '${OUTPUT_ROOT_DIR}', ${IMAGES_PER_TASK}); exit;"

# Restore initial directory.
cd Experiments/scripts
