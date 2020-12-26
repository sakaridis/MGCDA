# MGCDA: Map-Guided Curriculum Domain Adaptation

Created by Christos Sakaridis at Computer Vision Lab, ETH Zurich.

<img source="images/MGCDA_overview.png" align="center" width=100%>
<br/><br/>


### Overview

This is the source code for the MGCDA method for semantic segmentation at nighttime.

MGCDA is presented in our IEEE TPAMI 2020 paper [**Map-Guided Curriculum Domain Adaptation and Uncertainty-Aware Evaluation for Semantic Nighttime Image Segmentation**][arxiv] and its original version GCMA was introduced in our [ICCV 2019 paper][iccv_19].

For the source code for the uncertainty-aware semantic segmentation evaluation with the UIoU metric, you can consult the [UIoU Dark Zurich Challenge page][uiou_challenge].


### License

This software is made available for non-commercial use under a creative commons [license](LICENSE.txt). You can find a summary of the license [here][cc_license]. For a commercial license please contact the authors.


### Contents

1. [Requirements](#requirements)
2. [Demo](#demo)
3. [Testing](#testing-mgcda)
4. [Training](#training-mgcda)
5. [Acknowledgments](#acknowledgments)
6. [Citation](#citation)


### Requirements

For running the demo, you only need MATLAB 2016b or later.

For testing, you need:

1.  Linux
2.  NVIDIA GPU with CUDA & CuDNN
3.  MATLAB: version 2016b

For training, you need:

1. Linux
2. NVIDIA GPU with CUDA & CuDNN
3. MATLAB: version 2016b
4. Python 3


### Demo

Run the [demo MATLAB script](source/Semantic_segmentation/Guided_refinement/Demo_geometrically_guided_segmentation_refinement.m).

This applies the geometrically guided segmentation refinement involved in MGCDA on a pair of corresponding images, i.e. a dark image and a daytime image which depict the same scene from a different viewpoint.

The results of the guided refinement, i.e. the refined segmentation of the dark image and the daytime segmentation aligned to the viewpoint of the dark image, are written in the directory `output/demo/`.


### Testing MGCDA

- Download the [pre-trained MGCDA model][mgcda_model] and put it in the directory `output/RefineNet/Union_Cityscapes_Dark_Zurich/`.
- Download the [ResNet-101 backbone model][resnet101_backbone] and put it in the directory `source/Semantic_segmentation/refinenet/model_trained/`.
- Compile the MatConvNet provided in directory `source/Semantic_segmentation/refinenet/libs/matconvnet/` to point to your CUDA and CuDNN installation. Detailed instructions for this step can be found [here](source/Semantic_segmentation/refinenet/main/my_matconvnet_resnet/README.md).
- Customize the file `source/Semantic_segmentation/refinenet/main/setpath.sh` so that the environment variables `PATH` and `LD_LIBRARY_PATH` point to your installation directories for CUDA and CuDNN.
- Download the [Dark Zurich][dark_zurich_test] dataset (test set - anonymized version) and unzip it in the directory `data/Dark_Zurich/`. Testing is performed on this set.
- The shell script that tests the pre-trained MGCDA model is `source/scripts/MGCDA_test.sh`. You first need to make this script executable. In the command line, navigate to the directory that contains this repository and run:\
  `find -type f -name '*\.sh' -exec chmod u+x {} \;`
- **Test MGCDA on Dark Zurich-test**:
  ```
  cd source/scripts
  ./MGCDA_test.sh
  ```
  The generated prediction files are written under the directory `output/RefineNet/Dark_Zurich_test_anon/` and include four different prediction formats (Ids, trainIds, color, raw soft predictions) to facilitate further usage.

You can also test MGCDA on other sets, such as Nighttime Driving, BDD100K-night (a selected nighttime subset of the segmentation set of BDD100K), and the validation set of Dark Zurich, simply by:
1. downloading the respective set, similarly to above
2. changing line 9 of the inner test script `source/Semantic_segmentation/Experiments/Union_Cityscapes_Dark_Zurich/scripts/DarkCityscapes_DarkZurichNight_CycleGANfc-DarkZurich_twilight_labels_refinenet_init_geoRefDynDay-w_1-test_DarkZurich_testAnon.sh` to the name of the respective set, e.g. to `Nighttime_Driving`. Consult the [MATLAB testing function](source/Semantic_segmentation/refinenet/main/test_RefineNet.m) for a list of supported test sets.

To test MGCDA on your own custom set, you need to:
1. implement a MATLAB function for your set similar to the function `source/Semantic_segmentation/refinenet/main/my_gen_ds_info_Dark_Zurich_test_anon.m` that corresponds to Dark Zurich-test
2. augment the [MATLAB testing function](source/Semantic_segmentation/refinenet/main/test_RefineNet.m) with a handle to the above function.


### Training MGCDA

- Download the pre-trained [RefineNet-res101-Cityscapes][refinenet_model] model and put it in the directory `output/RefineNet/Cityscapes/`.
- Download the [ResNet-101 backbone model][resnet101_backbone] and put it in the directory `source/Semantic_segmentation/refinenet/model_trained/`.
- Compile the MatConvNet provided in directory `source/Semantic_segmentation/refinenet/libs/matconvnet/` to point to your CUDA and CuDNN installation. Detailed instructions for this step can be found [here](source/Semantic_segmentation/refinenet/main/my_matconvnet_resnet/README.md).
- Customize the file `source/Semantic_segmentation/refinenet/main/setpath.sh` so that the environment variables `PATH` and `LD_LIBRARY_PATH` point to your installation directories for CUDA and CuDNN.
- Configure the CycleGAN Python implementation. The recommended way is via conda. Install a new conda environment using the provided YAML file:
  ```
  cd source/Style_transfer/pytorch-CycleGAN-and-pix2pix
  conda env create -f environment.yml
  ```
- Download the [Dark Zurich][dark_zurich_train] dataset (training set - anonymized version) and unzip it in the directory `data/Dark_Zurich/`.
- Download the [Cityscapes][cityscapes_downloads] dataset and unzip it in the directory `data/Cityscapes/`. You need the packages `leftImg8bit_trainvaltest.zip` and `gtFine_trainvaltest.zip`.
- Download the precomputed [depth map predictions][monodepth2_predictions] of Monodepth2 on Dark Zurich-day and unzip them in the directory `output/Depth_estimation/`.
- Download the precomputed [SURFs][surfs] for Dark Zurich and unzip them in the directory `output/Feature_extraction_and_matching/`.
- The shell script that runs the full training pipeline of MGCDA is `source/scripts/MGCDA_train.sh`. Make this script executable.
- **Train MGCDA on Cityscapes and Dark Zurich**:
  ```
  cd source/scripts
  ./MGCDA_train.sh
  ```
  The trained MGCDA model is stored in the directory `output/RefineNet/Union_Cityscapes_Dark_Zurich/` with the name `refinenet_res101_cityscapes_DarkCityscapes_DarkZurichTwilight_CycleGANfc_DarkZurichNight_CycleGANfc_DarkZurich_day_labels_original_w_1_twilight_labels_adaptedPrevGeoRefDyn_w_1_epoch_10.mat`.


### Acknowledgments

Our implementation includes adapted versions of two external repositories:
- RefineNet: <https://github.com/guosheng/refinenet> The associated license is [here](source/Semantic_segmentation/refinenet/LICENSE).
- CycleGAN: <https://github.com/junyanz/pytorch-CycleGAN-and-pix2pix> The associated license is [here](source/Style_transfer/pytorch-CycleGAN-and-pix2pix/LICENSE).


### Citation

If you use our code in your work, please cite our publications as
```
@article{SDV20,
  author = {Sakaridis, Christos and Dai, Dengxin and Van Gool, Luc},
  title = {Map-Guided Curriculum Domain Adaptation and Uncertainty-Aware Evaluation for Semantic Nighttime Image Segmentation}, 
  journal = {IEEE Transactions on Pattern Analysis and Machine Intelligence}, 
  year = {2020},
  doi = {10.1109/TPAMI.2020.3045882}
}
```
and
```
@inproceedings{SDV19,
  author = {Sakaridis, Christos and Dai, Dengxin and Van Gool, Luc},
  title = {Guided Curriculum Model Adaptation and Uncertainty-Aware Evaluation for Semantic Nighttime Image Segmentation},
  booktitle = {The IEEE International Conference on Computer Vision (ICCV)},
  year = {2019}
}
```


### Contact

Christos Sakaridis  
csakarid[at]vision.ee.ethz.ch  
https://www.trace.ethz.ch/publications/2019/GCMA_UIoU

[arxiv]: <https://arxiv.org/pdf/2005.14553.pdf>
[iccv_19]: <https://openaccess.thecvf.com/content_ICCV_2019/papers/Sakaridis_Guided_Curriculum_Model_Adaptation_and_Uncertainty-Aware_Evaluation_for_Semantic_Nighttime_ICCV_2019_paper.pdf>
[uiou_challenge]: <https://competitions.codalab.org/competitions/23553>
[mgcda_model]: <https://data.vision.ee.ethz.ch/csakarid/shared/MGCDA_UIoU/refinenet_res101_cityscapes_DarkCityscapes_DarkZurichv3twilight_CycleGANfc_DarkZurichv3night_CycleGANfc_DarkZurich_v3day_labels_original_w_1_v3twilight_labels_adaptedPrevGeoRefDyn_w_1_epoch_10.mat>
[refinenet_model]: <https://data.vision.ee.ethz.ch/csakarid/shared/MGCDA_UIoU/refinenet_res101_cityscapes_original.mat>
[resnet101_backbone]: <https://data.vision.ee.ethz.ch/csakarid/shared/MGCDA_UIoU/imagenet-resnet-101-dag.mat>
[dark_zurich_test]: <https://data.vision.ee.ethz.ch/csakarid/shared/GCMA_UIoU/Dark_Zurich_test_anon_withoutGt.zip>
[dark_zurich_train]: <https://data.vision.ee.ethz.ch/csakarid/shared/GCMA_UIoU/Dark_Zurich_train_anon.zip>
[monodepth2_predictions]: <https://data.vision.ee.ethz.ch/csakarid/shared/MGCDA_UIoU/monodepth2_Dark_Zurich_day.zip>
[surfs]: <https://data.vision.ee.ethz.ch/csakarid/shared/MGCDA_UIoU/SURF_Dark_Zurich_train.zip>
[project_page]: <https://www.trace.ethz.ch/publications/2019/GCMA_UIoU>
[cc_license]: <http://creativecommons.org/licenses/by-nc/4.0/>
[cityscapes_downloads]: <https://www.cityscapes-dataset.com/downloads/>
