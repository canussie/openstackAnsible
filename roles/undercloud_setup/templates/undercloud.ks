# set sha512 encycption
auth --enableshadow --passalgo=sha512
# set keyboard and lang
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8
# Network information
network  --bootproto=static --ip "{{ undercloud_ip }}" --netmask "{{ undercloud_netmask }}" --gateway "{{ undercloud_gw }}" --nameserver 8.8.8.8 --activate
network  --hostname=osd.ben.net
#
# Root password
rootpw --iscrypted {{ root_crypt }}
# System services
services --disabled="chronyd,firewalld,NetworkManager"
# System timezone
timezone Australia/Sydney --isUtc --nontp
user --name=stack --password={{ stack_crypt }} --iscrypted --gecos="Stack User"
user --name=blewis --password={{ blewis_crypt }} --iscrypted --gecos="Ben Lewis"
# System bootloader configuration
bootloader --location=mbr --boot-drive=vda
clearpart --all --initlabel --drives=vda
ignoredisk --only-use=vda



# Disk partitioning information
part pv.251 --fstype="lvmpv" --ondisk=vda --size=75000
part /boot --fstype="xfs" --ondisk=vda --size=512
volgroup centos --pesize=4096 pv.251
logvol /var  --fstype="xfs" --size=10240 --name=var --vgname=centos
logvol /home  --fstype="xfs" --size=10240 --name=home --vgname=centos --grow
logvol /  --fstype="xfs" --size=5120 --name=root --vgname=centos
logvol /usr  --fstype="xfs" --size=10240 --name=usr --vgname=centos
logvol /tmp  --fstype="xfs" --size=10240 --name=tmp --vgname=centos
logvol swap  --fstype="swap" --size=8192 --name=swap --vgname=centos

%packages
@^minimal
@core
kexec-tools

%end

%post
for nic in $(grep -l NM_CONTROLLED.*yes /etc/sysconfig/network-scripts/ifcfg-*)
  do
    cp $nic ${nic}.bak
    sed -i "s/NM_CONTROLLED=yes/NM_CONTROLLED=no/"  $nic
  done
# no passwd sudo blewis
echo "blewis    ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
# setup ssh keys
mkdir -p /root/.ssh
chmod 0700 /root/.ssh
mkdir -p /home/blewis/.ssh
chmod 0700 /home/blewis/.ssh
mkdir -p /home/stack/.ssh
chmod 0700 /home/stack/.ssh
chown -R stack: /home/stack/.ssh
# root
cat << EOF >> /root/.ssh/authorized_keys
{{ blewis_ssh_key }}
EOF
# blewis
cat << EOF >> /home/blewis/.ssh/authorized_keys
{{ blewis_ssh_key }}
EOF
# stack
cat << EOF >> /home/stack/.ssh/authorized_keys
{{ blewis_ssh_key }}
EOF
#chmod
chmod 0600 /root/.ssh/authorized_keys
chmod 0600 /home/blewis/.ssh/authorized_keys
chown blewis: -R /home/blewis/.ssh/
#stack sudo
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack 
chmod 0440 /etc/sudoers.d/stack
%end

reboot
