#!/usr/bin/env python3

import sys
import pickle
import lzma
import argparse
import numpy as np
from train_swept_models import get_datasets, binarize_datasets, run_inference

def eval_model(model_fname, dset_name):
    print("Loading model")
    with lzma.open(model_fname, "rb") as f:
        state_dict = pickle.load(f)
    if not hasattr(state_dict["model"], "pad_zeros"):
        state_dict["model"].pad_zeros = 0

    print("Loading dataset")
    train_dataset, test_dataset = get_datasets(dset_name)

    print("Running inference")
    bits_per_input = state_dict["info"]["bits_per_input"]
    test_inputs, test_labels = binarize_datasets(train_dataset, test_dataset, bits_per_input)[-2:]
    result = run_inference(test_inputs, test_labels, state_dict["model"], 1)

def read_arguments():
    parser = argparse.ArgumentParser(description="Run inference on a pre-trained BTHOWeN model")
    parser.add_argument("model_fname", help="Path to pretrained model .pickle.lzma")
    parser.add_argument("dset_name", help="Name of dataset to use for inference; obviously this must match the model")
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = read_arguments()
    eval_model(args.model_fname, args.dset_name)

