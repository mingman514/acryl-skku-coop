# Initial Settings (run once)
sudo swapoff -a

cd ./scripts
sudo apt install -y jq ipcalc
./group-setting.sh
./install-docker-containerd.sh
./install-k8s-helm.sh
