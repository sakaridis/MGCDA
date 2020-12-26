# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)

# MGCDA train script. Assumption: pwd is the directory of this script.


# -------------------------------------------------------------
# 1) Downsize Dark Zurich and Cityscapes for CycleGAN training.
# -------------------------------------------------------------

# Change directory to that containing the cropping and resizing scripts.
cd ../utilities/resizing_cropping/Experiments/scripts

# Crop Dark Zurich to Cityscapes aspect ratio.
./Crop_DarkZurich_train_bottom.sh
./Crop_DarkZurich_test_bottom.sh

# Resize Cityscapes to 360x720 resolution.
./Resize_Cityscapes_trainvaltest_orig_360.sh

# Resize cropped Dark Zurich to 360x720 resolution.
./Resize_DarkZurich_train_cropBottom_360.sh
./Resize_DarkZurich_test_cropBottom_360.sh

# --------------------------------------------------------------------------------
# 2) Train and test CycleGAN on Cityscapes -> Dark Zurich with full 360x720 crops.
# --------------------------------------------------------------------------------

# Change directory to that containing the CycleGAN train and test scripts.
cd ../../../../Style_transfer/Experiments/CycleGAN/Cityscapes/scripts

# Train CycleGAN on Cityscapes -> Dark Zurich-twilight and test on Cityscapes to stylize it as twilight.
./trainval_resize_360_CycleGAN_DarkZurichTwilight_resize_360-train_crop_none-test_Cityscapes_trainval_resize_360.sh

# Upsample the stylized Cityscapes images to original 1024x2048 resolution.
./trainval_resize_360_CycleGAN_DarkZurichTwilight_resize_360-jbu.sh

# Train CycleGAN on Cityscapes -> Dark Zurich-night and test on Cityscapes to stylize it as night.
./trainval_resize_360_CycleGAN_DarkZurichNight_resize_360-train_crop_none-test_Cityscapes_trainval_resize_360.sh

# Upsample the stylized Cityscapes images to original 1024x2048 resolution.
./trainval_resize_360_CycleGAN_DarkZurichNight_resize_360-jbu.sh

# ------------------------------------------------------------------------------------------------
# 3) First adaptation step for MGCDA: train RefineNet on synthetic twilight and real daytime data.
# ------------------------------------------------------------------------------------------------

# Change directory to that containing the test script for Cityscapes-pretrained RefineNet.
cd ../../../../../Semantic_segmentation/Experiments/RefineNet/Cityscapes/scripts

# Test Cityscapes-pretrained RefineNet on Dark Zurich-day to generate pseudolabels.
./original-test_DarkZurichDay.sh

# Change directory to that containing the train script for MGCDA.
cd ../../Union_Cityscapes_Dark_Zurich/scripts

# Train RefineNet on synthetic twilight Cityscapes and real daytime Dark Zurich-day.
./Cityscapes_trainval_dark_CycleGANfc_DarkZurichTwilight-DarkZurich_day_labels_refinenet-w_1-train_gradual.sh

# ---------------------------------------------------------------------------------------
# 4) Geometrically guided segmentation refinement for the labels of Dark Zurich-twilight.
# ---------------------------------------------------------------------------------------

# Test model adapted to twilight on Dark Zurich-twilight to generate initial pseudolabels.
./Cityscapes_trainval_dark_CycleGANfc_DarkZurichTwilight-DarkZurich_day_labels_refinenet-w_1-test_DarkZurich_twilight.sh

# Change directory to that containing the script for geometrically guided segmentation refinement.
cd ../../../Guided_refinement/Dark_Zurich/scripts

# Refine the labels of Dark Zurich-twilight.
./twilight_refinenet_synreal_CycleGANfc_warpDepthAlternBilateral_confProportionDyn_day_gps_refinenet.sh

# ---------------------------------------------------------------------------------------------------
# 5) Second adaptation step for MGCDA: train RefineNet on synthetic nighttime and real twilight data.
# ---------------------------------------------------------------------------------------------------

# Change directory to that containing the train script for MGCDA.
cd ../../../RefineNet/Union_Cityscapes_Dark_Zurich/scripts

# Train RefineNet on synthetic nighttime Cityscapes and real twilight Dark Zurich-twilight.
./DarkCityscapes_DarkZurichNight_CycleGANfc-DarkZurich_twilight_labels_refinenet_init_geoRefDynDay-w_1-train_gradual_init_DarkCityscapes_DarkZurichTwilight_CycleGANfc_DarkZurich_day_labels_refinenet_w_1.sh

# -------------------------------------------------------------------------------------------------------------------------------------
# 6) Evaluation of MGCDA on six evaluation sets: Dark Zurich-{test, val} and anonymized versions, Nighttime Driving, and BDD100K-night.
# -------------------------------------------------------------------------------------------------------------------------------------

# Predict with MGCDA and evaluate results on the evaluation sets using the standard mean IoU metric.
./DarkCityscapes_DarkZurichNight_CycleGANfc-DarkZurich_twilight_labels_refinenet_init_geoRefDynDay-w_1-testEval_DarkZurich_test_testAnon_val_valAnon_NighttimeDriving_BDD100Knight.sh

