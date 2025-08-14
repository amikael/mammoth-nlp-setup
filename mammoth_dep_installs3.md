# Verifying the Torch Provided by the Environment

This document shows how `torch_env_check.py` and `torch_env_check2.py` from the **RCCL-tests** repository helped us to debug our virtual environment.  The script `init3.10-with-conda.sh` was an older version of `init3.10-with-site.sh`.  The latter is now provided in this repository.

## Container provides a correct version of PyTorch

If I just run the container and do $WITH_CONDA, the pytorch test will work as follows:
```bash
(local) $ ssh lumi.csc.fi
(lumi)  $ cd $PROJHOME/conf
(lumi)  $ source init3.10-with-conda.sh  # run the module commands and set SIF
(lumi)  $ singularity exec $SIF bash
Singularity> $WITH_CONDA
(pytorch) Singularity> python torch_env_check.py
Detected platform: LUMI
=== PyTorch Environment Check ===
PyTorch version: 2.3.0+rocm6.2.0
ROCm HIP version: 6.2.41133-dd7f95766
CUDA available: False
CUDA device count: 0
=== Validation ===
✅ LUMI: ROCm detected, CUDA not available — OK.
python torch_env_check.py
```

## This Changes After Loading Venv

In the following, I Have activated the virtual environment after starting the container.

```bash
(pytorch) Singularity> source $PROJHOME/venv/mammoth3.10-with-conda/bin/activate
(mammoth3.10-with-conda) (pytorch) Singularity> python torch_env_check.py
Detected platform: LUMI
=== PyTorch Environment Check ===
PyTorch version: 2.7.1+cu126
ROCm HIP version: None
CUDA available: False
CUDA device count: 0
=== Validation ===
✅ LUMI: ROCm detected, CUDA not available — OK.
```
As you can see, now the ROCm HIP version and PyTorch were different and they did not match with what is promised by the name of the container: `lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif`.  Note that `python --version`
returns the same in the same case: Python 3.10.14.  This because the virtual environment was incorrectly set up on a login node.

## Re-Verifying the Torch Problem with Another Tool

### Testing PyTorch of the container

First we test pytorch/ROCm versions after applying container and $WITH_CONDA.
```bash
srun --account="$ACCOUNT" --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=2:00:00 --mem=25G --pty bash
source init3.10-with-conda.sh  # run the module commands and set SIF
singularity exec $SIF bash
$WITH_CONDA
python torch_env_check2.py

=== Torch ROCm/CUDA Diagnostic Script ===
Detected platform: LUMI
=== PyTorch Environment Check ===
PyTorch version          : 2.3.0+rocm6.2.0
ROCm HIP version          : 6.2.41133-dd7f95766
torch.version.cuda        : None
torch.cuda.is_available() : True
torch.cuda.device_count() : 1
Device 0: AMD Instinct MI250X
=== Validation ===
✅ LUMI: ROCm detected, no CUDA version reported — environment is OK.
```

### Testing PyTorch of the virtual environment

The above seems perfect.  Now we will test whether the virtual environment build after applying $WITH_CONDA is using the right pytorch version.
```bash
srun --account="$ACCOUNT" --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=2:00:00 --mem=25G --pty bash
source init3.10-with-conda.sh  # run the module commands and set SIF
singularity exec $SIF bash
$WITH_CONDA
python torch_env_check2.py
source $PROJHOME/venv/mammoth3.10-with-conda/bin/activate
python torch_env_check2.py

=== Torch ROCm/CUDA Diagnostic Script ===
Detected platform: LUMI
=== PyTorch Environment Check ===
PyTorch version          : 2.7.1+cu126
ROCm HIP version          : None
torch.version.cuda        : 12.6
torch.cuda.is_available() : False
torch.cuda.device_count() : 0
=== Validation ===
❌ LUMI: Unexpected CUDA version or missing ROCm — check your PyTorch installation.
```
The explanation is that **some package has required `torch` and pip has installed the 2.7.1+cu126 version from PyPI.**  We did not (necessarily) notice this. 


### Testing PyTorch after a correctly built virtual environment

To avoid this, the recipe 6 (above) is to be used.  When the recipe 6 was applied, the produced new venv required much fewer installations as some packages were preinstalled.
```bash
Successfully built mammoth-nlp
Installing collected packages: sentencepiece, tqdm, scikit-learn, mammoth-nlp
  Attempting uninstall: sentencepiece
    Found existing installation: sentencepiece 0.2.0
    Not uninstalling sentencepiece at /opt/miniconda3/envs/pytorch/lib/python3.10/site-packages, outside environment /project/project_462000964/members/aylijyra/venv/mammoth3.10-with-site
    Cannot uninstall ``sentencepiece`. No files were found to uninstall.
  Attempting uninstall: tqdm
    Found existing installation: tqdm 4.67.1
    Uninstalling tqdm-4.67.1:
      Successfully uninstalled tqdm-4.67.1
  Attempting uninstall: scikit-learn
    Found existing installation: scikit-learn 1.3.1
    Uninstalling scikit-learn-1.3.1:
      Successfully uninstalled scikit-learn-1.3.1
Successfully installed mammoth-nlp-0.2.1 scikit-learn-1.2.0 sentencepiece-0.1.97 tqdm-4.66.2
```
The run of recipe 6 for installation ended with a successful installation of MAMMOTH:
```bash
(while on a GPU computation node):
$  singularity exec $SIF bash
Singularity>  source $PROJHOME/venv/mammoth3.10-with-site/bin/activate
(mammoth3.10-with-site) Singularity>  python torch_env_check2.py

=== Torch ROCm/CUDA Diagnostic Script ===
Detected platform: LUMI
=== PyTorch Environment Check ===
PyTorch version          : 2.3.0+rocm6.2.0
ROCm HIP version          : 6.2.41133-dd7f95766
torch.version.cuda        : None
torch.cuda.is_available() : True
torch.cuda.device_count() : 1
Device 0: AMD Instinct MI250X
=== Validation ===
✅ LUMI: ROCm detected, no CUDA version reported — environment is OK.
```
Now the virtual environment includes the CSC-validated pytorch and rocm.
