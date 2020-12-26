# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Experiment parameters.
synthetic_configurations="trainval_dark_CycleGANfc_DarkZurichNight"
real_configurations="twilight_refinenet_DarkCityscapes_DarkZurichTwilight_CycleGANfc_DarkZurich_day_labels_original_w_1_geoRefDynDay"
initialization_configurations="DarkCityscapes_DarkZurichTwilight_CycleGANfc_DarkZurich_day_labels_original_w_1"
relative_weight_synthetic="1"
training_epochs="10"

# Test dataset.
imdb_test="Dark_Zurich_test_anon"

# Testing script.
./test_mixed.sh ${synthetic_configurations} ${real_configurations} ${initialization_configurations} ${relative_weight_synthetic} ${training_epochs} ${imdb_test}




