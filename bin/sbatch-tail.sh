(return 0 2>/dev/null) || { echo "❌ Please source this script instead of executing it."; exit 1; }
echo sbatch-tail...

# These come from the .profile or otherwise from the environment.
: "${SYSTEM:?❌ SYSTEM is not set}"
: "${PROJHOME:?❌ PROJHOME is not set}"            # /project/$ACCOUNT/members/$USER
: "${PROJDATA:?❌ PROJDATA is not set}"            # /scratch/$ACCOUNT/members/$USER
: "${ACCOUNT:?❌ ACCOUNT is not set}"              # project_462000964
echo ==============================================
echo " SYSTEM (from .profile)    : $SYSTEM"
echo " ACCOUNT                   : $ACCOUNT"
echo " USER                      : $USER"
echo " PROJHOME (from .profile)  : $PROJHOME"
echo " PROJDATA (from .profile)  : $PROJDATA"
echo " SLURM_JOB_NAME            : $SLURM_JOB_NAME"
echo ==============================================

f="$PROJHOME/conf/distributed-setup.sh"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }
f="$PROJHOME/conf/santy-checks.sh"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }
f="$PROJDATA/trains/$SLURM_JOB_NAME/job-setup.sh"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }
f="$PROJHOME/conf/module-loads.sh"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }
f="$PROJHOME/conf/comms-setup.sh"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }
f="$PROJHOME/conf/local-setup.sh"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }
f="$PROJHOME/conf/wrapper.sh"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }
f="$MAMMOTH/bin/activate"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }

source $PROJDATA/trains/$SLURM_JOB_NAME/job-setup.sh # job configurations define software/data
# These come from job-setup.sh
: "${MAMMOTH:?❌ MAMMOTH is not set}"              # $PROJHOME/venv/mammoth
: "${CODE_DIR:?❌ CODE_DIR is not set}"            # $MAMMOTH_BASE/lib64/python3.10/site-packages/mammoth/bin
: "${MASTER_ARGS:?❌ MASTER_ARGS is not set}"      # 
: "${TRAIN_SCRIPT:?❌ TRAIN_SCRIPT is not set}"    #
: "${TRAIN_ARGS:?❌ TRAIN_ARGS is not set}"        #
: "${PATTERN:?❌ PATTERN is not set}"              #
: "${EXP_ID:?❌ EXP_ID is not set}"                # Must be equivalent to SLURM_JOB_NAME
: "${GUARD_TIME:?❌ GUARD_TIME is not set}"        #
: "${GUARD_MAX_NODES:?❌ GUARD_MAX_NODES not set}" #

source $PROJHOME/conf/distributed-setup.sh
# These come from $PROJHOME/conf/distributed-setup.sh
: "${CPUS_PER_TASK:?❌ CPUS_PER_TASK is not set}"
: "${GPUS_PER_NODE:?❌ GPUS_PER_NODE is not set}"
: "${GPU_BIND_FLAG:?❌ GPU_BIND_FLAG is not set}"
: "${DISTR_OPS:?❌ DISTR_OPS is not set}"          # this will be used in srun command

source $PROJHOME/conf/sanity-checks.sh             # check sbatch sanity
# This comes from $PROJHOME/conf/sanity-checks.sh
: "${SANITY_CHECKS_OK:?❌ SANITY_CHECKS_OK is not set}"

source $PROJHOME/conf/module-loads.sh              # load modules
source $MAMMOTH/bin/activate                       # enter the environment

source $PROJHOME/conf/comms-setup.sh
# These variables come from comms-setup.sh
: "${MASTER_PORT:?❌ MASTER_PORT is not set}"
: "${MASTER_ADDR:?❌ MASTER_ADDR is not set}"
: "${FI_PROVIDER:?❌ FI_PROVIDER is not set (e.g. cxi)}"
: "${FI_HMEM:?❌ FI_HMEM is not set (e.g., rocr)}"
: "${FI_LOG_LEVEL:?❌ FI_LOG_LEVEL is not set (e.g., warn)}"
: "${FI_LOG_PROV:?❌ FI_LOG_PROV is not set (e.g., cxi)}"
: "${NCCL_SOCKET_IFNAME:?❌ NCCL_SOCKET_IFNAME is not set (e.g., hsn0)}"

srun $DISTR_OPS $PROJHOME/conf/task-wrapper.sh    # Generic wrapper for python scripts; See job-setup.sh
