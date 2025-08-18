

# WORLD_SIZE/RANK/LOCAL_RANK: 
# export WORLD_SIZE=$SLURM_NPROCS
# export RANK=$SLURM_PROCID
if (( is_torchrun )); then
  # torchrun computes these per subprocess; exporting is harmless but not required
  export WORLD_SIZE=$(( NODES * (NPROC_PER_NODE:-$GPUS_PER_NODE) ))
  export RANK=${SLURM_PROCID:-0}
  export LOCAL_RANK=${SLURM_LOCALID:-0}
else
  # Slurm-spawn: 1 task/GPU
  export WORLD_SIZE="$NTASKS"
  export RANK="${SLURM_PROCID:?}"
  export LOCAL_RANK="${SLURM_LOCALID:?}"
fi


# ---------- per-node caches / threads ----------
# MIOpen cache (AMD only; harmless elsewhere)
# export MIOPEN_USER_DB_PATH="${MIOPEN_USER_DB_PATH:-/tmp/$USER-miopen-${SLURM_JOB_ID}-${SLURM_NODEID:-0}}"
# export MIOPEN_CUSTOM_CACHE_DIR="${MIOPEN_CUSTOM_CACHE_DIR:-$MIOPEN_USER_DB_PATH}"
export MIOPEN_USER_DB_PATH="/tmp/$(whoami)-miopen-cache-$SLURM_NODEID"
export MIOPEN_CUSTOM_CACHE_DIR=\$MIOPEN_USER_DB_PATH
mkdir -p "$MIOPEN_USER_DB_PATH" || true
# Match OpenMP threads to cpus-per-task (data loaders often separate; this is safe)
if [[ -n "${SLURM_CPUS_PER_TASK:-}" && "${SLURM_CPUS_PER_TASK}" -gt 0 ]]; then
  export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
  export OMP_PROC_BIND="${OMP_PROC_BIND:-close}"
  export OMP_PLACES="${OMP_PLACES:-cores}"
fi



