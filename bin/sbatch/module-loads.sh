echo module-loads...
# usage: source module-loads.sh 
(return 0 2>/dev/null) || { echo "❌ Please source this script instead of executing it."; exit 1; }

module  --force purge
if [[ $SYSTEM == "lumi" ]]; then
    module -q use   /appl/local/containers/ai-modules   # AI-bindings
    module -q use  $PROJHOME/modules                   # pytorch-rocm-mammoth
    module -q load  LUMI/24.03                         # 
    module -q load  partition/L                        # 
    module -q load  singularity-AI-bindings            # AI bindings will be needed
    module -q load  pytorch-rocm-mammoth               # lazy pytorch module
else
    echo "module loads for $SYSTEM are not yet specified in module-load.sh"
    exit 1
fi
#module use /appl/local/csc/modulefiles/
#module load  pytorch/2.4
#module load gcc/9.4.0

echo ============================================================================
module --redirect list |egrep '\)'
echo ============================================================================
