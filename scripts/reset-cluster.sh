helm uninstall network-operator -n network-operator
sudo kubeadm reset -f

# Remove
sudo rm -r /etc/cni/net.d

# Restart services
echo "Restart docker"
sudo systemctl restart docker
echo "Restart containerd"
sudo systemctl restart containerd
echo "Restart kubelet"
sudo systemctl restart kubelet

echo "Cluster reset done."
