# Simple deployment of a VM Scale Set of Linux VMs with a jumpbox

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FthovarMS%2F5clickTemplates%2Fmaster%2FRawCluster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FthovarMS%2F5clickTemplates%2Fmaster%2FRawCluster%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template allows you to deploy a simple VM Scale Set of Linux VMs using the latest HPC version of CentOS 7.1. This template also deploys a jumpbox with a public IP address in the same virtual network. You can connect to the jumpbox via this public IP address, then connect from there to VMs in the scale set via private IP addresses. To ssh into the jumpbox, you could use the following command:

<b>Architecture</b>

View of ARM template:

<img src="https://github.com/thovarMS/5clickTemplates/blob/master/RawCluster/Azure%20ARM.PNG"  align="middle" width="395" height="274"  alt="hpc_vmss_architecture" border="1"/> <br></br>

Delpoyed in Azure: 

<img src="https://github.com/thovarMS/5clickTemplates/blob/master/RawCluster/Architecture.PNG"  align="middle" width="395" height="274"  alt="hpc_vmss_architecture" border="1"/> <br></br>

<b>Use</b>

ssh {username}@{jumpbox-public-ip-address}

To ssh into one of the VMs in the scale set, go to resources.azure.com to find the private IP address of the VM, make sure you are ssh'ed into the jumpbox, then execute the following command:



ssh {username}@{vm-private-ip-address}

<b>PARAMETER RESTRICTIONS</b>

vmssName must be 3-61 characters in length. It should also be globally unique across all of Azure. If it isn't globally unique, it is possible that this template will still deploy properly, but we don't recommend relying on this pseudo-probabilistic behavior.
instanceCount must be 100 or less.

