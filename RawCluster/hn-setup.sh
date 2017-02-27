#!/bin/bash
USER=$1
PASS=$2
SKUNAME=$3
LXDISTRO=$4

IP=`hostname -i`
localip=`hostname -i | cut --delimiter='.' -f -3`

echo User is: $USER
echo Pass is: $PASS
echo CentOS is: $SKUNAME
MyHostName=`hostname`

echo "*               hard    memlock         unlimited" >> /etc/security/limits.conf
echo "*               soft    memlock         unlimited" >> /etc/security/limits.conf

mkdir -p /home/$USER/.ssh
mkdir -p /home/$USER/bin

# BEWARE: /mnt/resource/ is /dev/sdb1 which is a temporary disk on the VM (data are not keeped between reboot) 
echo "--- --- --- --- --- --- Create directory under /mnt --- --- --- --- --- --- "
mkdir -p /mnt/resource/scratch
mkdir -p /mnt/nfsshare
chmod -R 777 /mnt/nfsshare/
chmod -R 777 /mnt/resource/scratch/
ls /mnt/resource/
echo "--- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- "

ln -s /opt/intel/impi/5.1.3.181/intel64/bin/ /opt/intel/impi/5.1.3.181/bin
ln -s /opt/intel/impi/5.1.3.181/lib64/ /opt/intel/impi/5.1.3.181/lib

if [ "$LXDISTRO" == "CentOS-HPC" ] ; then
   if [ "$SKUNAME" == "6.5" ] ; then
   # For CentOS 6.5 
      wget http://dl.fedoraproject.org/pub/epel/6/x86_64/sshpass-1.06-1.el6.x86_64.rpm 
      rpm -ivh sshpass-1.06-1.el6.x86_64.rpm 
   else
      wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm
      rpm -ivh epel-release-7-9.noarch.rpm
   fi
fi

if [ "$LXDISTRO" == "SLES-HPC" ] ; then
	wget 195.220.108.108/linux/opensuse/distribution/13.2/repo/oss/suse/x86_64/sshpass-1.05-2.1.2.x86_64.rpm 
	wget https://nmap.org/dist/nmap-7.31-1.x86_64.rpm
    rpm -ivh sshpass-1.05-2.1.2.x86_64.rpm
	rpm -ivh nmap-7.31-1.x86_64.rpm
else
   yum install -y -q nfs-utils sshpass nmap htop
   yum groupinstall -y "X Window System"
fi

echo "/mnt/nfsshare $localip.*(rw,sync,no_root_squash,no_all_squash)" | tee -a /etc/exports
echo "/mnt/resource/scratch $localip.*(rw,sync,no_root_squash,no_all_squash)" | tee -a /etc/exports
chmod -R 777 /mnt/nfsshare/
chmod -R 777 /mnt/resource/scratch/
if [ "$LXDISTRO" == "SLES-HPC" ] ; then
	systemctl start rpcbind.service
	systemctl enable nfsserver.service
	systemctl start nfsserver.service
else
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
      systemctl restart nfs-server
   fi
fi

mv clusRun.sh cn-setup.sh /home/$USER/bin
chmod +x /home/$USER/bin/*.sh
chown $USER:$USER /home/$USER/bin

nmap -sn $localip.* | grep $localip. | awk '{print $5}' > /home/$USER/bin/nodeips.txt
myhost=`hostname -i`
sed -i '/\<'$myhost'\>/d' /home/$USER/bin/nodeips.txt
sed -i '/\<10.0.0.1\>/d' /home/$USER/bin/nodeips.txt

echo -e  'y\n' | ssh-keygen -f /home/$USER/.ssh/id_rsa -t rsa -N ''
echo 'Host *' >> /home/$USER/.ssh/config
echo 'StrictHostKeyChecking no' >> /home/$USER/.ssh/config
chmod 400 /home/$USER/.ssh/config
chown $USER:$USER /home/$USER/.ssh/config

mkdir -p ~/.ssh
echo 'Host *' >> ~/.ssh/config
echo 'StrictHostKeyChecking no' >> ~/.ssh/config
chmod 400 ~/.ssh/config

for NAME in `cat /home/$USER/bin/nodeips.txt`; do sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'hostname' >> /home/$USER/bin/nodenames.txt;done

NAMES=`cat /home/$USER/bin/nodenames.txt` #names from names.txt file
for NAME in $NAMES; do
        sshpass -p $PASS scp -o "StrictHostKeyChecking no" -o ConnectTimeout=2 /home/$USER/bin/cn-setup.sh $USER@$NAME:/home/$USER/
        sshpass -p $PASS scp -o "StrictHostKeyChecking no" -o ConnectTimeout=2 /home/$USER/bin/nodenames.txt $USER@$NAME:/home/$USER/
        sshpass -p $PASS ssh -t -t -o ConnectTimeout=2 $USER@$NAME 'echo "'$PASS'" | sudo -S sh /home/'$USER'/cn-setup.sh '$MyHostName' '$SKUNAME' '$LXDISTRO
        sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'mkdir /home/'$USER'/.ssh && chmod 700 .ssh'
        sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME "echo -e  'y\n' | ssh-keygen -f .ssh/id_rsa -t rsa -N ''"
        sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'touch /home/'$USER'/.ssh/config'
        sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'echo "Host *" >  /home/'$USER'/.ssh/config'
        sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'echo StrictHostKeyChecking no >> /home/'$USER'/.ssh/config'
        sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'chmod 400 /home/'$USER'/.ssh/config'
        cat /home/$USER/.ssh/id_rsa.pub | sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'cat >> /home/'$USER'/.ssh/authorized_keys'
        sshpass -p $PASS scp -o "StrictHostKeyChecking no" -o ConnectTimeout=2 $USER@$NAME:/home/$USER/.ssh/id_rsa.pub /home/$USER/.ssh/sub_node.pub

        for SUBNODE in `cat /home/$USER/bin/nodeips.txt`; do
                sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$SUBNODE 'mkdir -p .ssh'
                cat /home/$USER/.ssh/sub_node.pub | sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$SUBNODE 'cat >> /home/'$USER'/.ssh/authorized_keys'
        done
        sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'chmod 700 /home/'$USER'/.ssh/'
        sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'chmod 640 /home/'$USER'/.ssh/authorized_keys'
	
	# enable passwordless sudo
	sshpass -p $PASS ssh -o ConnectTimeout=2 $USER@$NAME 'echo "$USER ALL=(ALL) NOPASSWD: ALL" >>  /etc/sudoers.d/waagent'
done

cp ~/.ssh/authorized_keys /home/$USER/.ssh/authorized_keys
cp /home/$USER/bin/nodenames.txt /mnt/scratch/hosts
chown -R $USER:$USER /home/$USER/.ssh/
chown -R $USER:$USER /home/$USER/bin/
chown -R $USER:$USER /mnt/resource/scratch/
chmod -R 744 /mnt/resource/scratch/
rm /home/$USER/bin/cn-setup.sh

# Don't require password for HPC user sudo
echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod +rwx /etc/sudoers.d/waagent
echo "$USER ALL=(ALL) NOPASSWD: ALL" >>  /etc/sudoers.d/waagent
    
# Disable tty requirement for sudo
sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers
