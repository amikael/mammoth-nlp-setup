# mammoth-nlp-setup
Snippets to facilitate with the search for the optimal mammoth-nlp setup on LUMI (lumi.csc.fi).  

## Purpose
This repository was born to develop an optimal setup procedure for the Mammoth Toolkit (known as `mammoth-nlp` in pip) for Transformer-based MT.
The use of the MT system involves two main aspects: training and inference.   
Both are compute intense, but especially training is the bottleneck when developing multi-lingual MT.

Everyone who has experience on supercomputing knows that the setup of the computing environment (multiprocessor communications, resource allocations and consistent software versions) matters.
This repository collects information that relates to the following aspects:

1. **You will need the right way to load PyTorch**
   - You should not install `pytorch` with `pip` (although such kind of instructions have been around). The package loads tens of thousands of files per python task and these package files are stored mainly on an RAID disk.  This kind of list is slow to use, especially when there are a lot of cuts down a lot of resources from the system, slowing down all jobs and making you to behave badly.
   - Thus, you need to have a container of SquashFS to speed up the reading of so many files every time when you import python. 
   - You need to make sure that PyTorch has access to ROCm, OFI Plugin, Slingshot, Libfabric, High Speed Network, CXI, caches etc. to work optimally in interprocess communication between GPUs and between computation nodes.   You need to have the related run-time plugins in your library path.
   - You need to make sure that they are consistent with each other.  Thus, you need to know what CSC-prefabricated containers and modules can provide you Python and PyTorch and what versions of them you need.
  
2. **You need to use a fairly recent but not the most recent version of Python**
   - It is non-trivial to know what versions of Python and PyTorch are compatible with other packages needed for running Mammoth Toolkit.  Python >=3.12 is definitely too new and incompatible with one package, but can you install mammoth on Python 3.11?
   - The choice of Python version can affect the choice of the container or module that you use to load pytorch.  We may be in a trouble if Python 3.11 is no more supported for the recommended PyTorch/ROCm combo where ROCm is updated to 6.3.  

3. **You need to setup LUMI "comms" properly**
   - CSC packages and modules make all the possible to help to set up inter-processor communication right.  However, there are settings, such as just-in-time compilation cache setup that cannot be done strightforwardly in the modules in advance since the module does not necessarily know Slurm parameters etc.  There are also other situations where the user has to know how to set up the "comms".
   - Setting up the comms parameters is tricky and one often needs to diagnose log files and validate the correct behaviour of PyTorch and the ROCm architecture.  One of the common issues is that the run-time plugins are not found or they are not compatibe. Thus, doing the setup successfully requires some effort.
  
4. **You need to setup Slurm jobs correctly**
   - Although Slurm jobs and sbatch files can be explained as they stand, it is much more difficult to learn and understand how to write the resource allocations, pinnings, master port etc.  and what you should not do.
   - There is sa quite a lot of variantion in the resource allocations.  Furthermore, processor pinning is very difficult to learn without training examples.  Even then, the full application of the learned guidelines requires a few second thoughts.

5. **You also need to master Mammoth specific configurations**

Given all this complexity of setting up the environment for model trainining, there is a high risk of doing something wrong.   The purpose of this repository is to collect the know-how in the setup decisions.  Not only example setups but also what kind of design choices have been made before arriving to these choices.  *This is not the place to find short answers*  This is a repository where you find some tools, research, and results on the setup best practice.

## Topics on LUMI 

This repository of setup instructions will grow gradually as I move some of the related research here.

### Using (almost) the latest PyTorch version for LUMI
- [python_container.md](python_container.md) - Describes how I chose a CSC-provided container with recent ROCm support
- [lazy_python_container.md](lazy_python_container.md) - Using the container through the CSC-style module (that I adapted to the container)

### Setting the CONDA Virtual Environment
- [setup3.11.py](setup3.11.py) is an update file to `setup.py` of `mammoth-nlp`: this comes with some updates in the `install_requires` of mammoth-nlp when this is being installed on Python 3.11. (After a thorough testing, this file update may be included to the mammoth-nlp codebase.)
- [mammoth_dep_check.py](mammoth_dep_check.py) is a tool for checking the status of the python packages required by `mammoth-nlp`.  
- [mammoth_dep_check_proposed3.11.py](mammoth_dep_check_proposed3.11.py) is the same tool with some updates in the `install_requires` of mammoth-nlp when this is being installed on Python 3.11.
- [mammoth_dep_check.md](mammoth_dep_check.md) gives some examples of the use case, indicating the changes in the package requirement status when I installed mammoth-nlp on Python 3.11 and made some changes to get the clean output.

  For the basic use this tool is a bit too much code, but it gives a nice output anyway.  If it does not work, it may require some registry file (a dot file) to exist in the user's home directory.  This is because the tool was orginally intended for finding out whether these packages are from the cray-python module, pytorch module, user's local installations or from the virtual environment, but this functionaly is a relic that may or may not work when set up with some wrappers for module and pip commands.   
                                                                                                                                                     - [mammoth_dep_installs1.md](mammoth_dep_installs1.md) is a document describing verbosely how I set up the virtual environment for mammoth-nlp and learned to do it "almost right". This was done first under a recommended AI container since this was newer than the pytorch module.  (Later on, I managed to make a CSC-style module out of this container.  Soon, I guess, we can expect to have a newer pytorch module available too.)
- [mammoth_dep_installs2.md](mammoth_dep_installs2.md) decribes what still went wrong with the creation of the virtual environment.  I identified 6 recipies to do the things in the right way.  You are not done before you understand all six of them.
- [mammoth_dep_installs3.md](mammoth_dep_installs3.md) validates the pytorch version of the venv with site packages.
- [mammoth_dep_installs4.md](mammoth_dep_installs4.md) uses a CSC-style module for a CSC-built container and reinstall mammoth-nlp using it. The best results so far! 
- [mammoth_dep_installs5.md](mammoth_dep_installs4.md) uses a CSC-style module for a CSC-built container and reinstall mammoth-nlp using it. The best results so far! 
                                       
### Setting up the Inter-processor communication
- [RCCL-test](https://github.com/amikael/RCCL-tests) is a repository of tools I developed to facilitate testing the inter-processor communications in LUMI.
- [rocm-setup.sh](rocm-setup.sh) is a shell include file (intended to be sourced rather than called) containing variable settings for the optimal interprocessor communication.
- [rocm-setup-commented.sh](rocm-setup-commented.sh) is the same file with some information about the validation of various features via log file.  This file is a relic and I am not sure if this is very useful.

### Setting up the Slurm jobs

- [detect_system.sh](detect_system.sh) is an includable script that detects whether we are on puhti.csc.fi, lumi.csc.fi etc.  Note that `$(hostname)` does not work on LUMI.  This can be used to make trains scripts to adapt automatically to the system when you have to switch between different machines.
- 

