#!/bin/bash
echo ##################################################
echo ############# Compute Node Setup #################
echo ##################################################
IPPRE=$1
USER=`whoami`
yum install -y -q nfs-utils
mkdir -p /mnt/nfsshare
# the NFS shared will be mounted on a persitant directory
mkdir -p /mnt/scratch
chmod 777 /mnt/nfsshare
chmod 777 /mnt/scratch
systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable nfs-lock
systemctl enable nfs-idmap
systemctl start rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap
localip=`hostname -i | cut --delimiter='.' -f -3`
echo "$IPPRE:/mnt/nfsshare    /mnt/nfsshare   nfs defaults 0 0" | tee -a /etc/fstab
echo "$IPPRE:/mnt/resource/scratch    /mnt/scratch   nfs defaults 0 0" | tee -a /etc/fstab
showmount -e 10.0.0.4
mount -a

ln -s /opt/intel/impi/5.1.3.181/intel64/bin/ /opt/intel/impi/5.1.3.181/bin
ln -s /opt/intel/impi/5.1.3.181/lib64/ /opt/intel/impi/5.1.3.181/lib
chown -R $USER:$USER /mnt/resource/

# Don't require password for HPC user sudo
echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
# Disable tty requirement for sudo
sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

df
