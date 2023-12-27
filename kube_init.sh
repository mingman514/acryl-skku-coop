TARGET_DIR=~
TARGET_IP=10.0.104.2   # RNIC IP


RNIC_INTERFACE=$(ip -o addr show | awk "/inet $TARGET_IP/" | awk '{print $2}')
echo "RNIC interface is [$RNIC_INTERFACE]"
sleep 3

msg() {
    message="$1"
    border="========================================"

    echo ""
    echo "$border"
    echo "$message"
    echo "$border"
    echo ""
}

# Remove
sudo rm -r /etc/cni/net.d

# Restart services
echo "Restart docker"
sudo systemctl restart docker
echo "Restart containerd"
sudo systemctl restart containerd
echo "Restart kubelet"
sudo systemctl restart kubelet

# K8S init
msg "Init kubernetes cluster"
sleep 2
sudo kubeadm init \
	--pod-network-cidr=20.0.1.0/24 \
	--kubernetes-version 1.27.0 \
	--cri-socket unix://var/run/containerd/containerd.sock

mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):netsys $HOME/.kube/config


# Taint control plane
msg "Taint control plane"
kubectl taint nodes $(hostname) node-role.kubernetes.io/control-plane-


# CNI
msg "Create CNI"
sleep 2
kubectl apply -f https://docs.projectcalico.org/v3.23/manifests/calico.yaml

echo "** Wait until CNI Pod Running"
while true; do
    pod_status=$(kubectl get pod -n kube-system -l k8s-app=calico-kube-controllers --no-headers=true --output=jsonpath='{.items[*].status.phase}')

    if [ "$pod_status" == "Running" ]; then
        echo "Pod is now running and ready."
        break
    elif [ "$pod_status" == "Pending" ]; then
        echo "Pod is still pending, waiting..."
    elif [ -z "$pod_status" ]; then
        echo "Pod not found, waiting..."
    else
        echo "Pod is in an unexpected state: $pod_status"
        exit 1
    fi
    sleep 2
done


# Nvidia device plugin
msg "Create nvidia device plugin"
./scripts/install-nvidia-device-plugin.sh
#kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.3/nvidia-device-plugin.yml

# RDMA device plugin
#msg "Create rdma device plugin"
#RDMA_DEV_PLUGIN_DIR="$TARGET_DIR/k8s-rdma-shared-dev-plugin"
#cd $TARGET_DIR
#if [ ! -d "k8s-rdma-shared-dev-plugin" ]; then
#  echo "k8s-rdma-shared-dev-plugin folder not found."
#  git clone https://github.com/Mellanox/k8s-rdma-shared-dev-plugin.git
#fi
#cd $RDMA_DEV_PLUGIN_DIR/deployment/k8s/base
#kubectl apply -k .
#cd ~
#
## macvlan
#sudo cp macvlan.conf /etc/cni/net.d/00-macvlan.conf
#sudo apt install -y jq
#jq ".master = $RNIC_INTERFACE" macvlan.conf > tmp_macvlan.conf
#mv tmp_macvlan.conf macvlan.conf

msg "Init K8S Cluster Done"
