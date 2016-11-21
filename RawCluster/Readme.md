This ARM template is inspired by Taylor NEWILL template:

   - RawCluster tempate: https://github.com/tanewill/5clickTemplates/tree/master/RawCluster  


# Simple deployment of a VM Scale Set of Linux VMs with a jumpbox

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FthovarMS%2F5clickTemplates%2Fmaster%2FRawCluster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This template allows you to deploy a simple VM Scale Set of Linux VMs using the latest HPC version of CentOS (7.1 or 6.5) or SLES (12 SP1). 
This template also deploys a jumpbox with a public IP address in the same virtual network. You can connect to the jumpbox via this public IP address, then connect from there to VMs in the scale set via private IP addresses.

## Architecture


### View of ARM template:

![Alt text](https://github.com/thovarMS/5clickTemplates/blob/master/RawCluster/AzureARM.PNG "ARM")

NOTES: you can deploy CentOS or SLES

### Delpoyed in Azure: 

![Alt text](https://github.com/thovarMS/5clickTemplates/blob/master/RawCluster/Architecture.PNG "architecture")

## Use

To ssh into one of the VMs in the scale set, go to resources.azure.com to find the private IP address of the VM, make sure you are ssh'ed into the jumpbox, then execute the following command:

<pre class="prettyprint copy-to-clipboard " >ssh {username}@{vm-private-ip-address}</pre>

Then log on of the Compute node using the same account and load the MPI environement variables with:

On CentOS (6.5 & 7.1) do:
<pre class="prettyprint copy-to-clipboard " >source /opt/intel/impi/5.1.3.181/bin64/mpivars.sh</pre>

On SLES (12 SP1) do:
<pre class="prettyprint copy-to-clipboard " >source /opt/intel/impi/5.0.3.048/bin64/mpivars.sh</pre>

You are now ready to launch your first test:

<i>Run a simple MPI command</i>
<pre class="prettyprint copy-to-clipboard " >mpirun -ppn 1 -n 2 -hostfile /home/$USER/nodenames.txt -env I_MPI_FABRICS=shm:dapl -env I_MPI_DAPL_PROVIDER=ofa-v2-ib0 -env I_MPI_DYNAMIC_CONNECTION=0 hostname</pre>

<i>Run an MPI benchmark</i>
<pre class="prettyprint copy-to-clipboard " >mpirun -ppn 1 -n 2 -hostfile /home/$USER/nodenames.txt -env I_MPI_FABRICS=dapl     -env I_MPI_DAPL_PROVIDER=ofa-v2-ib0 -env I_MPI_DYNAMIC_CONNECTION=0 IMB-MPI1 pingpong</pre>

## NOTES

The NFS share from the jump box is created on a fast/temporary drive on the VM (/mnt/ressource/scratch), so it will be lost in case if you STOP and then START of the VM from Azure CLI/Portal or PS.

## Still to do

<img src="https://github.com/thovarMS/beegfs-shared-slurm-on-centos7.2/blob/master/workInProgress.png" align="middle" />

- test deployment using H series
