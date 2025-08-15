## Testing the Module: Bindings Are Important! 
The following tests are motivated by the retrospective observation that possible installation errors cause faults in various stages of the training command of mammoth-nlp.  Here are some stages:
1. If bindings are missing in the container launch, even the test scripts can fail.
2. If Python library path is not correct, `train.py` does not start correctly.
3. At this stage, if `train.py` proceeds to ROCm initialization, related errors can occur.

In the following, we have detected an error with `train.py`, but tried some diagnosis tools.  These tools do not find the error with Python load paths, but they find some other issues that related to the way the container is launched.   At first, the manual launch and the lazy launch via the module look very different.  I was then able to make the two launching methods look indistinguishable when it comes to the dependency checks and the rccl tests.  But they remain distinguishable by the error that concerns the Python load path.  This will be tackled in the next notebook.

### False Impressions
Many things seem to work like magic.  However, I am still testing the virtual environment and the diagnosis tools with it.  Currently, there are problems in the automatic activation of the virtual environment, but if one does this activation explicitly, the diagnosis tool sees the virtual environment. 
```bash
module use /appl/local/containers/ai-modules
module load singularity-AI-bindings                # AI bindings will be needed
module use $PROJHOME/modules
module load pytorch-rocm-mammoth
source $PROJHOME/venv/mammoth3.10-with-site/bin/activate
source $PROJHOME/conf/rocm-setup.sh
python rebuilt3.10-with-conda/mammoth/mammoth/bin/train.py
```
For now this started promisingly, but ended with an error:
```bash
Running python in $SING_IMAGE...
/project/project_462000964/members/aylijyra/venv/mammoth3.10-with-site
Launch into container and forward virtual environment
/appl/local/csc/soft/ai/bin/singularity_wrapper exec images/lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif bash -c $WITH_CONDA && exec -a "/project/project_462000964/members/aylijyra/bin/python" "python"  rebuilt3.10-with-conda/mammoth/mammoth/bin/train.py
Traceback (most recent call last):
  File "/pfs/lustrep1/projappl/project_462000964/members/aylijyra/rebuilt3.10-with-conda/mammoth/mammoth/bin/train.py", line 7, in <module>
    from mammoth.distributed import (
ModuleNotFoundError: No module named 'mammoth.distributed'
```
There seems to be an error with the **Python paths**.  Given the error, we remove the venv activation code from the wrapper.  The same error occurred.  
### Contents of `init3.10-with-conda.sh`
To facilitate manual launching of a container for Python 3.10 and PyTorch, the following bash source script (`init3.10-with-conda.sh`) was created:
```
module load LUMI/24.03  partition/L
module use /appl/local/containers/ai-modules
module load singularity-AI-bindings                # AI bindings will be needed
export SIF=$PROJHOME/sif/lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif
```
### Comparing to Manual Approach
We suspected an error with the module `pytorch-rocm-mammoth`.  To avoid the module, we launch the related container manually.
```bash
source init3.10-with-conda.sh  # run the module commands and set SIF
singularity exec $SIF bash
$WITH_CONDA
source $PROJHOME/venv/mammoth3.10-with-site/bin/activatepython torch_env_check2.py
source $PROJHOME/conf/rocm-setup.sh
python $PROJHOME/rebuilt3.10-with-conda/mammoth/mammoth/bin/train.py
```
This otputs: `usage: train.py [-h] [-config CONFIG] [-save_config SAVE_CONFIG] -tasks TASKS...` which 
seems to be a good sign.  This shows that **we have more trust on the manual launch of containers** at this point.

In fact we forgot to do `srun`.  I wondered would we get the same promising output come with the compute dode.  Let us redo the check:
```bash
srun --account="$ACCOUNT" --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=2:00:00 --mem=25G --pty bash
source init3.10-with-conda.sh  # run the module commands and set SIF
singularity exec $SIF bash
$WITH_CONDA
source $PROJHOME/venv/mammoth3.10-with-site/bin/activate
source $PROJHOME/conf/rocm-setup.sh
python $PROJHOME/rebuilt3.10-with-conda/mammoth/mammoth/bin/train.py
```
This workflow was also good enough to the `usage information`.  Thus, we do not see any problem with the manual launch of the container, but the problem is with the CSC-style module.  Let's fix it now.

### Debugging
The analysis of the error. Recall that the problem was related to **Python paths** and our own **CSC-like module** that launches the container.   Perhaps the module changes the paths somehow...  Let's find it out!

We started with command `find $PROJHOME/rebuilt3.10-with-conda/mammoth |egrep distributed` that show that `rebuilt3.10-with-conda/mammoth/mammoth/distributed` is an existing directory containing `.py` packages.  This indicated that the error relates to **python paths**.  

