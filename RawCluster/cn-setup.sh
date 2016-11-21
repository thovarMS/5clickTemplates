#!/bin/bash
echo ##################################################
echo ############# Compute Node Setup #################
echo ##################################################
IPPRE=$1
SKUNAME=$2
LXDISTRO=$3
USER=`whoami`
yum install -y -q nfs-utils
mkdir -p /mnt/nfsshare
# the NFS shared will be mounted on a persitant directory on the VM
mkdir -p /mnt/scratch
chmod 777 /mnt/nfsshare
chmod 777 /mnt/scratch
if [ "$LXDISTRO" == "CentOS-HPC" ] ; then
   if [ "$SKUNAME" == "6.5" ] ; then
   # For CentOS 6.5 (systemctl is supported for version > 7)
      chkconfig nfs on 
      chkconfig rpcbind on 
      service rpcbind start
      service nfs start
   else
      systemctl enable rpcbind
      systemctl enable nfs-server
      systemctl enable nfs-lock
      systemctl enable nfs-idmap
      systemctl start rpcbind
      systemctl start nfs-server
      systemctl start nfs-lock
      systemctl start nfs-idmap
   fi
fi   
localip=`hostname -i | cut --delimiter='.' -f -3`
echo "$IPPRE:/mnt/nfsshare    /mnt/nfsshare   nfs defaults 0 0" | tee -a /etc/fstab
echo "$IPPRE:/mnt/resource/scratch    /mnt/scratch   nfs defaults 0 0" | tee -a /etc/fstab
showmount -e $IPPRE
mount -a

if [ "$LXDISTRO" == "CentOS-HPC" ] ; then
   ln -s /opt/intel/impi/5.1.3.181/intel64/bin/ /opt/intel/impi/5.1.3.181/bin
   ln -s /opt/intel/impi/5.1.3.181/lib64/ /opt/intel/impi/5.1.3.181/lib
else
   rpm -v -i --nodeps /opt/intelMPI/intel_mpi_packages/*.rpm
fi
chown -R $USER:$USER /mnt/resource/

# Don't require password for HPC user sudo
echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
# Disable tty requirement for sudo
sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

df
