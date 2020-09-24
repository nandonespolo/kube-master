#!/bin/bash

node_type=$1

echo "----- Turn off swapp"
sudo swapoff -a  
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "----- Get the Docker gpg key:"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

echo "----- Add the Docker repository:"
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

echo "----- Get the Kubernetes gpg key:"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

echo "----- Add the Kubernetes repository:"
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

echo "----- Update your packages:"
sudo apt-get -y update

echo "----- Install Docker, kubelet, kubeadm, and kubectl:"
sudo apt-get install -y docker-ce=5:19.03.9~3-0~ubuntu-focal kubelet=1.19.0-00 kubeadm=1.19.0-00 kubectl=1.19.0-00

echo "----- Hold them at the current version:"
sudo apt-mark hold docker-ce kubelet kubeadm kubectl

echo "----- Add the iptables rule to sysctl.conf:"
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf

echo "----- Enable iptables immediately:"
sudo sysctl -p

echo "----- Setting up aliases:"
cat << 'EOF' >> ~/.bashrc
alias kb="kubectl"
alias kball="kubectl get all"
alias kballn="kubectl get all --all-namespaces"
alias kbsys="kubectl --namespace kube-system"
EOF
source ~/.bashrc

EOF
if [ "$node_type" = "master" ];
then   
    echo "----- Initialize the cluster (run only on the master):"
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16

    echo "----- Set up local kubeconfig:"
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo "----- Apply Flannel CNI network overlay:"
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    sleep 5
    # https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#install
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
fi