We may also try another approach: building the virtual environment from scratch using the container and the CSC-like module for it.  
If we do, in both cases, the venv on the top of srun + container + --site-packages, the virtual environment construction does not make any difference.  

Instead, we can try to show that the problem is related to the *mammoth-nlp* only.  To verify this, we run our test scripts.  If all of them work fine, then mammoth is the only package having problems.  However, since some of these scripts also initiate ROCm / RCCL, they fail if not run on a compute node.

#### A. Testing the manual setting without `srun`
1. Test #1: `python diag/mammoth_dep_check_proposed3.11.py` produce a clean table of packages. Passed.
2. Test #2: `python diag/torch_env_check2.py` produced clean results. Passed.
3. Test #3: `python diag/rccl_test2.py` **failed**.  This was **expected** since we are on the login node.

In the training material, singularity is always launched inside an `srun` command.  However, it is still possible to pre-load a module that is based on a singularity container before running `srun`.  Without knowing at this point how such modules have been implemented, I made a naive test: try to launch a container manually and then run `srun`.   This was not successful: trying to launch `srun` while inside venv/pytorch/Singularity  failed: Command not found.   The naive test was very useful for learning about how the module has been implemented: it launches the container lazily, inside the compute node, thus inside `srun`.  Thus, the module technology and its implementation is a great way to clean the user's experience and to allow 'loading' a container before it is actually launched.    

#### B. Testing the manual setting with `srun`

Now we did `srun --account=$PROJECYT --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=00:30:00 --pty bash` before the tests and the manual launc of the container.

1. Test #1: `python diag/mammoth_dep_check_proposed3.11.py` produce a clean table of packages. Passed.
2. Test #2: `python diag/torch_env_check2.py` produced clean results. Passed.
3. Test #3: `python diag/rccl_test2.py`.  This was first successful but resulted in some late errors:
```bash
/bin/sh: fi_info: command not found
/bin/sh: ip: command not found
[W socket.cpp:464] [c10d] The server socket has failed to bind to [::]:12355 (errno: 98 - Address already in use).
```
   **The first two errors related to bindings of binaries and some others to the availability of the port**.  

The following bindings were needed (in addition to those provided by `module load AI-bindings`).  These were added to `init3.10-with-conda.sh`.
```
export BINDINGS="--bind /bin/ip:/bin/ip --bind /usr/lib64/libmnl.so.0:/usr/lib64/libmnl.so.0 \
  --bind /opt/cray/libfabric/1.15.2.0/bin/fi_info:/bin/fi_info "
```

#### C. Testing `rccl_test2.py` on the container again with additional bindings 

Now we added bindings to the container launch.  The variable `BINDINGS` is defined in `init3.10-with-conda.sh`.

```bash
singularity exec $BINDINGS $SIF bash
$WITH_CONDA
source $PROJHOME/venv/mammoth3.10-with-site/bin/activate
source $PROJHOME/conf/rocm-setup.sh
python conf/rccl_test2.py
```
The bindings helped:  The command `python diag/rccl_test2.py` passed and produced clean results.  

#### D. Testing `rccl_test2.py` on the module again: remember to add the same bindings 

Now, let us redo these tests with the module approach.  This time we also have `srun`.
```bash
exit # exit manually launched Singularity
module use /appl/local/containers/ai-modules
module load singularity-AI-bindings                # AI bindings will be needed
module use $PROJHOME/modules
module load pytorch-rocm-mammoth
source $PROJHOME/venv/mammoth3.10-with-site/bin/activate
source $PROJHOME/conf/rocm-setup.sh
srun --account=$PROJECYT --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=00:30:00 --pty bash
python conf/rccl_test2.py
```

1. Test #1: `python diag/mammoth_dep_check_proposed3.11.py` produce a clean table of packages. Passed.
2. Test #2: `python diag/torch_env_check2.py` produced clean results. Passed.
3. Test #3: `python conf/rccl_test2.py` worked fine, but the same bindings were missing, causing some errors.

We already knew about the missing bindings but forgot to fix the issue when launching the container lazily via the module `pytorch-rocm-mammoth` and `python`.  To bad!     I added these bindings to the new 2.0 module and loaded it: `module load pytorch-rocm-mammoth/2.0`.  (The module system seems to find the latest module automatically.  Thus, even `module load pytorch-rocm-mammoth` is now enough when
their  contain the lines:
```
```
With the fixed bindings, command `python conf/rccl_test2.py` produced clean results. The script found the binaries.  **Test passed.**
The conclusion is that the test scripts run fine but *mammoth* does not.  Thus it is likely that **there is something wrong with the way how mammoth** has been added to the python venv.  To check this, we do not seem to need a GPU session (as `train.py` can produce the usage information on a login node too=, but it may be a good idea anyway.  

In the following notebook, I report the new installation procedure that uses the module and venv in a neat way.
