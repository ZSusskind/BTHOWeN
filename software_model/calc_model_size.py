#!/usr/bin/env python3

import sys
import lzma
import pickle
from math import ceil

with lzma.open(sys.argv[1], "rb") as f:
    state_dict = pickle.load(f)

info = state_dict["info"]

filters_per_discriminator = ceil((info["num_inputs"] * info["bits_per_input"]) / info["num_filter_inputs"])
bits_per_discriminator = filters_per_discriminator * info["num_filter_entries"]
bits_in_model = bits_per_discriminator * info["num_classes"]
kib_in_model = bits_in_model / 8192
print(f"Size: {kib_in_model} KiB")

