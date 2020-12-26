# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Define directories.
SOURCE_DIR="../../../../pytorch-CycleGAN-and-pix2pix" # Relative to current working directory, assuming it coincides with the directory of the current script.
OUTPUT_ROOT_DIR="../../../output/Cityscapes" # Relative to ${SOURCE_DIR} from which the experiment is executed.
DARK_ZURICH_ROOT_DIR="../../../output/Dark_Zurich" # Relative to ${SOURCE_DIR} from which the experiment is executed.
CHECKPOINTS_DIR="../../../output/CycleGAN/checkpoints" # Modify as required.

# Parameters.
DATASETS_NAME="cityscapes_resize_360_2_darkzurichnight_resize_360"

cd ${SOURCE_DIR}

# Create dataset directories for CycleGAN training and testing data using symbolic links.
mkdir datasets/${DATASETS_NAME}

mkdir datasets/${DATASETS_NAME}/trainA datasets/${DATASETS_NAME}/testA
ln -s ${OUTPUT_ROOT_DIR}/leftImg8bit_trainvaltest_orig_resize_360/train datasets/${DATASETS_NAME}/trainA
ln -s ${OUTPUT_ROOT_DIR}/leftImg8bit_trainvaltest_orig_resize_360/train datasets/${DATASETS_NAME}/testA
ln -s ${OUTPUT_ROOT_DIR}/leftImg8bit_trainvaltest_orig_resize_360/val datasets/${DATASETS_NAME}/testA

ln -s ${DARK_ZURICH_ROOT_DIR}/rgb_crop_bottom_resize_360/train/night datasets/${DATASETS_NAME}/trainB
ln -s ${DARK_ZURICH_ROOT_DIR}/rgb_crop_bottom_resize_360/train/night datasets/${DATASETS_NAME}/testB

# Activate conda environment for CycleGAN.
conda activate pytorch-CycleGAN-and-pix2pix

# Train CycleGAN with full 360x720 images.
python train.py --dataroot ./datasets/${DATASETS_NAME} \
--checkpoints_dir ${CHECKPOINTS_DIR} \
--name ${DATASETS_NAME}_cyclegan \
--model cycle_gan \
--preprocess none \
--display_id 0

# Test CycleGAN for translating downsized 360x720 Cityscapes images to Dark Zurich-night domain.
python test.py --dataroot ./datasets/${DATASETS_NAME}/testA \
--checkpoints_dir ${CHECKPOINTS_DIR} \
--name ${DATASETS_NAME}_cyclegan \
--model test \
--model_suffix _A \
--epoch 45 \
--preprocess none \
--num_test 3500 \
--results_dir ${OUTPUT_ROOT_DIR}/leftImg8bit_trainval_dark_CycleGAN_DarkZurichNight_resize_360

# Switch back to default environment.
conda deactivate

# Restore pwd.
cd ../Experiments/CycleGAN/Cityscapes/scripts
