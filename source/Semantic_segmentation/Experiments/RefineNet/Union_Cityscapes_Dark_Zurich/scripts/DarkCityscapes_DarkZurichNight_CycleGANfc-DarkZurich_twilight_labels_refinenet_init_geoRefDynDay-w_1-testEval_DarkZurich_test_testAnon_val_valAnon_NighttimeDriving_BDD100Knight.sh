# Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
# Experiment parameters.
synthetic_configurations="trainval_dark_CycleGANfc_DarkZurichNight"
real_configurations="twilight_refinenet_DarkCityscapes_DarkZurichTwilight_CycleGANfc_DarkZurich_day_labels_original_w_1_geoRefDynDay"
initialization_configurations="DarkCityscapes_DarkZurichTwilight_CycleGANfc_DarkZurich_day_labels_original_w_1"
relative_weight_synthetic="1"
training_epochs="10"

# Test datasets.
imdb_test_1="Dark_Zurich_test"
imdb_test_2="Dark_Zurich_test_anon"
imdb_test_3="Dark_Zurich_val"
imdb_test_4="Dark_Zurich_val_anon"
imdb_test_5="Nighttime_Driving"
imdb_test_6="BDD100K_night_trainval_correct"

# Testing+evaluation scripts.
./testEval_mixed.sh ${synthetic_configurations} ${real_configurations} ${initialization_configurations} ${relative_weight_synthetic} ${training_epochs} ${imdb_test_1}
./testEval_mixed.sh ${synthetic_configurations} ${real_configurations} ${initialization_configurations} ${relative_weight_synthetic} ${training_epochs} ${imdb_test_2}
./testEval_mixed.sh ${synthetic_configurations} ${real_configurations} ${initialization_configurations} ${relative_weight_synthetic} ${training_epochs} ${imdb_test_3}
./testEval_mixed.sh ${synthetic_configurations} ${real_configurations} ${initialization_configurations} ${relative_weight_synthetic} ${training_epochs} ${imdb_test_4}
./testEval_mixed.sh ${synthetic_configurations} ${real_configurations} ${initialization_configurations} ${relative_weight_synthetic} ${training_epochs} ${imdb_test_5}
./testEval_mixed.sh ${synthetic_configurations} ${real_configurations} ${initialization_configurations} ${relative_weight_synthetic} ${training_epochs} ${imdb_test_6}




