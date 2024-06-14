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
# There are chances that calico autodetects a wrong interface, so use the first internal ip for each kubernetes node.
kubectl set env daemonset/calico-node -n kube-system IP_AUTODETECTION_METHOD=kubernetes-internal-ip

echo "** Wait until CNI Pod Running"
wait_until_pod_running_by_label "k8s-app=calico-kube-controllers"

# Nvidia device plugin
msg "Create nvidia device plugin"
sleep 2
./scripts/install-nvidia-gpu-operator.sh

# Nvidia Network Operator (including rdmaSharedDevicePlugin, multus, etc.)
msg "Create nvidia network operator"
sleep 2
./scripts/install-nvidia-network-operator.sh

msg "Init K8S Cluster Done"
echo "Now let Worker nodes join this cluster with following command:"
echo ""
kubeadm token create --print-join-command
