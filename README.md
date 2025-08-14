# mammoth-nlp-setup
Snippets to facilitate with the mammoth-nlp setup on Puhti and LUMI

## Purpose
This repository was born to develop an optimal setup procedure for the Mammoth Toolkit (known as `mammoth-nlp` in pip) for Transformer-based MT.
The use of the MT system involves two main aspects: training and inference.   
Both are compute intense, but especially training is the bottleneck when developing multi-lingual MT.

Everyone who has experience on supercomputing knows that the setup of the computing environment (multiprocessor communications, resource allocations and consistent software versions) matters.
This repository collects information that relates to the following aspects:

1. **You will need the right way to load PyTorch**
   - You should not install `pytorch` with `pip` (although such kind of instructions have been around).
   - The package loads tens of thousands of files per python task and these package files are stored mainly on an RAID disk.  This kind of list is slow to use, especially when there are a lot of cuts down a lot of resources from the system, slowing down all jobs and making you to behave badly. Thus, you need to have a container of SquashFS to speed up the reading of so many files every time when you import python. 
     b. You need to make sure that PyTorch has access to ROCm, OFI Plugin, Slingshot, Libfabric, High Speed Network, CXI, caches etc. to work optimally in interprocess communication between GPUs and between computation nodes.  You need to have the related run-time plugins in your library path and you need to make sure that they are consistent with each other.  Thus, you need to know what CSC-prefabricated containers and modules can provide you Python and PyTorch and what versions of them you need.
  
2. **You need to the right version of Python**
   - It is non-trivial to know what versions of Python and PyTorch are compatible with other packages needed for running Mammoth Toolkit.
   - This choice can affect the choice of the container or module that you use to load pytorch.

3. **You need to setup "comms" properly**
   - CSC packages and modules make all the possible to help to set up interprocessor communication right.  However, there are settings, such as just-in-time compilation cache setup that cannot be done strightforwardly in the modules in advance since the module does not necessarily know Slurm parameters etc.  There are also other situations where the user has to know how to set up the "comms".
   - Setting up the comms parameters is tricky and one often needs to diagnose log files and validate the correct behaviour of PyTorch and the ROCm architecture.  One of the common issues is that the run-time plugins are not found or they are not compatibe. Thus, doing the setup successfully requires some effort.
  
4. **You need to setup Slurm jobs correctly**
   - Although Slurm jobs and sbatch files can be explained as they stand, it is much more difficult to learn and understand how to write the resource allocations, pinnings, master port etc.  and what you should not do.
   - There is sa quite a lot of variantion in the resource allocations.  Furthermore, processor pinning is very difficult to learn without training examples.  Even then, the full application of the learned guidelines requires a few second thoughts.

5. **You also need to master Mammoth specific configurations**

Given all this complexity of setting up the environment for model trainining, there is a high risk of doing something wrong.   The purpose of this repository is to collect the know-how in the setup decisions.  Not only example setups but also what kind of design choices have been made before arriving to these choices.

## Topics

This repository of setup instructions will grow gradually as I move some of the related research here.
