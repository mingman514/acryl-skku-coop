TARGET_DIR=~
TARGET_IP=192.168.1.1   # RNIC IP

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

wait_until_pod_running_by_label() {
    while true; do
        pod_status=$(kubectl get pod -n kube-system -l $1 --no-headers=true --output=jsonpath='{.items[*].status.phase}')
        sleep 2
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
    done
}

sudo swapoff -a

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
	--kubernetes-version 1.27.10 \
	--cri-socket unix://var/run/containerd/containerd.sock
	#--pod-network-cidr=20.0.1.0/24 \

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
wait_until_pod_running_by_label "k8s-app=calico-kube-controllers"

# Nvidia device plugin
msg "Create nvidia device plugin"
sleep 2
./scripts/install-nvidia-device-plugin.sh

# Nvidia Network Operator (including rdmaSharedDevicePlugin, multus, etc.)
msg "Create nvidia network operator"
./scripts/install-nvidia-network-operator.sh

## macvlan
#msg "Setting macvlan network"
#sudo apt install -y jq ipcalc
#cp templates/macvlan_network_template.yaml macvlan_network.yaml
#RDMA_IFACE=$RNIC_INTERFACE
#RDMA_SUBNET_CIDR=$(ipcalc -b ${TARGET_IP%:*} | grep Network | awk '{print $2}')
#RDMA_SUBNET_NETMASK=$(ipcalc -b ${TARGET_IP%:*} | grep Netmask | awk '{print $4}')
#RDMA_EXCLUDES=${RDMA_SUBNET_CIDR/%$RDMA_SUBNET_NETMASK/25}
#sed -i -e "s|RDMA_INTERFACE|$RDMA_IFACE|" -e "s|RDMA_SUBNET_CIDR|$RDMA_SUBNET_CIDR|" -e "s|RDMA_SUBNET_EXCLUDES|$RDMA_EXCLUDES|" macvlan_network.yaml
#jq ".master = $RNIC_INTERFACE" macvlan.conf > tmp_macvlan.conf
#mv tmp_macvlan.conf macvlan.conf
#kubectl apply -f macvlan_network.yaml

msg "Init K8S Cluster Done"

echo "Now let Worker nodes join this cluster with following command:"
echo ""
sudo kubeadm token create --print-join-command
