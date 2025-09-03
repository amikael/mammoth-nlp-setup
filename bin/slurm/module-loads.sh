
echo module-loads...
# (c) 2025 Anssi Yli-Jyrä, CC-BY

# usage: source module-loads.sh 
(return 0 2>/dev/null) || { echo "❌ Please source this script instead of executing it."; exit 1; }

LOCAL_PROJHOME=$PROJHOME
# LOCAL_PROJHOME=/project/project_462000964/members/aylijyra

module  --force purge
if [[ $SYSTEM == "lumi" ]]; then
    module -q use   /appl/local/containers/ai-modules  # AI-bindings
    module -q use   $LOCAL_PROJHOME/modules            # pytorch-rocm-mammoth
    module -q load  LUMI/24.03                         # 
    module -q load  partition/L                        # 
    module -q load  singularity-AI-bindings            # AI bindings will be needed
    module -q load  pytorch-rocm-mammoth               # lazy pytorch module
      # ask Anssi for this module, if you cannot access $LOCAL_PROJHOME
else
    echo "module loads for $SYSTEM are not yet specified in module-load.sh"
    echo "please add them in this script!"
    exit 1
fi

echo ============================================================================
module --redirect list |egrep '\)'
echo ============================================================================
