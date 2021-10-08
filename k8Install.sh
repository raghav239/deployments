#!/bin/bash
swapoff -a
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
apt-get update -y
apt-get install -y  apt-transport-https ca-certificates curl software-properties-common gnupg2
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
apt-get update && sudo apt-get install -y \
  containerd.io=1.2.13-2 -y \
  docker-ce=5:19.03.11~3-0~ubuntu-$(lsb_release -cs) -y \
  docker-ce-cli=5:19.03.11~3-0~ubuntu-$(lsb_release -cs) -y

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl enable docker
systemctl restart docker
systemctl status docker
apt-get update -y && sudo apt-get install -y apt-transport-https curl
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet
systemctl status kubelet
kubeadm init
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

