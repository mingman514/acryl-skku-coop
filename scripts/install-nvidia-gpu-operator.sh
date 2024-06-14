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
       
# driver.enabled: false when using pre-installed driver
# driver.rdma.enabled: nvidia-peermem kernel module
# mig.strategy: [single|mixed] mixed when MIG mode is not enabled on all GPUs on a node
