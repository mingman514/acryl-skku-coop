# Add helm repo
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

# Install GPU Operator
helm install --wait --generate-name \
       -n gpu-operator --create-namespace \
       nvidia/gpu-operator \
       --set driver.rdma.enabled=true \
       --set driver.rdma.useHostMofed=false \
       --set mig.strategy=mixed # [single|mixed] mixed when MIG mode is not enabled on all GPUs on a node
