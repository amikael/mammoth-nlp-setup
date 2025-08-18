echo module-loads...
# usage: source module-loads.sh 
(return 0 2>/dev/null) || { echo "❌ Please source this script instead of executing it."; exit 1; }

HOSTNAME=$(hostname)  # this does not work well for lumi
if [[ $SYSTEM == "" ]]; then
   if [[ "$HOSTNAME" == roihu* ]]; then
      export SYSTEM=roihu
   elif [[ "$HOSTNAME" == mahti* ]]; then
      export SYSTEM=mahti
   elif [[ "$HOSTNAME" == puhti* ]]; then
      export SYSTEM=puhti
   elif grep -q 'lumi-super' /etc/motd; then
      export SYSTEM=lumi
   else
      echo "⚠️ Unknown system: $HOSTNAME. Please edit this script (detect_system.sh) manually."
      exit 1
   fi
fi

module  --force purge
module use /appl/local/containers/ai-modules  # AI-bindings
module use $PROJHOME/modules                  # pytorch-rocm-mammoth
module load LUMI/24.03                        # 
module load partition/L                       # 
module load singularity-AI-bindings           # AI bindings will be needed
#module use /appl/local/csc/modulefiles/
#module load  pytorch/2.4
#module load gcc/9.4.0
module load pytorch-rocm-mammoth              # lazy pytorch module
echo Loaded modules: LUMI/24.03, partitionl/L, singularity-AI-bindings, pytorch-rocm-mammoth

