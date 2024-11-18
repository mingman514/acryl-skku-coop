##############################
# K8S 설치
##############################
K8S_VERSION="1.31"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# k8s 공식 repo 추가
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

# k8s 관련 패키지 설치 (설치 가능한 패키지 확인: apt-cache madison [package name])
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# 버전 고정
sudo apt-mark hold kubelet kubeadm kubectl

# 자동 부팅 확인
sudo systemctl enable kubelet

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
