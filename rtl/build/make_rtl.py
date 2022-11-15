#!/usr/bin/env python3

import os
import sys
import lzma
import pickle
import argparse
from textwrap import dedent
from render_template import render_template_file
from numpy import flip, log2

build_dirname = os.path.dirname(__file__)
sv_dirname = os.path.join(build_dirname, "../sv_srcs")
os.makedirs(sv_dirname, exist_ok=True)
sys.path.append(os.path.join(build_dirname, "../../software_model"))

parser = argparse.ArgumentParser()
parser.add_argument("filenames", nargs="+", help="List of templated .sv.mako files to convert")
parser.add_argument("--model", required=True, help="Pointer to the model .pickle.lzma file")
parser.add_argument("--hash_units", type=int, default=-1, help="If specified, set the number of hash units per discriminator; defaults to one per filter")
parser.add_argument("--bus_width", type=int, default=512, help="Width of the input data bus")
args = parser.parse_args()

with lzma.open(args.model, "rb") as f:
  state_dict = pickle.load(f)
model_info = state_dict["info"]
model = state_dict["model"]

# Generate global_parameters.py/.svh
global_parameters = {\
    "num_inputs": model_info["num_inputs"],\
    "num_classes": model_info["num_classes"],\
    "inputs_per_filter": model_info["num_filter_inputs"],\
    "filter_entries": model_info["num_filter_entries"],\
    "hash_functions_per_filter": model_info["num_filter_hashes"],\
    "bits_per_input": model_info["bits_per_input"]\
}

global_parameters["input_bits"] = global_parameters["num_inputs"] * global_parameters["bits_per_input"]
global_parameters["filters_per_discriminator"] = global_parameters["input_bits"] // global_parameters["inputs_per_filter"]

if args.hash_units > 0:
    global_parameters["hashers_per_discriminator"] = args.hash_units
else:
    global_parameters["hashers_per_discriminator"] = global_parameters["filters_per_discriminator"]

global_parameters["input_bus_width"] = args.bus_width

header_text_py = dedent("""\
    ################################################################################
    ## THIS FILE WAS AUTOMATICALLY GENERATED BY make_rtl.py
    ## DO NOT EDIT
    ################################################################################

""")
global_parameter_string_py = "\n".join([f"{k} = {v}" for k, v in global_parameters.items()])
global_parameter_string_py = header_text_py + global_parameter_string_py
global_parameter_fname_py = os.path.join(build_dirname, "global_parameters.py")
with open(global_parameter_fname_py, "w") as f:
    f.write(global_parameter_string_py)

header_text_svh = header_text_py.replace("#", "/")
global_parameter_string_svh = "\n".join([f"`define {k.upper()} {v}" for k, v in global_parameters.items()])
global_parameter_string_svh = header_text_svh + global_parameter_string_svh
global_parameter_fname_svh = os.path.join(sv_dirname, "global_parameters.svh")
with open(global_parameter_fname_svh, "w") as f:
    f.write(global_parameter_string_svh)


# Generate SV header file
os.makedirs(sv_dirname, exist_ok=True)
parameter_header_fname = os.path.join(sv_dirname, "model_parameters.svh")

#filter_parameter_string = "'{\\\n"
filter_parameter_string = f"{len(model.discriminators)*len(model.discriminators[0].filters)*len(model.discriminators[0].filters[0].data)}'b"
for discriminator_idx, discriminator in reversed(list(enumerate(model.discriminators))):
    #filter_parameter_string += "  '{\\\n"
    for filter_idx, filter_object in reversed(list(enumerate(discriminator.filters))):
        filter_parameter_string += "".join(str(x) for x in flip(filter_object.data))
        #filter_parameter_string += "    '{" + ",".join(str(x) for x in flip(filter_object.data)) + "}"
        #if filter_idx > 0:
        #    filter_parameter_string += ","
        #filter_parameter_string += "\\\n"
    #filter_parameter_string += "  }"
    #if discriminator_idx > 0:
    #    filter_parameter_string += ","
    #filter_parameter_string += "\\\n"
#filter_parameter_string += "}\n"

hash_parameter_size = int(log2(model_info["num_filter_entries"]))
#hash_parameter_string = "'{\\\n"
hash_parameter_string = f"{model_info['hash_values'].size*hash_parameter_size}'b"
for hash_idx, hash_params in reversed(list(enumerate(model_info["hash_values"]))):
    #hash_parameter_string += "  '{" + ",".join(str(x) for x in flip(hash_params)) + "}"
    for p in flip(hash_params):
        hash_parameter_string += bin(p)[2:].zfill(hash_parameter_size)
    #if hash_idx > 0:
    #    hash_parameter_string += ","
    #hash_parameter_string += "\\\n"
#hash_parameter_string += "}\n"

sv_header_string = header_text_svh
sv_header_string += "`define MODEL_PARAM_FILTER_DATA " + filter_parameter_string + "\n\n"
sv_header_string += "`define MODEL_PARAM_HASH_PARAMS " + hash_parameter_string + "\n\n"

with open(parameter_header_fname, "w") as f:
    f.write(sv_header_string)

# Render all template files
for in_fname in args.filenames:
    dirname, basename = os.path.split(in_fname)
    out_dirname = os.path.join(dirname, "../sv_srcs")
    out_fname = os.path.join(out_dirname, basename.rstrip(".mako"))
    render_template_file(in_fname, out_fname)

