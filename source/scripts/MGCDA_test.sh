# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)

# MGCDA test script. Assumption: pwd is the directory of this script.


# --------------------------------------------------------------------------------------------------------------
# Generate predictions with MGCDA pre-trained model for the nighttime set Dark Zurich-test (anonymized version).
# --------------------------------------------------------------------------------------------------------------

# Change directory to that containing the test script for MGCDA.
cd ../Semantic_segmentation/Experiments/RefineNet/Union_Cityscapes_Dark_Zurich/scripts

# Generate predictions with MGCDA pre-trained model.
./DarkCityscapes_DarkZurichNight_CycleGANfc-DarkZurich_twilight_labels_refinenet_init_geoRefDynDay-w_1-test_DarkZurich_testAnon.sh

