# add nvidia Helm charts repo
helm repo add nvidia https://mellanox.github.io/network-operator
helm repo update

# install NVidia Network Operator
helm install -n network-operator --create-namespace \
	  -f network-operator-values.yaml --wait --version 1.4.0 \
	    network-operator nvidia/network-operator
