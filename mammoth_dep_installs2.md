# Installation of Mammoth NLP Dependencies - The Complete Picture

## What You Already Have
1. You have chosen the Python version and the corresponding container and made a project copy of it.
2. You have been on a GPU node
3. You have been to a container
4. You have created a virtual environment
5. You run the package installation script with command `bash pip_install3.10-with-conda.sh`.
6. We have downloaded MAMMOTH but the installation of MAMMOTH failed.

## Typical failing scenarios and Fixes

   1. **Must Reinstall on GPU node:** We have forgotten one from the combinartion: srun + singularity + activation before installation.  You must install inside a GPU session (srun --partition=dev-g ...) to ensure the ROCm (AMD) support on LUMI:
      - Many containers (like the LUMI PyTorch ROCm SIFs) mount /dev/kfd and /dev/dri and expose /opt/rocm.  When you pip install inside the container without being on a GPU node, ROCm is not fully available
      - Some packages (like x-transformers or pyonmttok) may detect this absence and assume CUDA, or install a prebuilt wheel that includes torch with +cuXXX (CUDA)

   2. **MAMMOTH does not completely install on Python 3.12:**  For the time being, `pyonmttok` package is not available for Python 3.12.  Reduce MAMMOTH requirements and components or use Python 3.11.

   3. **Python 3.11 needs newer packages:** When intalling sckit-learn to Python 3.11, the earliest compatible scikit-learn version seems to be 1.3.1.  It is also good to do the other updates to the requirements, hoping that MAMMOTH will still be compatible with these major updates.  For this purpose, I seems that you will need adjust MAMMOTH's `setup.py` to get through.
   
   4. **Python 3.10** seems to be compatible the original package requirements of MAMMOTH. I did not know this before trying and it was a surprise.  The package installation script will first install newer packages, but when installing MAMMOTH, it will downgrade some packages successfully.  This maximizes the compatibility with the virtual environment and MAMMOTH as MAMMOTH requirements in `setup.py` can be intact.
   
   5. **Prevent MAMMOTH dependents like `x-transformers` from installing pytorch from PyPi:**  The installation of `pytorch` as a dependent package is the first symptom that everything is not all right with the installation  procedure.
   
   6. **Include the preinstalled Python packages to the virtual environment:** I did not know that virtual environment starts from scratch unless the preinstalled packages are included to it.  When this happens, it is no wonder that CSC-installed `pytorch` in the container does not have any effect in usual virtual environment building instructions.  For example, the MAMMOTH installation tutorial gives creates a virtual environment from the scratch and then installs `pytorch` from PyPI, which makes the package to fallback from ROCm to nVidia simulations, thus failing to tap the full power of the AMD GPUs.

## The In-Depth Explanation of Fixes

### Recipe 1: Reinstall on a GPU Node
If you happened to do the same mistake as me and forgot to ensure GPU node for pip, you will need to restart building the virtual environment and the installation of MAMMOTH.  This can be done with the following commands:
```bash
rm -rf $PROJHOME/venv/mammoth3.10-with-conda  
rm -rf $PROJHOME/rebuilt3.10-with-conda
```
The use of GPU node during installation is ensured by `srun` session:
```bash
srun --account="$ACCOUNT" --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=2:00:00 --mem=25G --pty bash
bash pip_install3.10-with-conda.sh
exit # exit the srun session
```
After this build, you need to verify the torch provided by the environment finds ROCm.

