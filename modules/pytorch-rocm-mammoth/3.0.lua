local singName = 'lumi-pytorch-rocm-6.2.0-python-3.10-pytorch-v2.3.0.sif'
local pytorchVersion = '2.3.0'
local loadTxt = capture('cat /project/project_462000964/members/aylijyra/txt/load-pytorch-rocm-mammoth.txt')

help(string.format([[
ROCm-enabled PyTorch version %s for Python and MAMMOTH venv

]], pytorchVersion))

local singRoot = os.getenv('PROJHOME') or '/project/project_462000964/members/aylijyra' 

family("python_ml_env")

prepend_path('PATH', '/project/project_462000964/members/aylijyra/bin/wrappers')

setenv('SING_IMAGE', pathJoin(singRoot, 'images', singName))
setenv('NCCL_SOCKET_IFNAME', 'hsn')  -- use only high speed network

setenv('MIOPEN_DISABLE_CACHE', '1')  -- disable cache
setenv('MIOPEN_USER_DB_PATH', '')    -- disable userdb
--setenv('MIOPEN_USER_DB_PATH', '/tmp/miopen-userdb-' .. os.getenv('USER'))
--setenv('MIOPEN_CUSTOM_CACHE_DIR', '/tmp/miopen-cache-' .. os.getenv('USER'))

--setenv('CXI_FORK_SAFE', '1')  -- these seem to be needed for multi node (via Samuel Antao)
setenv('CXI_FORK_SAFE_HP', '1')
setenv('FI_CXI_DISABLE_CQ_HUGETLB', '1')

setenv('NCCL_NET_GDR_LEVEL', 'PHB')
setenv('RCCL_NET_GDR_LEVEL', 'PHB')       -- GPU Direct RDMA when GPUs & NICs share common Host Bridge
setenv('NCCL_ENABLE_DMABUF_SUPPORT', '1')

setenv('SLURM_MPI_TYPE', 'pmi2')

setenv('FI_HMEM','1')
setenv('FI_LOG_LEVEL','debug')
setenv('FI_PROVIDER','cxi')               -- This is only for Cray.  Avoid ambiguity with OFI
setenv('HSA_ENABLE_DEBUG','1')            -- We try this but may not be working
setenv('HSA_FORCE_FINE_GRAIN_PCIE','1')   -- Sets fine grained memory on
setenv('RCCL_DEBUG','INFO')
setenv('RCCL_ENABLE_DMABUF_PLUGIN','0')   -- Since containers lack device bindings for DMABUF
setenv('RCCL_MSCCL_ENABLE','1')           -- Already set in the LUMI supported container; just to emphasize
setenv('RCCL_TRACE_PLUGIN','1')

setenv('PLUGIN_DIR','/project/project_462000964/members/aylijyra/rccl-lib3.10') -- Insider the container

setenv('SINGULARITYENV_LD_LIBRARY_PATH', '/project/project_462000964/members/aylijyra/rccl-lib3.10:/usr/local/lib:/opt/rocm/lib/:/usr/local/lib/python3.11/dist-packages/faiss:/opt/cray/libfabric/1.15.2.0/lib64')
prepend_path('LD_LIBRARY_PATH','/project/project_462000964/members/aylijyra/rccl-lib3.10')

setenv('SING_FLAGS', '-B /opt/cray --bind /bin/ip:/bin/ip --bind /usr/lib64/libmnl.so.0:/usr/lib64/libmnl.so.0 \
  --bind /opt/cray/libfabric/1.15.2.0/bin/fi_info:/bin/fi_info ')
-- -B /opt/rocm/lib/librccl.so:/usr/local/lib/python3.10/dist-packages/torch/lib/librccl.so')

setenv('SINGULARITY_CONTAINLIBS', '/usr/lib64/libcxi.so.1,/usr/lib64/libjson-c.so.3,/opt/rocm/lib/librocm_smi64.so.6')

-- ROCm/PyTorch environment hook (so users can `eval $WITH_CONDA`)
setenv("WITH_CONDA", "source /opt/conda/etc/profile.d/conda.sh && conda activate pytorch")

if (mode() == "load") then
   LmodMessage(loadTxt)
end
