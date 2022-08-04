# BTHOWeN
Code to accompany the paper:

**Weightless Neural Networks for Efficient Edge Inference**, Zachary Susskind, Aman Arora, Igor Dantas Dos Santos Miranda, Luis Armando Quintanilla Villon, Rafael Fontella Katopodis, Leandro Santiago de Araújo, Diego Leonel Cadette Dutra, Priscila Lima, Felipe Maia Galvão França, Mauricio Breternitz Jr., Lizy John

*To be presented at the 31st International Conference on Parallel Architectures and Compilation Techniques (PACT 2022)*

# Usage
## Prerequisites

Our codebase was written for Python 3.8.10; other version may very well work but are untested.

We recommend constructing a virtual environment for dependency management:
```
python3 -m venv env
source env/bin/activate
```

From here, dependency installation can be automatically handled with a single command:
```
pip install -r requirements.txt
```

If you'd like to synthesize generated RTL using our Make flow, you'll need a VCS installation and of course a valid license. Point the `VCS_HOME` environment variable to your top-level VCS installation directory (the executable path should be `$(VCS_HOME)/bin/vcs`).

## Creating BTHOWeN Models
All relevant code lives in the `software_model/` directory. Natively supported datasets are MNIST, Ecoli, Iris, Letter, Satimage, Shuttle, Vehicle, Vowel, and Wine.

`train_swept_models.py` is the primary script for programmatic model sweeping. It allows for specification of Bloom filter and encoding parameters; run with `--help` for more details.

`evaluate.py` runs inference on a pre-trained model - invocation takes the form `./evaluate.py <model_fname> <dset_name>`.

`calc_model_size.py` is a small script which gives the total Bloom filter size (in KiB; 1 KiB = 1024B) of the specified pre-trained model.

`convert_dset.py` is the script we used to binarize the MNIST dataset as an input to our RTL testbenches for checking correctness. You're unlikely to need this one, but we provide it for completeness.

## Producing RTL for Pre-Trained BTHOWeN Models
All relevant code lives in the `rtl/` directory.

We provide a Makefile for generating the RTL. Invoking `make` with no arguments will generate RTL for a sample model (our small MNIST model), and then attempt to build the RTL and testbenches. To generate the RTL without building it, run `make template`.  
The Makefile also allows for the model file, number of hash units in the accelerator, and data bus width to be specified as optional command-line arguments. So for instance, you could run:
```
make template MODEL=../software_model/selected_models/letter.pickle.lzma HASH_UNITS=2 BUS_WIDTH=32
```
If `HASH_UNITS` is left as the default (-1), the script will choose the smallest number of hash units possible without causing the device to be memory-bound. This is a function of the exact model architecture and the bus width.

SystemVerilog sources are generated using the [Mako templating library](https://www.makotemplates.org/) from the `.sv.mako` sources under `rtl/mako_srcs/`, and written under `rtl/sv_srcs/`.

