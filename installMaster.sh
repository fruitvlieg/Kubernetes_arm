#!/bin/bash
user=kuby

#Create user change passwd after running this script
if ! id -u $user > /dev/null 2>&1; then
    sudo adduser $user --gecos "First Last,RoomNumber,WorkPhone,HomePhone"  --disabled-password --shell /bin/bash
    echo "$user:$user" | sudo chpasswd
    usermod -s /bin/bash $user
    usermod -m -d /home/$user $user
fi

# Install Docker
curl -sSL get.docker.com | sh && \
sudo usermod $user -aG docker

# Disable Swap
sudo dphys-swapfile swapoff && \
sudo dphys-swapfile uninstall && \
sudo update-rc.d dphys-swapfile remove
echo Adding " cgroup_enable=cpuset cgroup_enable=memory" to /boot/cmdline.txt
sudo cp /boot/cmdline.txt /boot/cmdline_backup.txt
orig="$(head -n1 /boot/cmdline.txt) cgroup_enable=cpuset cgroup_enable=memory"
echo $orig | sudo tee /boot/cmdline.txt

# Add repo list and install kubeadm
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
sudo apt-get update -q && \
sudo apt-get install -qy kubeadm

#Show interface menu
i=0
while read line
do
    OPTIONS[ $i ]="$line"
    (( i++ ))
    OPTIONS[ $i ]="$(ip link show $line)"
    (( i++ ))
done < <(ls /sys/class/net)

interface=$(whiptail --title "Menu" --menu "Choose an network interface for k8s master" 45 180 24 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)
echo $interface

kubeadm init --pod-network-cidr 192.166.0.0/16 --service-cidr 10.96.0.0/12 --service-dns-domain "k8s" --apiserver-advertise-address $(ifconfig $interface | grep 'inet'|cut -d':' -f2| awk '{print $2}')

home="/home/$user"
mkdir -p $home/.kube
cp -i /etc/kubernetes/admin.conf $home/.kube/config
chown $user:$user  $home/.kube/config
export KUBECONFIG=$home/.kube/config
export KUBECONFIG=$home/.kube/config | tee -a ~/.bashrc
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sudo kubeadm token list
