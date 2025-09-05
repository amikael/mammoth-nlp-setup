# mammoth-nlp-setup

├── bin
│   ├── conf
│   │   ├── build-venv-mammoth-hf.sh                       <= installing feat/hf_integration 
│   │   ├── build-venv-mammoth.sh              old
│   │   ├── init3.10-with-conda.sh             old
│   │   ├── pip_install3.10-with-conda.sh      old
│   │   ├── pip_install3.10-with-site.sh       old
│   │   ├── requirements-lumi.txt                          <= needed by installing feat/hf_integration
│   │   └── setup3.11.py                       old
│   ├── create                                 contains scripts for setting up experiment directories
│   │   ├── create-experiment2.md              old        
│   │   ├── create-experiment.md               old
│   │   ├── create-experiment.sh               old
│   │   └── tree.txt                           old
│   ├── diag                                   contains various test scripts
│   │   ├── detect_system.sh
│   │   ├── envcheck.sh -> /users/aylijyra/git/RCCL-tests/envcheck.sh
│   │   ├── mammoth_dep_check.md
│   │   ├── mammoth_dep_check_proposed3.11.py
│   │   ├── mammoth_dep_check.py
│   │   ├── print-args                          
│   │   ├── rccl_test.py -> /users/aylijyra/git/RCCL-tests/rccl_test.py
│   │   ├── test_fine_grain2.sh -> /users/aylijyra/git/RCCL-tests/test_fine_grain2.sh
│   │   └── torch_env_check2.py -> /users/aylijyra/git/RCCL-tests/torch_env_check2.py
│   ├── modules
│   │   ├── load-pytorch-rocm-mammoth.txt       used when  `module load pytorch-rocm-mammoth`
│   │   └── pytorch-rocm-mammoth
│   ├── slurm
│   │   ├── README.md                           local help
│   │   ├── sbatch-tail.sh                      source this right after #sbatch directives
│   │   ├── distributed-setup.sh                - complements the missing allocations
│   │   ├── sanity-checks.sh                    - checks the allocations
│   │   ├── module-loads.sh                     - loads modules
│   │   ├── comms-setup.sh                      - sets comms environment
│   │   ├── task-wrapper.sh                     launces the job
│   │   └── local-setup.sh                      - used by task-wrapper to set up node-local variables and monitor
│   ├── templates
│   │   ├── job-setup_template.sh               template for job; copy to experment directory
│   │   ├── more-slurms
│   │   └── yml
│   └── wrappers                                used by pytorch-rocm-mammoth, singularity wrappers for python and pip
│       ├── lazy_python_container.md
│       ├── pip -> python
│       ├── pip3 -> pip
│       ├── python
│       ├── python3 -> python
│       ├── python_container.md
│       └── sing-bash
├── images                                      used by pytorch-rocm-mammoth that is loaded in module-loads.sh 
│   ├── lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif -> sif-images/lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif
│   ├── lumi-pytorch-rocm-6.2.4-python-3.12-pytorch-v2.7.1.sif -> sif-images/lumi-pytorch-rocm-6.2.4-python-3.12-pytorch-v2.7.1.sif
│   └── sif-images -> /appl/local/containers/sif-images
├── lib                                         used by pytorch-rocm-mammoth and comms-setup.sh 
│   ├── librccl-net-ofi.so -> /opt/aws-ofi-rccl/librccl-net.so
│   └── librccl-net.so -> /opt/aws-ofi-rccl/librccl-net.so
└── README.md                                   this file