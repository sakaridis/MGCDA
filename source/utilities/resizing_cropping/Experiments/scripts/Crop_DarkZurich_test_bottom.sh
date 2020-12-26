# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Parameters.
DATASET_SPLIT="test"
CROP_I_A="121"
CROP_J_A="1"
CROP_I_B="1080"
CROP_J_B="1920"
CROP_ATTRIBUTES="bottom"
OUTPUT_ROOT_DIR="../../../data/Dark_Zurich"
IMAGES_PER_TASK="302"

# Change directory to that containing the cropping script.
cd ../..

# Crop script.
matlab -nodesktop -nodisplay -nosplash -r "Crop_DarkZurich(1, '${DATASET_SPLIT}', [${CROP_I_A}, ${CROP_J_A}, ${CROP_I_B}, ${CROP_J_B}], '${CROP_ATTRIBUTES}', '${OUTPUT_ROOT_DIR}', ${IMAGES_PER_TASK}); exit;"

# Restore initial directory.
cd Experiments/scripts
