#!/usr/bin/env -S -u BASH_ENV bash --noprofile --norc
echo running task-wrapper.sh...

# Use -u for Python, not for the bash wrapper.
# In bash, -u means treat unset vars as an error (nounset). It has
# nothing to do with buffering. It’s still a good safety flag for the
# wrapper, but use it via:
set -euo pipefail

# Local setups 
f="$PROJHOME/bin/local-setup.sh"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }
source $PROJHOME/bin/local-setup.sh

echo "back to task-wrapper...continuing..."

set -euo pipefail
: "${SLURM_PROCID:?❌ SLURM_PROCID is not set - must be run insider srun}"
: "${SLURM_NNODES:?❌ SLURM_NNODES is not set}" # jobs of the current job step
: "${SLURM_NODEID:?❌ SLURM_NODEID is not set}" 
: "${SLURM_JOB_NODELIST:?❌ SLURM_JOB_NODELIST is not set}" 
: "${GPUS_PER_NODE:?❌ GPUS_PER_NODE is not set}"
: "${SYSTEM:?❌ SYSTEM is not set}"
: "${PATTERN:?❌ PATTERN is not set}"
: "${EXP_ID:?❌ EXP_ID is not set}"
: "${LOG_DIR:?❌ LOG_DIR is not set}"
: "${MASTER_ADDR:?❌ MASTER_ADDR is not set}"
: "${MASTER_PORT:?❌ MASTER_PORT is not set}"
: "${MASTER_ARGS:?❌ MASTER_ARGS is not set}"
: "${TRAIN_SCRIPT:?❌ TRAIN_SCRIPT is not set}"
: "${TRAIN_ARGS:?❌ TRAIN_ARGS is not set}"

# Set NPROC_PER_NODE
: "${NPROC_PER_NODE:=${GPUS_PER_NODE:-1}}"	

print_affinity # Optional: print CPU/GPU binding sanity

trap stop_monitor EXIT  # clean with trap
start_monitor  # Start monitor (comment out if you don’t want it)

# python/pytorch uses MASTER_ARGS (already set) but torchrun uses RDZV_ARGS:
RDZV_ARGS="--rdzv_backend=c10d --rdzv_endpoint=${MASTER_ADDR}:${MASTER_PORT}"

case "${PATTERN:-slurm}" in
    slurm)
	RUNTIME="python"
      	RUNTIME_ARGS="-u"
	POST_ARGS="--node_rank ${SLURM_NODEID:-0} ${MASTER_ARGS}"
	;;
    torchrun)
	RUNTIME="torchrun"
    	RUNTIME_ARGS="--node_rank ${SLURM_NODEID:-0} ${RDZV_ARGS} \
		      --nnodes=${SLURM_NNODES:?} --nproc_per_node=${NPROC_PER_NODE} "
	POST_ARGS=""
	;;
esac

echo ==============================================
echo " SLURM_NODEID (node_rank)  : $SLURM_NODEID"
echo " GPUS_PER_NODE             : $GPUS_PER_NODE"
echo " NPROC_PER_NODE            : $NPROC_PER_NODE"
echo " SLURM_NNODES              : $SLURM_NNODES"
echo " PATTERN                   : $PATTERN"
echo " SLURM_JOB_NODELIST        : $SLURM_JOB_NODELIST"
echo " RUNTIME                   : $RUNTIME"
echo " RUNTIME_ARGS              : $RUNTIME_ARGS"
echo " RDZV_ARGS                 : $RDZV_ARGS"
echo " MASTER_ARGS               : $MASTER_ARGS"
echo " TRAIN_SCRIPT              : $TRAIN_SCRIPT"
echo " TRAIN_ARGS                : $TRAIN_ARGS"
echo " POST_ARGS                 : $POST_ARGS"
echo ==============================================
echo "${RUNTIME} ${RUNTIME_ARGS} ${TRAIN_SCRIPT} ${TRAIN_ARGS} ${POST_ARGS} ..."

exec "${RUNTIME} ${RUNTIME_ARGS} ${TRAIN_SCRIPT} ${TRAIN_ARGS} ${POST_ARGS}"


python -u \
  $PROJHOME/venv/mammoth/lib64/python3.10/site-packages/mammoth/bin/train.py \
  -config $PROJDATA/trains/mammoth-lumi-1n1g-1m/conf/simple.yml \
  -tensorboard -tensorboard_log_dir $PROJDATA/trains/mammoth-lumi-1n1g-1m/logs/mammoth-lumi-1n1g-1m \
  -save_model $PROJDATA/trains/mammoth-lumi-1n1g-1m/models/mammoth-lumi-1n1g-1m \
  --node_rank 0 -master_addr nid007954 -master_port 29602


