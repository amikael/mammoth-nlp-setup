#! /usr/bin/bash

export MAMMOTH_BASE=$PROJHOME/venv/mammoth

module use /appl/local/containers/ai-modules
module use $PROJHOME/modules

module load LUMI/24.03
module load partition/L
module load singularity-AI-bindings                # AI bindings will be needed
module load pytorch-rocm-mammoth

python -m venv --system-site-packages "$MAMMOTH_BASE"
source $MAMMOTH_BASE/bin/activate

pip install mammoth-nlp
export CODE_DIR=$MAMMOTH_BASE/lib64/python3.10/site-packages/mammoth/bin

# deactivate


