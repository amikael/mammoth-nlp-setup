echo Setting up distributed computing environment ...
(return 0 2>/dev/null) || { echo "❌ Please source this script instead of executing it."; exit 1; }
: "${SYSTEM:?❌ SYSTEM is not set}"

# Do not hardcode CUDA_VISIBLE_DEVICES=0,1,2…. Let binding happen per task.

if [[ -n "${SLURM_JOB_NUM_NODES:-}" ]]; then
  NODES="$SLURM_JOB_NUM_NODES"
else
  JOBINFO="$(scontrol show -d job ${SLURM_JOB_ID:?})"
  NODES="$(awk -F'[= ]' '/NumNodes=/{print $2; exit}' <<<"$JOBINFO")"
fi
: "${NODES:?could not determine node count}"

case "$SYSTEM" in
  lumi)
      # On LUMI (AMD/ROCm), Slurm’s gpu-bind may be a no-op;
      # we bind via HIP/ROCR_VISIBLE_DEVICES using SLURM_LOCALID
      # (as in your world-setup).
      
      : "${GPUS_PER_NODE:=8}"     # policy default 8 GCDs per LUMI-G node
      : "${CPUS_PER_TASK:=7}"     # policy default (≈56 cores / 8 GCDs)
      
      # choose either way:
      
      CPU_BIND_OPS="--cpu-bind=cores"  # rely on HIP/ROCR_VISIBLE_DEVICES=$SLURM_LOCALID *inside* srun.
      # Just use --cpu-bind=cores and map tasks→GCDs via HIP/ROCR_VISIBLE_DEVICES=$SLURM_LOCALID
      # inside srun.

      # Optional: if you want the exact topology mapping from the LUMI slides, use
      # the provided CPU mask string instead of --cpu-bind=cores. It’s a fine-tuning, not a requirement.
      #  LUMI_CPU_MASKS=mask_cpu:0xfe000000000000,0xfe00000000000000,0xfe0000,0xfe000000,0xfe,0xfe00,0xfe00000000,0xfe0000000000
      #  CPU_BIND_OPS="--cpu-bind=$LUMI_CPU_MASKS" # the slide’s exact LUMI masks
      # Slide: https://462000265.lumidata.eu/ai-20250204/files/LUMI-ai-20250204-09-Extreme_scale_AI.pdf

      GPU_BIND_FLAG=""            # do NOT use --gpu-bind on ROCm/LUMI CPU masks?
      # Put them under a *CPU* bind var (see note below)
      # --gpu-bind is an NVIDIA feature; on LUMI you want CPU binding, not GPU binding.
      
      # Never export *VISIBLE_DEVICES in the batch script before srun.
      # Outside srun there’s no SLURM_LOCALID, you’ll end up exposing all GPUs to every task
      ;;
  
  puhti)
      # --gpu-bind=closest is great on NVIDIA (Puhti/Mahti).
      : "${GPUS_PER_NODE:=4}"
      : "${CPUS_PER_TASK:=10}"            # 40 cores / 4 GPUs
      CPU_BIND_OPS=""
      GPU_BIND_FLAG="--gpu-bind=closest"  # NVIDIA-only helper (Puhti/Mahti): bind task to the PCIe-closest GPU
      ;;
  
  mahti)
      : "${GPUS_PER_NODE:=4}"
      : "${CPUS_PER_TASK:=8}"             # start with 8; can go higher after profiling
      CPU_BIND_OPS=""
      GPU_BIND_FLAG="--gpu-bind=closest"  # NVIDIA-only helper (Puhti/Mahti): bind task to the PCIe-closest GPU 
      ;;
esac
export GPUS_PER_NODE
export CPUS_PER_TASK

# On NVIDIA (Puhti/Mahti), pass --gpu-bind=closest to srun so the task is placed near “its” GPU
# On LUMI (ROCm), rely on HIP/ROCR_VISIBLE_DEVICES=$SLURM_LOCALID + --cpu-bind=cores

export DISTR_OPS="--unbuffered --nodes=$NODES --ntasks-per-node=$GPUS_PER_NODE \
	 --gpus-per-task=1 --cpus-per-task=$CPUS_PER_TASK $CPU_BIND_OPS $GPU_BIND_FLAG"

######################################################
# ---------- torchrun rendezvous (MASTER_*) ----------
######################################################
# These are safe to set once per job.
# Use first hostname from nodelist, avoid plain `hostname` (not always in containers)
MASTER_ADDR="$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n1)"
# Pick a port that collides less: 29500 + (JOBID mod 1000)
MASTER_PORT="${MASTER_PORT:-$((29500 + SLURM_JOB_ID % 1000))}"

echo ==============================================
echo " SYSTEM              : $SYSTEM"
echo " SLURM_JOB_NUM_NODES : $SLURM_JOB_NUM_NODES"
echo " local NODES         : $NODES"
echo " GPUS_PER_NODE       : $GPUS_PER_NODE"
echo " CPUS_PER_TASK       : $CPUS_PER_TASK"
echo " local CPU_BIND_OPS  : $CPU_BIND_OPS"
echo " local GPU_BIND_FLAG : $GPU_BIND_FLAG"
echo " DISTR_OPS           : $DISTR_OPS"
echo " MASTER_PORT         : $MASTER_PORT"
echo " MASTER_ADDR         : $MASTER_ADDR"
echo ==============================================

