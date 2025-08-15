# MIOpen cache (optional but recommended for perf)

export MIOPEN_DISABLE_CACHE=0
export MIOPEN_USER_DB_PATH=$PROJHOME/tmp/$USER-miopen-${SLURM_JOB_ID}


export CXI_FORK_SAFE_HP=1
export FI_CXI_DISABLE_CQ_HUGETLB=1
# CXI_FORK_SAFE_HP=1 and FI_CXI_DISABLE_CQ_HUGETLB=1 are fine (and commonly recommended on Slingshot to avoid fork/hugepage issues with PyTorch dataloaders/containers). Keep them.  docs.nersc.gov, lumi-supercomputer.github.io

# Set on NCCL debugging
export RCCL_DEBUG=INFO
export RCCL_DEBUG_SUBSYS=ALL              # This variable should not exist on LUMI, but try

# RCCL_MSCCL_ENABLE=1 enables MSCCL support in RCCL (ROCm Collective Communications Library).
# MSCCL (Multi-Source Collective Communication Library) is an advanced plugin mechanism that allows
# customized, optimized algorithms for collective communication operations like all-reduce,
# reduce-scatter, all-gather, etc., especially on multi-GPU AMD platforms like LUMI-G with MI250X.
export RCCL_MSCCL_ENABLE=1  # Already set in the LUMI supported container; just to emphasize
#
# VALIDATED!!  NCCL INFO RCCL_MSCCL_ENABLE set by environment to 1.



# FI_HMEM=1 allows MPI or libfabric-based applications to send/receive directly to/from
# GPU memory, without needing to copy data to the host first.
export FI_HMEM=rocr
# 
# VALIDATED!!  core:fi_param_get_():288<info> read string var hmem=1
# VALIDATED!!  core:ofi_hmem_set_iface_filter():296<warn> unknown HMEM interface specified in FI_HMEM, entry="1"
# VALIDATED!!  core:fi_param_get_():279<info> variable hmem_disable_p2p=<not set>
# 


# RCCL_ENABLE_DMABUF_PLUGIN=1 would enables inter-process GPU memory sharing using DMA-BUF
# But because we are in a container, /dev and some other bindings are likely not properly set.
# The following is just a reminder that there is more to ask about from LUST.  Not now.
# RCCL log file will report this is off, so no other debugging is needed.
# export RCCL_ENABLE_DMABUF_PLUGIN=0   # Since containers lack device bindings for DMABUF
unset RCCL_ENABLE_DMABUF_PLUGIN        # Since containers lack device bindings for DMABUF
#
# VALIDATED!!  NCCL INFO Dmabuf feature disabled without NCCL_DMABUF_ENABLE=1





# Setting FI_PROVIDER=cxi is critical for avoiding ofi_rxm-based fallbacks that might silently degrade performance.
# This is Cray-specific networking.   Prevents OFI from trying to auto-select from verbs, tcp, ofi_rxm, etc.
# One should use this when using libfabric-aware workloads like RCCL+OFI, or MPI+GPU buffers.
export FI_PROVIDER=cxi               # This is only for Cray.  Avoid ambiguity with OFI

# quiet the info spam (show only warnings/errors)
export FI_LOG_LEVEL=warn
# (optional) only log CXI provider if you do need logs
export FI_LOG_PROV=cxi

#
# VALIDATED!!  core:fi_param_get_():288<info> read string var provider=cxi
# VALIDATED!!  core:verify_filter_names():562<warn> provider cxi is unknown, misspelled or DL provider?
# ERROR: -> The cxi provider library (libfabric-cxi.so) is not in the default libfabric plugin directory
# ERROR: -> FI_PROVIDER_PATH isn't set and the default path does not include it
# ERROR: -> The libfabric version loaded does not include cxi (wrong version, container mismatch)
# VALIDATED!!  core:fi_param_get_():279<info> variable universe_size=<not set>
# VALIDATED!!  core:fi_param_get_():279<info> variable poll_fairness=<not set>
# VALIDATED!!  core:fi_param_get_():279<info> variable cxi_compat=<not set>
# VALIDATED!!  core:fi_param_get_():279<info> variable provider_path=<not set>
# VALIDATED!!  core:ofi_load_dl_prov():709<info> restricted_dl: setting FI_PROVIDER_PATH
#                      to "/opt/cray/libfabric/1.15.2.0/lib64/libfabric"
# You didn’t set FI_PROVIDER_PATH, so libfabric will use internal defaults.


# NCCL_SOCKET_IFNAME=hsn tells NCCL (and often RCCL too) to use the HSN (High-Speed Network) interface
#   — which is Slingshot on LUMI.  Without this, NCCL/RCCL might fall back to Ethernet or Infiniband-like
#   fallback interfaces (e.g., eth0, lo, etc.). One should use it especially for multi-node training or benchmarks.
#   This is used by NCCL (NVIDIA's GPU communication library) that is not in LUMI, not honored by RCCL.
#
# export NCCL_SOCKET_IFNAME=hsn0,hsn1,hsn2,hsn3     # ❌ No interfaces found starting with 'hsn0,hsn1,hsn2,hsn3'
# export NCCL_SOCKET_IFNAME=hsn0                    # ensure RCCL/NCCL uses Slingshot HSN; works at least minimally
export NCCL_SOCKET_IFNAME=hsn0,hsn1,hsn2,hsn3     # still in LUMI docs; rccl_text just does not recognize
#
# VALIDATED!!  "NCCL INFO NCCL_SOCKET_IFNAME set by environment to hsn"
# VALIDATED!!  "NCCL INFO Bootstrap : Using hsn0:10.253.26.197<0>"



