#!/usr/bin/env python3
# This script is used to produce .mem input files for the RTL testbenches
# It's not designed for datasets other than MNIST since we use that dataset
#  to validate the correctness of our model, but got power numbers using
#  Vivado using a data-independent flow
# Hic sunt dracones

import os
import re
import sys
import pickle
import lzma
import numpy as np

import torchvision.datasets as dsets
import torchvision.transforms as transforms

from main import binarize_datasets, run_inference

def convert_dataset(train_dataset, target_dataset, model_fname, out_basename):
    with lzma.open(model_fname, "rb") as f:
        state_dict = pickle.load(f)
    
    bits_per_input = state_dict["info"]["bits_per_input"]
    target_inputs, target_labels = binarize_datasets(train_dataset, target_dataset, bits_per_input)[-2:]

    run_inference(target_inputs, target_labels, state_dict["model"])

    reshaped_target_inputs = np.flip(target_inputs[:,state_dict["model"].input_order], axis=1)
    target_input_data = np.packbits(reshaped_target_inputs.flatten()).tobytes()
    target_label_data = target_labels.astype(np.uint8).tobytes()

    model_basename = out_basename + "_" + re.sub(r"\.pickle\.lzma", "", os.path.basename(model_fname))
    input_fname = model_basename + "_inputs.mem"
    label_fname = model_basename + "_labels.mem"
    with open(input_fname, "wb") as f:
        f.write(target_input_data)
    with open(label_fname, "wb") as f:
        f.write(target_label_data)

if __name__ == "__main__":
    model_fname = sys.argv[1]
    out_basename = sys.argv[2]
    train_dataset = dsets.MNIST(root ='./data',
            train = True,
            transform = transforms.ToTensor(),
            download = True)
    target_dataset = dsets.MNIST(root ='./data',
        train = False,
        transform = transforms.ToTensor())
    convert_dataset(train_dataset, target_dataset, model_fname, out_basename)
