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

sudo systemctl restart containerd

kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.3/nvidia-device-plugin.yml
