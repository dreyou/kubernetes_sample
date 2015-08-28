# -*- mode: ruby -*-
# vi: set ft=ruby :
#
Vagrant.configure(2) do |config|
  # 
  # Vagrant boxes for libvirt or virtualbox
  # 
  config.vm.box = "puppetlabs/centos-7.0-64-nocm"
  config.vm.provider "virtualbox"
  #
#
# Creating minions nodes
#
  config.vm.define :minion1 do |minion1|
    minion1.vm.network "private_network", ip: "192.168.33.11"
    minion1.vm.hostname = "minion1"
    minion1.vm.synced_folder "./common", "/vagrant"
    minion1.vm.provision "shell", inline: $common
    minion1.vm.provision "shell", inline: $minion
  end
  config.vm.define :minion2 do |minion2|
    minion2.vm.network "private_network", ip: "192.168.33.12"
    minion2.vm.hostname = "minion2"
    minion2.vm.synced_folder "./common", "/vagrant"
    minion2.vm.provision "shell", inline: $common
    minion2.vm.provision "shell", inline: $minion
  end
#
# Creating master node
#
  config.vm.define :master do |master|
    master.vm.network "private_network", ip: "192.168.33.10"
    master.vm.hostname = "master"
    master.vm.synced_folder "./common", "/vagrant"
    master.vm.provision "shell", inline: $common
    master.vm.provision "shell", inline: $master
  end
#
# Master node provisioning
#
$common = <<SCRIPT
#!/bin/sh
>&2 echo Common setup
#
# Check internet connection
#
ping -c 2 -W 2 google-public-dns-a.google.com
if [[ $? != 0 ]]
then
  echo "Can't connect to internet" >&2
  exit 1
fi
#
# Adding hosts to /etc/hosts
#
echo "192.168.33.10 master" >> /etc/hosts
echo "192.168.33.11 minion1" >> /etc/hosts
echo "192.168.33.12 minion2" >> /etc/hosts
echo "192.168.33.13 minion3" >> /etc/hosts
echo "192.168.33.14 minion4" >> /etc/hosts
#
# Prepare ssh keys
#
mkdir /root/.ssh
cp /vagrant/id_rsa.pub /root/.ssh/
cp /vagrant/id_rsa /root/.ssh/
cat /vagrant/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
#
# Turning off firewalld (clean iptables rules)
#
systemctl stop firewalld.service
systemctl disable firewalld.service
#
# Turn on our interfaces, wich may not be started by vagrant
#
systemctl restart NetworkManager.service
systemctl stop network.service
systemctl start network.service
chkconfig network on
#
# Prepare repository
#
cp -vf /vagrant/virt7-release.repo /etc/yum.repos.d/virt7-release.repo
echo 'exclude=.ru, .corbina.net, -ru' >> /etc/yum/pluginconf.d/fastestmirror.conf
yum clean all
yum -y makecache
yum erase etcd
yum -y install --enablerepo=virt7-release kubernetes
#
# Config file to all nodes
#
cp /vagrant/config /etc/kubernetes/config
SCRIPT
#
# Master node provisioning
#
$master = <<SCRIPT
>&2 echo Setting up Master Node
#!/bin/sh
#
# Install etcd on master node
#
yum -y install http://cbs.centos.org/kojifiles/packages/etcd/0.4.6/7.el7.centos/x86_64/etcd-0.4.6-7.el7.centos.x86_64.rpm
#
echo 'addr = "0.0.0.0:4001"' >> /etc/etcd/etcd.conf
echo 'bind_addr = "0.0.0.0:4001"' >> /etc/etcd/etcd.conf
#
# Scan ssh keys
#
for HOST in {master,minion1}; do ssh-keyscan $HOST >> /root/.ssh/known_hosts; done
#
# Sync time on all hosts
#
for HOST in {master,minion1}; do ssh $HOST "yum -y install ntp&&systemctl stop ntpd.service&&ntpdate pool.ntp.org&&systemctl enable ntpd.service&&systemctl start ntpd.service"; done
#
# Copy apiserver config
#
cp /vagrant/apiserver /etc/kubernetes/apiserver
#
# Start master services
#
for SERVICES in etcd kube-controller-manager kube-scheduler; do 
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES 
done
systemctl stop kube-apiserver
systemctl enable kube-apiserver
systemctl start kube-apiserver
sleep 20
#
# Check nodes
#
kubectl get nodes
#
#
#
wget http://kubernetes.io/v1.0/docs/user-guide/walkthrough/pod-nginx.yaml
kubectl create -f pod-nginx.yaml
sleep 20
kubectl get pods
#curl http://$(kubectl get pod nginx -o=template -t={{.status.podIP}})
#kubectl delete pod nginx
SCRIPT
#
# Minion node provisioning
#
$minion = <<SCRIPT
#!/bin/sh
>&2 echo Setting up Minion Node
#
# Copy kubelet config
#
cp /vagrant/kubelet /etc/kubernetes/kubelet
#
# Start minion services
#
for SERVICES in kube-proxy kubelet docker; do 
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES 
done
SCRIPT
end
