# Reinstalling MAMMOTH to LUMI using User Module for Container
Modularized container makes things much easier.  First, let us factor out the module load commands to the file `$PROJHOME/bin/module-loads.sh` that contains the lines:
```bash
# usage: source $PROJHOME/bin/module-loads.sh in your existing shell
(return 0 2>/dev/null) || { echo "❌ Please source this script instead of executing it."; exit 1; }
module use /appl/local/containers/ai-modules  # AI-bindings
module use $PROJHOME/modules                  # pytorch-rocm-mammoth
module load LUMI/24.03                # 
module load partition/L               # 
module load singularity-AI-bindings   # AI bindings will be needed
module load pytorch-rocm-mammoth/2.0  # delayed pytorch, rocm sif
```
Then, I created the script `build-venv-mammoth.sh` that looks like the following:
```bash
#! /usr/bin/bash

: "${ACCOUNT:?❌ ACCOUNT is not set}"                  # project_462000964
: "${PROJHOME:?❌ PROJHOME is not set}"                # /project/$ACCOUNT/members/$USER
: "${MAMMOTH_BASE:?❌ MAMMOTH_BASE is not set}"        # $PROJHOME/venv/mammoth

source $PROJHOME/bin/module-loads.sh                   # load modules
python -m venv --system-site-packages $MAMMOTH_BASE    # create the environment
source $MAMMOTH_BASE/bin/activate                      # enter the environment
  pip install mammoth-nlp                              #   install MAMMOTH
deactivate                                             # quit the environment
```
Just do during a fresh lumi session:
```bash
srun --account="$ACCOUNT" --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=2:00:00 --mem=25G --pty bash build-venv-mammoth.sh
```
After this has been run, everything is ready.  One can now:
```bash
: "${ACCOUNT:?❌ ACCOUNT is not set}"                  # project_462000964
: "${PROJHOME:?❌ PROJHOME is not set}"                # /project/$ACCOUNT/members/$USER
: "${MAMMOTH_BASE:?❌ MAMMOTH_BASE is not set}"        # $PROJHOME/venv/mammoth
: "${CODE_DIR:?❌ CODE_DIR is not set}"                # $MAMMOTH_BASE/lib64/python3.10/site-packages/mammoth/bin

source $PROJHOME/bin/module-loads.sh                   # load modules
source $MAMMOTH_BASE/bin/activate                      # enter the environment
srun --account="$ACCOUNT" --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=2:00:00 --mem=25G --pty python $CODE_DIR/train.py
```
This run successfully and produced the following output:
```
run: job 11959312 queued and waiting for resources
srun: job 11959312 has been allocated resources
Real python: /project/project_462000964/members/aylijyra/venv/mammoth/bin/python
Running python in /project/project_462000964/members/aylijyra/images/lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif...
/project/project_462000964/members/aylijyra/venv/mammoth
including /project/project_462000964/members/aylijyra/venv/mammoth/lib/python3.10/site-packages ...
including /project/project_462000964/members/aylijyra/venv/mammoth/lib64/python3.10/site-packages ...
Launch into container and forward virtual environment
/appl/local/csc/soft/ai/bin/singularity_wrapper exec /project/project_462000964/members/aylijyra/images/lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif bash -c $WITH_CONDA && exec -a "/project/project_462000964/members/aylijyra/venv/mammoth/bin/python" "python"  /project/project_462000964/members/aylijyra/venv/mammoth/lib64/python3.10/site-packages/mammoth/bin/train.py
usage: train.py [-h] [-config CONFIG] [-save_config SAVE_CONFIG] -tasks TASKS ...
```
Thus, we have proven that modularized container with delayed launch is a very handful trick and solidly implemented by CSC / LUST.  Furthermore, we managed to apply this trick to our case where we wanted to use a recent container.  This approach has multiple benefits:
- Removes the clutter of running singularity from the code.
- Simplifies the design of sbatch workflows.
- Similar look-and-feel as with `module load pytorch`.
- The trick takes care of the order where the container is run just before the application.
- The investigations uncovered that rocm-setup.py can be incorporated (as lua function calls) to the module file, as there are already similar environment settings in place.
- Since srun *inherits* the module settins, all settings can be collected to the sbatch file elegantly.
- There is no need for user to remember $WITH_CONDA command.
- modules, container, pythin path, venv and srun are all nicely orchestrated and naturally ordered in the sbatch file.
