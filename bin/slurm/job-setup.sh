# job-setup.sh
echo "experiment-specific setup (job-setup.sh) ..."
(return 0 2>/dev/null) || { echo "❌ Please source this script instead of executing it."; exit 1; }
set -euo pipefail  # make failures fatal and undefined vars errors (optional)
: "${SLURM_JOB_NAME:?❌ SLURM_JOB_NAME is not set}" 
: "${MASTER_ADDR:?❌ MASTER_ADDR is not set}"
: "${MASTER_PORT:?❌ MASTER_PORT is not set}"

export EXP_ID=mammoth-lumi-1n1g-1m
##########################
# SLURM_JOB_NAME is EXP_ID
##########################
# Require both to be set
: "${EXP_ID:?❌ EXP_ID is empty or unset}"
if [[ -z "${SLURM_JOB_NAME:-}" ]]; then
  # fallback to scheduler record if env missing
  SLURM_JOB_NAME="$(scontrol show -d job "${SLURM_JOB_ID:?}" | awk -F'[= ]' '/JobName=/{print $2; exit}')" || true
fi
: "${SLURM_JOB_NAME:?❌ SLURM_JOB_NAME is empty or unset}"
if [[ "$SLURM_JOB_NAME" != "$EXP_ID" ]]; then 
  echo "❌ Name mismatch: SLURM_JOB_NAME='$SLURM_JOB_NAME' ≠ EXP_ID='$EXP_ID'."
  echo "   Fix with: sbatch --job-name \"$EXP_ID\" …  or export EXP_ID='$SLURM_JOB_NAME'."
  exit 1
fi

# avoid spaces in the file names
JOB_DIR=$PROJDATA/trains/$SLURM_JOB_NAME
LOG_DIR=$JOB_DIR/logs
CONF_DIR=$JOB_DIR/conf
SAVE_DIR=$JOB_DIR/models
TENSOR_DIR="${LOG_DIR}/${EXP_ID}"
CONF_FILE="${CONF_DIR}/BEM_models/BEM_encoder_shared.yml"
CONF_FILE="${CONF_DIR}/europarl-1node-4gpu.yml"
CONF_FILE="${CONF_DIR}/simple.yml"
SAVE_FILE="${SAVE_DIR}/${EXP_ID}"
MAMMOTH=$PROJHOME/venv/mammoth           # place to find mammoth
CODE_DIR=$MAMMOTH/lib64/python3.10/site-packages/mammoth/bin
TRAIN_SCRIPT="$CODE_DIR/train.py"
export MAMMOTH LOG_DIR TRAIN_SCRIPT

f="$TRAIN_SCRIPT"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }
d="$CONF_DIR"; [[ -d "$d" && -r "$d" && -x "$d" ]] || { echo "❌ Bad dir: $d" >&2; exit 1; }
f="$CONF_FILE"; [[ -s "$f" ]] || { echo "❌ Missing/empty: $f" >&2; exit 1; }
d="$JOB_DIR";  [[ -d "$d" && -r "$d" && -x "$d" ]] || { echo "❌ Bad dir: $d" >&2; exit 1; }
d="$MAMMOTH";  [[ -d "$d" && -r "$d" && -x "$d" ]] || { echo "❌ Bad dir: $d" >&2; exit 1; }
d="$CODE_DIR"; [[ -d "$d" && -r "$d" && -x "$d" ]] || { echo "❌ Bad dir: $d" >&2; exit 1; }
mkdir -p "$TENSOR_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$SAVE_DIR"

export TRAIN_ARGS="-config ${CONF_FILE} -tensorboard -tensorboard_log_dir ${TENSOR_DIR} -save_model ${SAVE_FILE}"
    #--reset_optim states \
    #--train_from   ARR_Embeddingless/models/BEM_encoder_shared_1m/42/models/model_step_90000
  
export PATTERN="slurm"  # slurm or torchrun
export MASTER_ARGS="-master_addr ${MASTER_ADDR} -master_port ${MASTER_PORT}"
export GUARD_MAX_NODES=4  # do not change
# Guard threshold (default 24h). Accepts same Slurm formats.
# Set a different guard with export GUARD_TIME="12:00:00" (12h) or GUARD_TIME="2-00:00:00" (2 days).
export GUARD_TIME="${GUARD_TIME:-0-01:00:00}"

echo ==============================================
echo " EXP_ID           : $EXP_ID"
echo " SLURM_JOB_NAME   : $SLURM_JOB_NAME"
echo " local JOB_DIR    : $JOB_DIR"
echo " local CONF_DIR   : $CONF_DIR"
echo " local CONF_FILE  : $CONF_FILE"
echo " LOG_DIR          : $LOG_DIR"
echo " local SAVE_DIR   : $SAVE_DIR"
echo " local SAVE_FILE  : $SAVE_FILE"
echo " local TENSOR_DIR : $TENSOR_DIR"
echo " MAMMOTH          : $MAMMOTH"
echo " local CODE_DIR   : $CODE_DIR"
echo " TRAIN_SCRIPT     : $TRAIN_SCRIPT"
echo " TRAIN_ARGS       : $TRAIN_ARGS"
echo " MASTER_ARGS      : $MASTER_ARGS"
echo " PATTERN          : $PATTERN"
echo " GUARD_MAX_NODES  : $GUARD_MAX_NODES"
echo " GUARD_TIME       : $GUARD_TIME"
echo ==============================================
