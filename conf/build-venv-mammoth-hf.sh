#! /usr/bin/bash
# (c) 2025 Anssi Yli-Jyrä, CC-BY

# This script assumes $ACCOUNT, $PROJHOME
# The script pulls updates in $HOME/git/mammoth
# The script builds $HOME/git/mammoth-hf
# The script creates symlink $PROJHOME/mammoth-hf
# The script deletes/rebuilds $PROJHOME/venv/mammoth-hf

: "${ACCOUNT:?❌ ACCOUNT is not set}"           # project_462000964
: "${PROJHOME:?❌ PROJHOME is not set}"         # /project/$ACCOUNT/members/$USER
source $PROJHOME/bin/slurm/module-loads.sh

# clone or pull current mammoth at user's home git
: "${GITHOME:?❌ GITHOME is not set}"           # $HOME/git
cd $GITHOME/mammoth
git pull
# git clone https://github.com/Helsinki-NLP/mammoth.git mammoth

cd $PROJHOME
export MAMMOTH_REPO=$PROJHOME/mammoth
: "${MAMMOTH_REPO:?❌ MAMMOTH_REPO is not set}"
ln -s $HOME/git/mammoth $MAMMOTH_REPO

export MAMMOTH_HF_BASE=$PROJHOME/mammoth-hf
cd $MAMMOTH_REPO
git worktree add ../mammoth-hf feat/hf_integration
ln -s $HOME/git/mammoth-hf $MAMMOTH_HF_BASE
: "${MAMMOTH_HF_BASE:?❌ MAMMOTH_HF_BASE is not set}"

export MAMMOTH_VENV=$PROJHOME/venv/mammoth-hf
: "${MAMMOTH_VENV:?❌ MAMMOTH_VENV is not set}"
rm -Rf $PROJHOME/venv/mammoth-hf
python -m venv --system-site-packages "$MAMMOTH_VENV"
source $MAMMOTH_VENV/bin/activate
python -m pip install --upgrade pip
# pip install -r $MAMMOTH_HF_BASE/requirements.txt
pip install -r $PROJHOME/conf/requirements-lumi.txt

# expect something like this:
# Successfully installed ConfigArgParse-1.7.1 MarkupSafe-3.0.2 certifi-2025.8.3 charset-normalizer-3.4.3 einx-0.3.0 frozendict-2.4.6 fsspec-2025.7.0 idna-3.10 loguru-0.7.3 networkx-3.5 packaging-25.0 protobuf-6.32.0 setuptools-80.9.0 sympy-1.14.0 tensorboard-2.20.0 transformers-4.55.4 typing_extensions-4.14.1 urllib3-2.5.0

deactivate