# RCCL_ENABLE_OFI=1 is an environment variable that enables the OFI transport plugin in RCCL,
# AMD's ROCm-based equivalent of NCCL.  With this, you use libfabric to talk over the network
# (e.g., Cray Slingshot via cxi).  You gain access to high-performance, RDMA-capable inter-node
# GPU communication.  You can communicate directly between GPUs across nodes (if combined with
# other ROCm/libfabric features).  This is essential for multi-node GPU training on LUMI-G
# (MI250X GPUs + Slingshot). --- I am very surprised that this option is not turned on by the
# container lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif although the container
# boast to provide Slingshot 11 enabling.
# RCCL_ENABLE_OFI=1  tells RCCL (the ROCm/NCCL equivalent) to use the OFI (OpenFabrics Interfaces)
# communication backend instead of the default IPC/SHMEM-based or ring/allreduce communication engines.
# I have managed to set it on using an old aws-ofi-rccl module (< eb) and its librccl-net.so plugin.
# Now experiencing difficulties to set it on with the container.
# The container seems to have directory /opt/aws-ofi-rccl that conatins the default plugin librccl-net.so
# But RCCL seem so be searching for librccl-net-ofi.so instead and fails.
# librccl-net.so should be renamed as librccl-net-ofi.so and
# a symlink librccl-net.so -> librccl-net-ofi.so should be set
export RCCL_TRACE_PLUGIN=1
export PLUGIN_DIR=$PROJHOME/rccl-lib3.10   # This where I found it insider the container
# This directory contains:
#    librccl-net-ofi.so -> /opt/aws-ofi-rccl/librccl-net.so
#    librccl-net.so -> /opt/aws-ofi-rccl/librccl-net.so
export LD_LIBRARY_PATH=$PLUGIN_DIR:$LD_LIBRARY_PATH
# The last line ensures that the dynamic linker can find any dependent .so files required
# by the plugin (e.g., libfabric.so, etc.).
#
# There are various variants of the RCCN Net plugin.  The default is OFI and should be used.
# export RCCL_NET_PLUGIN=ofi     # uses librccl-net-ofi.so; without it looks for the default
# Do not set this unless the PLUGIN_DIR contains librccl-net-ofi.so.
#
# VALIDATED!!  NCCL INFO Plugin name set by env to librccl-net-ofi.so
# VALIDATED!!  NCCL INFO NET/Plugin: Failed to find ncclNetPlugin_v8 symbol.
# VALIDATED!!  NCCL INFO NET/Plugin: Loaded net plugin AWS Libfabric (v5)
# VALIDATED!!  NCCL INFO NET/Plugin: Failed to find ncclCollNetPlugin_v8 symbol.
# VALIDATED!!  NCCL INFO NET/Plugin: Failed to find ncclCollNetPlugin symbol (>= v5).
# VALIDATED!!  ncclCollNetPlugin symbols v4 and lower are not supported.
# VALIDATED!!  NCCL INFO NET/OFI Using aws-ofi-rccl 1.4.0
# VALIDATED!!  NCCL INFO NET/OFI Setting FI_EFA_FORK_SAFE environment variable to 1



# RCCL_NET_GDR_LEVEL=PHB controls when RCCL should use GPU Direct RDMA (GDR).
# PHB: use GDR only if GPU and NIC share the same PCIe Host Bridge
# One should probably use this, but cautiously.
# On LUMI-G, AMD MI250X GPUs are connected via xGMI, and the Slingshot NIC may or may not share
# the same host bridge with your assigned GPU. Using PHB is a safe option — it allows GDR only when safe.
export RCCL_NET_GDR_LEVEL=PHB              # GPU Direct RDMA when GPUs & NICs share common Host Bridge
export NCCL_NET_GDR_LEVEL=PHB              # GPU Direct RDMA when GPUs & NICs share common Host Bridge
#
# NOT VALIDATED: ChatGPT explains this: the variable is not directly observable from standard RCCL logs.



# HSA_FORCE_FINE_GRAIN_PCIE=1 is for the ROCm runtime and igt controls the memory allocation
# mode over PCIe between host and GPU.  When set to 1, memory mapped over PCIe is fine-grained,
# meaning: Shared memory behaves more like unified memory with more seamless CPU-GPU coherence.
# It enables true zero-copy transfers, useful for things like vllm, tensor parallelism, etc.

# ONLY IF YOU NEED THIS:
# export HSA_FORCE_FINE_GRAIN_PCIE=1        # set fine grained memory on

#   This is silent, but essential for FI_HMEM=1 and RCCL over OFI.
# export HSA_ENABLE_DEBUG=1                 # we try this but may not be working
unset HSA_ENABLE_DEBUG                      # less log noise

#   HSA_ENABLE_DEBUG=1 is harmless—keep it if you’d like, but expect no output unless
#   you are using a ROCm developer image.
# export HSA_TOOLS_LIB=libhsakmt-debug.so   # generally not available in production use
#   Remove HSA_TOOLS_LIB unless you really need low-level tracing.
#   Containers built for production normally do not ship libhsakmt-debug.so;
#   the warning is harmless but clutters your logs.
# NOT VALIDATED: ChatGPT explains this: the variable is not directly observable from standard RCCL logs.
# Is it not directly observable in logs. This is handled internally by ROCm’s memory allocator
# (roc::HostMemoryManager), and does not emit any standard log message.  You can infer it if
# fine-grained buffers behave correctly — e.g., host-allocated buffers used in GPU kernels
# without explicit synchronization.


# For debugging:
# echo -----------------------------
# env | egrep 'RCCL_|HSA_|FI_|PLUGIN_|NCCL_'
# echo -----------------------------

