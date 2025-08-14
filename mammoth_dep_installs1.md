## Installing the required Python packages to the virtual environment
### Pro Tips
Always create venvs on GPU nodes if you're using GPU-accelerated Python packages (e.g., torch, jax, tensorflow).
Avoid pip installing torch without specifying the correct ROCm wheel index.  Inside LUMI containers, prefer $WITH_CONDA + provided packages unless you really need a custom venv.

Creating a venv and doing pip install manually can: Accidentally pull NVIDIA/CUDA versions of packages from PyPI.
Cause version mismatches with ROCm libraries. Overwrite or shadow the container’s optimized libraries.
Fail silently and degrade performance or GPU support. Even if your requirements.txt doesn't include torch, it may pull in incompatible transitive dependencies.

- NEVER: `pip install --user` outside container can break thins
- NEVER: `pip install torch` without specifying ROCm Installs CUDA version — doesn't work on LUMI
- EXPERTS: `pip install --pre torch --index-url https://download.pytorch.org/whl/nightly/rocm6.2` to ROCm wheels, for experts
- `$WITH_CONDA` + preinstalled PyTorch + venv -- preferred

Follow these steps to safely use ROCm-compatible PyTorch on LUMI:
1. Start an interactive session with GPU
```bash
srun --account=project_462000964 --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=00:30:00 --pty bash
```
2. Enter the Singularity container
```bash
singularity exec --rocm $PROJHOME/sif/lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif bash
```
3. Step 3: Activate the curated conda environment
```bash
$WITH_CONDA
```
4. (Optional) Create and activate a custom venv inside container
```bash
python3.10 -m venv $PROJHOME/venv/mammoth3.10-with-conda
source $PROJHOME/venv/mammoth3.10-with-conda/bin/activate
```

5. Upgrad the tools
```bash
pip install --upgrade pip setuptools wheel
```

6. (Added after failures:) Check the correct ROCm PyTorch before anything else:
```bash
# pip install torch==2.3.0+rocm6.2.0 --extra-index-url https://download.pytorch.org/whl/rocm
python $PROJHOME/diag/torch_env_check2.py
```
 
### Diagnosis tool
To facilitate the testing of Python package versions, I created a diagnosis tool [mammoth_dep_check_proposed3.11.py](mammoth_dep_check_proposed3.11.py) (located in `$PROJHOME/diag/`; not shown here) that is able to test and compare packages to those required.  This helps to get an overall picture of the status of the pip installations.  

This tool involves an adapted copy of the install_requires from MAMMOTH's `setup.py`.
```python
    install_requires=[
        "configargparse",
        "einops>=0.8.0,<=0.8.1",
        "flake8==4.0.1",
        "flask==2.0.3",
        "pyonmttok>=1.32,<2",
        "pytest-flake8==1.1.1",
        "pytest==7.0.1",
        "pyyaml",
        "sacrebleu==2.3.1",
        "scikit-learn==1.3.1",
        "sentencepiece>=0.1.97,<=0.2.0",
        "tensorboard>=2.9",
        "timeout_decorator",
        "torch>=1.10.2",
        "tqdm>=4.66.2,<4.67.1",
        "waitress",
        "x-transformers==1.32.14",
    ],
```
There are a few changes:
- einops==0.8.0 changed to einops>=0.8.0,<=0.8.1
- scikit-learn==1.2.0 changed to scikit-learn==1.3.1
- sentencepiece==0.1.97 changed to sentencepiece>=0.1.97,<=0.2.0
- tqdm==4.66.2 changed to tqdm>=4.66.2,<=4.67.1

When the original requirement of MAMMOPTH was not available for Python 3.11, I updated the version this requirements to allow a slightly newer version that is also available for Python 3.11.  The same packages seem to be also the best choices for Python 3.10, but I am not completely sure if I tested this thoroughly. Therefore, the name of the tool's name has 3.11 rather than 3.10.  In fact, all the listed packages except `pyonmttok` are also available for 3.12, and when we get an updated `pyonmmttok` the transition to Python 3.12 would be readily available.

I carried out the installation inside the container+virtual environment using the shell script `pip_install3.10-with-conda.sh`:
```bash
#! /usr/bin/bash
# pip_install.sh -- builds a mammoth pip environment

# Download
if [ ! -d  $PROJHOME/rebuilt3.10-with-conda ]; then
    mkdir -p $PROJHOME/rebuilt3.10-with-conda
fi
if [ ! -d  $PROJHOME/rebuilt3.10-with-conda/mammoth ]; then
  cd       $PROJHOME/rebuilt3.10-with-conda
  git clone https://github.com/Helsinki-NLP/mammoth.git
fi
export PYTHONUSERBASE="$PROJHOME/venv/mammoth3.10-with-conda"
export CODE_DIR="$PROJHOME/rebuilt3.10-with-conda/mammoth"

source init3.10-with-conda.sh

singularity exec $SIF bash <<'EOF'

  echo "Running inside a container!"
  echo "\$WITH_CONDA"
  $WITH_CONDA

  if [ ! -d "$PROJHOME/venv/mammoth3.10-with-conda" ]; then
      echo Creating virtual environment mammoth3.10-with-conda
      echo python -m venv "\$PROJHOME/venv/mammoth3.10-with-conda"
      python -m venv "$PROJHOME/venv/mammoth3.10-with-conda"
  else
      echo Found a virtual environment mammoth3.10-with-conda
  fi
  echo Activating ...
  source $PROJHOME/venv/mammoth3.10-with-conda/bin/activate
  python --version

    pip install --upgrade pip
    pip install Flask==2.0.3
    pip install configargparse
    pip install flake8==4.0.1
    pip install pytest-flake8==1.1.1
    pip install pytest==7.0.1
    pip install pyyaml==6.0.2
    pip install pyonmttok
    pip install sacrebleu==2.3.1
    pip install scikit-learn==1.3.1
    pip install sentencepiece==0.2.0
    pip install tensorboard==2.19.0
    pip install timeout-decorator
    pip install tqdm==4.67.1
    pip install waitress
    pip install x-transformers==1.32.14

    cd $CODE_DIR
    # pip install -e .  # this fails due to requirements

  deactivate

EOF
```
This script sources from `init3.10-with-conda.sh` the module definitions and the container's full pathname:
```
# source this file

# module load LUMI/23.09  partition/L
module load LUMI/24.03  partition/L
module use /appl/local/containers/ai-modules
module load singularity-AI-bindings                # AI bindings will be needed

export SIF=$PROJHOME/sif/lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif

echo "Use the following commands to enter the env:"
echo "  source init3.10-with-conda.sh"
echo "  singularity exec \$SIF bash"
echo "  \$WITH_CONDA"
echo "  source \$PROJHOME/venv/mammoth3.10-with-conda/bin/activate"
echo "Then exit the container with"
echo "  deactivate"
echo "  exit"
```
But all this will end up installing the default nVidia version of `pytorch` unless run the installation on a GPU node.  If you install the default PyTorch (CPU-only) or a CUDA (NVIDIA) build, then later run on an AMD GPU node, PyTorch will just run on CPU (or fail to load CUDA). It won’t use the AMD GPU at all.  CPU-only vs a single MI250X GPU is typically 1–2 orders of magnitude slower for DL training/inference, depending on model/batch size. Think 10×–100×+ slower is a reasonable rule of thumb. So: yes, dramatically slower if you accidentally run a CPU/ CUDA-only build on the node.
