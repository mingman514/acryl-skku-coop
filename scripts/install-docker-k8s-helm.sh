##############################
# Docker 및 Containerd 설치
##############################
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8
sudo add-apt-repository \
	   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	      bionic \
	         stable"
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# containerd에 관련 모드 설정
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# 해당 모드 로드
sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl 파라미터 설정
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# sysctl 파라미터 적용
sudo sysctl --system

# containerd 설정 파일 생성
sudo mkdir -p /etc/containerd
sudo rm /etc/containerd/config.toml # 기존 파일 있다면 제거
containerd config default | sudo tee /etc/containerd/config.toml

# SystemdCgroup = true 설정
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl enable containerd
sudo systemctl restart containerd



##############################
# K8S 설치
##############################
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# k8s 관련 패키지 설치
sudo apt-get update
sudo apt-get install -y kubelet=1.27.4-00 kubeadm=1.27.4-00 kubectl=1.27.4-00

# 버전 고정
sudo apt-mark hold kubelet kubeadm kubectl

# 자동 부팅 확인
sudo systemctl enable docker kubelet

# 자동완성 설정 (exec bash로 배시 리로드, source /etc/profile.d/bash_completion.sh로 자동완성 리로드)
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
source /etc/profile.d/bash_completion.sh


##############################
# Helm 설치
##############################
# install Helm
sudo snap install helm --classic
