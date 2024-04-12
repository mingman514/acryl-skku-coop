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



# Nvidia Device Plugin 설정
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/libnvidia-container.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

echo '{
    "default-runtime": "nvidia",
            "runtimes": {
	                    "nvidia": {
			                                "path": "/usr/bin/nvidia-container-runtime",
							                                        "runtimeArgs": []
												                                                }
																	                                            }
                            }' | sudo tee /etc/docker/daemon.json

sudo systemctl restart docker

sudo sed -i 's/default_runtime_name = "runc"/default_runtime_name = "nvidia"/' /etc/containerd/config.toml
sudo sed -i 's/runtimes.runc/runtimes.nvidia/' /etc/containerd/config.toml
sudo sed -i 's@BinaryName = ""@BinaryName = "/usr/bin/nvidia-container-runtime"@' /etc/containerd/config.toml

sudo systemctl enable containerd
sudo systemctl restart containerd


##############################
# K8S 설치
##############################
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# k8s 공식 repo 추가
sudo mkdir -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# k8s 관련 패키지 설치 (설치 가능한 패키지 확인: apt-cache madison [package name])
sudo apt-get update
sudo apt-get install -y kubelet=1.27.10-1.1 kubeadm=1.27.10-1.1 kubectl=1.27.10-1.1

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
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
