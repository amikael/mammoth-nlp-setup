# MAMMOTH-nlp-setup - a framework for running MAMMOTH easily
Developed by Anssi Yli-Jyrä (c) 2025 as a part of the MARMoT project. CC-BY-NC

## This repo contains the following tree
```
$GITHOME/mammoth-nlp-setup
├── bin
│   ├── conf
│   │   ├── build-venv-mammoth-hf.sh           installing feat/hf_integration branch of MAMMOTH and its venv
│   │   ├── build-venv-mammoth.sh              old
│   │   ├── init3.10-with-conda.sh             old
│   │   ├── pip_install3.10-with-conda.sh      old
│   │   ├── pip_install3.10-with-site.sh       old
│   │   ├── requirements-lumi.txt              reduced deps for installing feat/hf_integration branch of MAMMOTH 
│   │   └── setup3.11.py                       MAMMOTH setup for pip intall with relaxed deps of the main branch (for Python 3.11)
│   ├── create                                 contains scripts for setting up experiment directories
│   │   ├── create-experiment2.md              old        
│   │   ├── create-experiment.md               old
│   │   ├── create-experiment.sh               old
│   │   └── tree.txt                           old
│   ├── diag                                   contains various test scripts
│   │   ├── detect_system.sh                   determines the machine name (on LUMI, this is non-standard)
│   │   ├── envcheck.sh                        show env variables
│   │   ├── mammoth_dep_check.md               discussion about mammoth-nlp dependencies
│   │   ├── mammoth_dep_check.py               - tests dependencies of the main branch
│   │   ├── mammoth_dep_check_proposed3.11.py  - tests relaxed dependencies of the main branch (for Python 3.11)
│   │   ├── print-args                         just lists the command line args separately
│   │   ├── test_fine_grain2.sh                  
│   │   ├── rccl_test.py                       tests the comms (more tests)
│   │   └── torch_env_check2.py                tests the comms (simple)
│   ├── modules
│   │   ├── load-pytorch-rocm-mammoth.txt      used when  `module load pytorch-rocm-mammoth`
│   │   └── pytorch-rocm-mammoth
│   ├── slurm
│   │   ├── README.md                          local help
│   │   ├── sbatch-tail.sh                     source this right after #sbatch directives
│   │   ├── distributed-setup.sh                - complements the missing allocations
│   │   ├── sanity-checks.sh                    - checks the allocations
│   │   ├── module-loads.sh                     - loads modules
│   │   ├── comms-setup.sh                      - sets comms environment
│   │   ├── task-wrapper.sh                    launces the job
│   │   └── local-setup.sh                      - used by task-wrapper to set up node-local variables and monitor
│   ├── templates
│   │   ├── job-setup_template.sh              template for job; copy to experment directory
│   │   ├── more-slurms
│   │   └── yml
│   └── wrappers                               used by pytorch-rocm-mammoth
│       ├── lazy_python_container.md           - documentation of the wrapper/module interplay
│       ├── pip -> python                      
│       ├── pip3 -> pip
│       ├── python                             - singularity launching wrapper for python
│       ├── python3 -> python
│       ├── python_container.md                old documentation about choosing the container
│       └── sing-bash                          - singularity launching wrapper for bash (less tested)
├── images                                     used by pytorch-rocm-mammoth that is loaded in module-loads.sh 
│   ├── lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif -> sif-images/lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif
│   ├── lumi-pytorch-rocm-6.2.4-python-3.12-pytorch-v2.7.1.sif -> sif-images/lumi-pytorch-rocm-6.2.4-python-3.12-pytorch-v2.7.1.sif
│   └── sif-images -> /appl/local/containers/sif-images
├── lib                                        used by pytorch-rocm-mammoth and comms-setup.sh 
│   ├── librccl-net-ofi.so -> /opt/aws-ofi-rccl/librccl-net.so
│   └── librccl-net.so -> /opt/aws-ofi-rccl/librccl-net.so
└── README.md                                  this file
```

