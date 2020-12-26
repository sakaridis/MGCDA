import os.path
import random
from data.base_dataset import BaseDataset, get_params, get_transform
import torchvision.transforms as transforms
from data.image_folder import make_dataset
from PIL import Image


class UnalignedGuidedTargetDataset(BaseDataset):
    """A dataset class for unaligned image dataset with source counterparts of target images.

    It requires two directories to host training images from domain A '/path/to/data/trainA'
    and from domains B and C '/path/to/data/trainBC', which contains aligned pairs as tiled images {C, B}.
    You can train the model with the dataset flag '--dataroot /path/to/data'.
    For testing, you need to prepare two directories:
    '/path/to/data/testA' similarly to training and '/path/to/data/testB' which contains images from domain B.
    """

    def __init__(self, opt):
        """Initialize this dataset class.

        Parameters:
            opt (Option class) -- stores all the experiment flags; needs to be a subclass of BaseOptions
        """
        BaseDataset.__init__(self, opt)
        self.dir_A = os.path.join(opt.dataroot, opt.phase + 'A')  # create a path to '/path/to/data/trainA'
        self.dir_BC = os.path.join(opt.dataroot, opt.phase + 'BC')  # create a path to '/path/to/data/trainBC'

        self.A_paths = sorted(make_dataset(self.dir_A, opt.max_dataset_size))  # get image paths
        self.BC_paths = sorted(make_dataset(self.dir_BC, opt.max_dataset_size))  # get image paths
        self.A_size = len(self.A_paths)
        self.BC_size = len(self.BC_paths)
        assert(self.opt.load_size >= self.opt.crop_size)   # crop_size should be smaller than the size of loaded image
        self.input_nc = self.opt.output_nc if self.opt.direction == 'BtoA' else self.opt.input_nc
        self.output_nc = self.opt.input_nc if self.opt.direction == 'BtoA' else self.opt.output_nc

    def __getitem__(self, index):
        """Return a data point and its metadata information.

        Parameters:
            index - - a random integer for data indexing

        Returns a dictionary that contains A, B, A_paths and B_paths
            A (tensor) - - an image in the input domain
            B (tensor) - - its corresponding image in the target domain
            A_paths (str) - - image paths
            B_paths (str) - - image paths (same as A_paths)
        """

        # Read one image from each set given a random integer index.
        A_path = self.A_paths[index % self.A_size]
        if self.opt.serial_batches:
            index_BC = index % self.BC_size
        else:  # Randomize the index for the second set to avoid fixed pairs (A, (B,C)).
            index_BC = random.randint(0, self.BC_size - 1)
        BC_path = self.BC_paths[index_BC]
        A_img = Image.open(A_path).convert('RGB')
        # Split {B,C} image into B and C.
        BC_img = Image.open(BC_path).convert('RGB')
        w, h = BC_img.size
        w2 = int(w / 2)
        B_img = BC_img.crop((0, 0, w2, h))
        C_img = BC_img.crop((w2, 0, w, h))

        # Apply image transformations, using the same transform both for B and C.
        A_transform = get_transform(self.opt, grayscale=(self.input_nc == 1))
        transform_params_BC = get_params(self.opt, B_img.size)
        B_transform = get_transform(self.opt, transform_params_BC, grayscale=(self.output_nc == 1))
        C_transform = get_transform(self.opt, transform_params_BC, grayscale=(self.output_nc == 1))

        A = A_transform(A_img)
        B = B_transform(B_img)
        C = C_transform(C_img)

        return {'A': A, 'B': B, 'C': C, 'A_paths': A_path, 'BC_paths': BC_path}

    def __len__(self):
        """Return the total number of images in the dataset.

        As we have two datasets with potentially different number of images,
        we take a maximum of the size of the individual datasets.
        """
        return max(self.A_size, self.BC_size)
