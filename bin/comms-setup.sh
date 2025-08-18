echo comms-setup.sh...

set -euo pipefail
(return 0 2>/dev/null) || { echo "❌ Please source this script instead of executing it."; exit 1; }
: "${SYSTEM:?❌ SYSTEM is not set}"
: "${SLURM_JOB_ID:?❌ SLURM_JOB_ID is not set}"
: "${SLURM_JOB_NODELIST:?❌ SLURM_JOB_NODELIST is not set}"

# ---------- cluster-specific comm knobs (minimal, safe) ----------

if [[ "$SYSTEM" == "lumi" ]]; then
  # Slingshot/CXI + ROCm: quiet & correct HMEM
  export FI_PROVIDER="${FI_PROVIDER:-cxi}"
  export FI_HMEM="${FI_HMEM:-rocr}"
  export FI_LOG_LEVEL="${FI_LOG_LEVEL:-warn}"
  export FI_LOG_PROV="${FI_LOG_PROV:-cxi}"
  # Bootstrap interface for RCCL (choose a single HSN to avoid noise)
  export NCCL_SOCKET_IFNAME=hsn0,hsn1,hsn2,hsn3
  export NCCL_SOCKET_IFNAME="${NCCL_SOCKET_IFNAME:-hsn0}"
  # Keep DMABUF off unless you validated your stack
  unset NCCL_DMABUF_ENABLE  # intentionally unset by default

  export NCCL_NET_GDR_LEVEL=PHB
  
  # Cray HPE recommended: can sometimes be detrimental for performance at small
  # scale but useful to improve stability at large scale.
  #
  # Quoted by Samuel from AMD: 18 Aug 2025
  # export  FI_MR_CACHE_MONITOR=userfaultfd
  # export  FI_CXI_DEFAULT_CQ_SIZE=131072
  # export  FI_CXI_RX_MATCH_MODE=software
  # export  FI_CXI_RDZV_PROTO=alt_read
fi

###############################################################################
# --- RCCL net plugin presence sanity check -----------------------------------
###############################################################################
# We want BOTH names available because different RCCL builds may dlopen either:
#   - librccl-net-ofi.so  (OFI provider plugin)
#   - librccl-net.so      (generic/legacy name some builds still look for)
#
# Search order: PLUGIN_DIR (if set) first, then LD_LIBRARY_PATH entries.
_rccl_find_in_path() {
  local libname="$1"
  local found=""
  local -a dirs=()

  # Build ordered search list
  [[ -n "${PLUGIN_DIR:-}" ]] && dirs+=("$PLUGIN_DIR")
  if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
    # Split LD_LIBRARY_PATH on ':'
    IFS=':' read -r -a _ldirs <<<"$LD_LIBRARY_PATH"
    dirs+=("${_ldirs[@]}")
  fi

  # Walk the dirs; accept exact .so or versioned (e.g., .so.1)
  for d in "${dirs[@]}"; do
    [[ -z "$d" ]] && d="."      # empty element means current dir
    # exact
    if [[ -f "$d/$libname" ]]; then
      found="$d/$libname"; break
    fi
    # versioned
    if compgen -G "$d/$libname.*" >/dev/null 2>&1; then
      found="$(ls -1 "$d/$libname".* 2>/dev/null | head -n1)"; break
    fi
  done

  [[ -n "$found" ]] && printf '%s\n' "$found"
}

_missing=0
declare -A _FOUND=()
for _lib in librccl-net-ofi.so librccl-net.so; do
  _path="$(_rccl_find_in_path "$_lib" || true)"
  if [[ -n "$_path" ]]; then
    echo "OK[rccl-plugin]: found $_lib → $_path"
    _FOUND["$_lib"]="$-_path"
  else
    echo "❌ MISSING: $_lib not found in PLUGIN_DIR/LD_LIBRARY_PATH." >&2
    _missing=1
  fi
done

if (( _missing )); then
  echo "HINT:" >&2
  echo "  • Put both files in one directory (e.g. \$PLUGIN_DIR) and prepend it to LD_LIBRARY_PATH:" >&2
  echo "      export PLUGIN_DIR=/path/to/rccl-plugins" >&2
  echo "      export LD_LIBRARY_PATH=\"\$PLUGIN_DIR:\${LD_LIBRARY_PATH:-}\"" >&2
  echo "  • If you only have one of them, make a symlink so both names exist in the same dir:" >&2
  echo "      cd /path/to/rccl-plugins" >&2
  echo "      ln -s librccl-net-ofi.so librccl-net.so   # or vice versa" >&2
  exit 1
  # User experience:
  # /project/project_462000964/members/aylijyra/rccl-lib3.10:
  #   librccl-net-ofi.so -> /opt/aws-ofi-rccl/librccl-net.so
  #   librccl-net.so     -> /opt/aws-ofi-rccl/librccl-net.so
  # Note that /opt/aws-ofi-rccl/ exists only in containers, such
  # as lumi-pytorch-rocm-6.2.4-python-3.12-pytorch-v2.7.0.sif
  # in /appl/local/containers/sif-images
fi

# Optional: smoke-test dlopen so we fail early on missing deps
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import ctypes, sys, os
libs = []
# Take names from env to keep the bash search result ordering if you want;
# otherwise, just retest by names—bash already printed locations above.
for name in ("librccl-net-ofi.so", "librccl-net.so"):
    # try LD paths implicitly first; if that fails, fall back to explicit search
    try:
        ctypes.CDLL(name)  # rely on loader search path
        print(f"OK[dlopen]: {name}")
    except OSError as e:
        print(f"❌ dlopen failed for {name}: {e}", file=sys.stderr)
        sys.exit(1)
PY
fi
# --- end RCCL plugin sanity ---------------------------------------------------

echo ==============================================
echo " SLURM_JOB_ID              : $SLURM_JOB_ID"
echo " SLURM_JOB_NODELIST        : $SLURM_JOB_NODELIST"
echo " MASTER_PORT               : $MASTER_PORT"
echo " MASTER_ADDR (29xxx)       : $MASTER_ADDR"
echo " RDZV_ARGS                 : $RDZV_ARGS"
echo " FI_PROVIDER (cxi)         : $FI_PROVIDER"
echo " FI_HMEM (rocr)            : $FI_HMEM"
echo " FI_LOG_LEVEL (warn)       : $FI_LOG_LEVEL"
echo " FI_LOG_PROV (cxi)         : $FI_LOG_PROV"
echo " NCCL_SOCKET_IFNAME (hsn0) : $NCCL_SOCKET_IFNAME"
echo " NCCL_NET_GDR_LEVEL        : $NCCL_NET_GDR_LEVEL"
echo ==============================================
