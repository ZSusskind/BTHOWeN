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

