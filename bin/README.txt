# SBATCH Frontmatters Bundle (LUMI & Puhti)

This bundle contains ready-to-use SBATCH "frontmatter" scripts for Mammoth-NLP training. 
They **do not** include `#SBATCH` resource discovery/launch logic; they end with:
```
source "$PROJHOME/bin/sbatch-tail.sh"
```
Your `sbatch-tail.sh` handles environment, sanity checks, and the actual `srun` pattern.

## Patterns

- **Slurm pattern** (1 task/GPU): `--ntasks-per-node=4`, `--gpus-per-task=1`.  
  GPU mapping is done inside `srun` via `local-setup.sh` (e.g., `*_VISIBLE_DEVICES=$SLURM_LOCALID`).

- **Torchrun pattern** (1 task/node): `--ntasks-per-node=1`, `--gpus-per-node=4`.  
  The script sets `export PATTERN=torchrun` before sourcing your tail. Your entrypoint should invoke `torchrun`.

## Partitions & Sizes

- **LUMI**: `dev-g` (≈10–15 min sanity), `small-g` (≤4 nodes jobs), `standard-g` (long jobs / multi-node).
- **Puhti**: `gputest` (short sanity), `gpu` (regular GPU partition).

## Variables you must set

- `$ACCOUNT` — your project/account.
- `$PROJHOME` — root path where `bin/sbatch-tail.sh` lives.
- (Optional) `$SYSTEM` — used by your tail scripts to pick LUMI vs Puhti behavior.

## Files

- `train-sbatch-<system>-<nodes>n<gpus>g-<time>.slurm` — Slurm pattern (1 task/GPU)
- `train-sbatch-<system>-tr-<nodes>n<gpus>g-<time>.slurm` — Torchrun pattern (1 task/node)