### Recipe 2: Install MAMMOTH on Python 3.12
You can follow the recipe for Python 3.11, but currently there is no working recipe for building `pyonmttok` for Python 3.12.  I have tried this and the problem seemed to be that different parts of the known building recipe [OpenNMT repo discussion](https://github.com/OpenNMT/Tokenizer/issues/329) use implicitly different Python versions and libraries.   This prevents installing the compiled package to the virtual environment.  After some 20 attempts, I could not fix the discrepancy between the compilers.

### Recipe 3: Update the MAMMOTH Requirements
Now we have to update the `setup.py` of MAMMOTH.  Try
```bash
diff ../rebuilt3.10-with-conda/mammoth/setup.py conf/setup.py
```
If this looks good, you can: 
```
mv ../rebuilt3.10-with-conda/mammoth/setup.py ../rebuilt3.10-with-conda/mammoth/setup-original.py
cp -p conf/setup.py ../rebuilt3.10-with-conda/mammoth/setup.py
```
Now running the installation script again should start MAMMOTH installation on the virtual environment.
```bash
srun --account="$ACCOUNT" --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=2:00:00 --mem=25G --pty bash
bash pip_install3.10-with-conda.sh
exit # exit the srun session
```
### Recipe 4: You Just Use the Packet Installation Script
Running the recipe 1 after discovering the pytorch incompatibility already completed the MAMMOTH installation.
It was a surprise that when running Python 3.10, the current requirements are still compatible.  But as the following indicates, adding MAMMOTH will downgrade some packages that were required or otherwise natural updates for newer Python versions.
```bash
Successfully built mammoth-nlp
Installing collected packages: sentencepiece, tqdm, einops, scikit-learn, mammoth-nlp
  Attempting uninstall: sentencepiece
    Found existing installation: sentencepiece 0.2.0
    Uninstalling sentencepiece-0.2.0:
      Successfully uninstalled sentencepiece-0.2.0
  Attempting uninstall: tqdm
    Found existing installation: tqdm 4.67.1
    Uninstalling tqdm-4.67.1:
      Successfully uninstalled tqdm-4.67.1
  Attempting uninstall: einops
    Found existing installation: einops 0.8.1
    Uninstalling einops-0.8.1:
      Successfully uninstalled einops-0.8.1
  Attempting uninstall: scikit-learn
    Found existing installation: scikit-learn 1.3.1
    Uninstalling scikit-learn-1.3.1:
      Successfully uninstalled scikit-learn-1.3.1
Successfully installed einops-0.8.0 mammoth-nlp-0.2.1 scikit-learn-1.2.0 sentencepiece-0.1.97 tqdm-4.66.2
```
### Recipe 5: Prevent MAMMOTH dependents like `x-transformers` from installing pytorch from PyPI:
Our problem seems to be that when I am installing packages for MAMMOTH, the CSC provided `pytorch` that supports ROCm gets replaced with a `pytorch` that is not meant for AMD.  To test this, we will restart the installation process and run torch validation at every step to see if any of them mingled this.  This packet is also observable from the installation where one can see from the log that `torch` is installed. 

In fact, it is easy to verify that some packages such as `x-transformers` require pytorch.  Presumably this requirement causes them to download a newer pytorch from PyPI.  This can be prevented with an option:
```bash
pip install --no-deps x-transformers
```
I have now updated the script `pip_install3.10-with-conda.sh` accordingly, but this attacks only the symptom and is not the correct way, because some of the packages x-transformers is dependent of may now be left uninstalled.  The better way is to inherit the site packages which turns out to be the root problem, see Recipe 6.

### Recipe 6: Include the preinstalled Python packages to the virtual environment
Now it seems that when we create a virtual environment, the preinstalled python packages, such as `torch` is not automatically included.  The following demonstrates the problem.
```bash
(pytorch) Singularity> python -c 'import torch; quit()'
(pytorch) Singularity> python -m venv test-venv
(pytorch) Singularity> python -c 'import torch; quit()'
(pytorch) Singularity> source test-venv/bin/activate
(test-venv) (pytorch) Singularity> python -c 'import torch; quit()'
ModuleNotFoundError: No module named 'torch'
```
The trick to force the inheritance of the preinstalled packages is to use the option `--system-site-packages`:
```bash
python -m venv --system-site-packages my-venv
```
I have now updated `pip_install3.10-with-conda.sh` with name `pip_install3.10-with-site.sh` adding the option to the environment creation. This can be used as follows:
```bash
remove -rf $PROJHOME/venv/mammoth3.10-with-conda   # no more needed
remove -rf $PROJHOME/rebuilt3.10-with-conda        # good to rebuild
srun --account="$ACCOUNT" --partition=dev-g --ntasks=1 --gres=gpu:mi250:1 --time=2:00:00 --mem=25G --pty bash
bash pip_install3.10-with-site.sh
```
