#!/bin/bash

user=kuby
home="/home/$user"

ipv6=$(sudo cat /proc/sys/net/ipv6/conf/all/disable_ipv6)
#Disable ipv6
if [ "$ipv6"  = "0" ]; then
        sudo sh  "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf" 
        sudo sh "echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf"
        sudo sh "echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf"
fi
sudo sysctl -p
sudo cat /proc/sys/net/ipv6/conf/all/disable_ipv6

sudo sysctl net.bridge.bridge-nf-call-iptables=1
#Disable swap
sudo swapoff -a

sudo kubeadm init --pod-network-cidr 192.166.0.0/16 --service-cidr 10.96.0.0/12 --service-dns-domain "k8s" --apiserver-advertise-address $(ifconfig eth0 | grep 'inet'|cut -d':' -f2| awk '{print $2}')


rm -rf  $home/.kube
mkdir -p $home/.kube
sudo cp -i /etc/kubernetes/admin.conf $home/.kube/config
sudo chown $user:$user  $home/.kube/config
export KUBECONFIG=$home/.kube/config
export KUBECONFIG=$home/.kube/config | tee -a ~/.bashrc

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
#kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

#Allow pods on master
kubectl taint nodes --all node-role.kubernetes.io/master-
sudo kubeadm token list

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard-arm-head.yaml
