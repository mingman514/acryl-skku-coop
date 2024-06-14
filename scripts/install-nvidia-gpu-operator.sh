# Add helm repo
helm repo add nvidia-ngc https://helm.ngc.nvidia.com/nvidia --force-update
helm repo update

# Install GPU Operator
helm install --wait --generate-name \
       -n gpu-operator --create-namespace \
       nvidia-ngc/gpu-operator \
       --set driver.enabled=true \
       --set driver.rdma.enabled=true \
       --set driver.rdma.useHostMofed=true \
       --set mig.strategy=mixed
       
# driver.enabled: false when using pre-installed driver (false일 경우 gpudirect rdma를 위해 직접 nvidia_peermem 모듈을 호스트에서 실행해야 함)
# driver.rdma.enabled: nvidia-peermem kernel module
# mig.strategy: [single|mixed] mixed when MIG mode is not enabled on all GPUs on a node