## Your $PROJHOME will have to contain some other files that **you need to set up yourself**

```
$PROJHOME (put the following somewhere in your project directories and call the root $PROJHOME; set $PROJHOME in your .profile) 
├── bin                               # symlink to $GITHOME/mammoth-nlp-setup/images/
├── images                            # symlink to $GITHOME/mammoth-nlp-setup/images/
├── lib                               # symlink to $GITHOME/mammoth-nlp-setup/lib/
├── mammoth -> /users/aylijyra/git/mammoth       # symlink to $GITHOME/mammoth
├── mammoth-hf -> /users/aylijyra/git/mammoth-hf # symlink to $GITHOME/mammoth-hf worktree (greated in $GITHOME/mammoth with command `git worktree add ../mammoth-hf feat/hf_integration`)
├── modules -> bin/modules            # symlink to $GITHOME/mammoth-nlp-setup/bin/modules
├── projdata                          # a symlink to $PROJDATA
└── venv                              # virtual environments built by build-venv-mammoth-*.sh
    ├── mammoth
    └── mammoth-hf
```

## The repo runs in **a data directory tree that you also need to initialize yourself**

```
$PROJDATA (link the following somewhere in your project directories and call the root $PROJDATA; set $PROJDATA in your .profile) 
├── data                              # all data files that in use
│   ├── europarl
│   │   ├── ...
│   │   └── sv-en
│   └── europarl.tar.gz
├── exp
│   ├── 2025-08-21_enfi_1n1g-30m      # example directory, named after its `#SBATCH --job-name=2025-08-21_enfi_1n1g-30m`
└── vocab                             # all important vocabularies
    ├── opusTC.mul.64k.spm
    └── opusTC.mul.vocab.onmt
```

## The contents of the experiment directory that is created by scripts

```
$PROJDATA/exp/2025-08-21_enfi_1n1g-30m
├── bin -> $PROJHOME/bin                                 # shortcut to the project binaries
├── create.sh -> bin/create/2025-08-21_enfi_1n1g-30m.sh  # your script that can be used to build this directory
├── mammoth -> $PROJHOME/mammoth-hf                      # shortcut to the mammoth base (here feat/hf_integration branch)
├── conf.yml                                             # derived locally from conf.yml.envsubst
├── conf.yml.envsubst                                    # the source of cong.yml (to be updated asap with a better mechanism)
├── data                                                 # data files for the experiment; symlinks to ../../../data/
│   ├── europarl-v7.fi-en.en -> ../../../data/europarl/fi-en/europarl-v7.fi-en.en
│   ├── europarl-v7.fi-en.fi -> ../../../data/europarl/fi-en/europarl-v7.fi-en.fi
│   ├── train.fi-en.en.sp -> ../../../data/europarl/fi-en/train.fi-en.en.sp
│   ├── train.fi-en.fi.sp -> ../../../data/europarl/fi-en/train.fi-en.fi.sp
│   ├── valid.fi-en.en.sp -> ../../../data/europarl/fi-en/valid.fi-en.en.sp
│   └── valid.fi-en.fi.sp -> ../../../data/europarl/fi-en/valid.fi-en.fi.sp
├── eval                                                 # reserved for evaluation 
├── job-setup.sh                                         # sbatch will read this
├── logs                                                 # slurm etc logs
├── metrics                                              # links to your metrics
├── models                                               # saved MAMMOTH models
├── tensorboard                                          # reserved for monitoring
├── train-1n1g-2h.slurm                                  # your train etc script (to be renamed as enter.slurm)
└── vocab                                                # vocabularies used by the experiment; symlinks to ../../../data/
    ├── opusTC.mul.64k.spm -> ../../../vocab/opusTC.mul.64k.spm
    └── opusTC.mul.vocab.onmt -> ../../../vocab/opusTC.mul.vocab.onmt

```
