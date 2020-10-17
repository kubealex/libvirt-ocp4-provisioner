[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# libvirt-ocp4-provisioner - Automate your cluster provisioning from 0 to OCP!
Welcome to the home of the project!
This project has been inspired by [@ValentinoUberti](https://github.com/ValentinoUberti), who did a GREAT job creating the playbooks to provision existing infrastructure nodes on oVirt and preparing for cluster installation.  

I wanted to play around with terraform and port his great work to libvirt and so, here we are! I adapted his playbooks to libvirt needs, making massive use of in-memory inventory creation for provisioned VMs, to minimize the impact on customizable stuff in variables.

To give a quick overview, this project will allow you to provision a **fully working** and **stable** OCP environment, consisting of:

- Bastion machine provisioned with:
	- dnsmasq (with SELinux module, compiled and activated) 
	- dhcp based on dnsmasq
	- nginx (for ignition files and rhcos pxe-boot)
	- pxeboot
- Loadbalancer machine provisioned with:
	- haproxy
- OCP Bootstrap VM
- OCP Master VM(s)
- OCP Worker VM(s)

It also takes care of preparing the host machine with needed packages, configuring:
- dedicated libvirt network (fully customizable)
- dedicated libvirt storage pool (fully customizable) 
- terraform 
- libvirt-terraform-provider ( compiled and initialized based on [https://github.com/dmacvicar/terraform-provider-libvirt](https://github.com/dmacvicar/terraform-provider-libvirt))

PXE is automatic, based on MAC binding to different OCP nodes role, so no need of choosing it from the menus, this means you can just run the playbook, take a beer and have your fully running OCP **4.5.latest** stable up and running.

## **bastion** and **loadbalancer** VMs spec:

- OS: Centos8 Generic Cloud base image [https://cloud.centos.org/centos/8/x86_64/images/](https://cloud.centos.org/centos/8/x86_64/images/)  
- cloud-init:   
  - user: ocpinstall  
  - pass: ocprocks  
  - ssh-key: generated during vm-provisioning and stores in the project folder  

The user is capable of logging via SSH too.  

## Quickstart
The playbook is meant to be ran against a/many local or remote host/s, defined under **vm_host** group, depending on how many clusters you want to configure at once.  

    ansible-playbook main.yml

You can quickly make it work by configuring the needed vars, but you can go straight with the defaults!

**vars/libvirt.yml**

    libvirt:                       
      storage:                     
        pool_name: ocp4
        pool_path: /var/lib/libvirt/images/ocp4
      network:                     
        network_name: ocp4         
        network_gateway: 192.168.100.1
        network_bridge: ocpbr1     
        network_mask: 255.255.255.0

The kind of network created is a simple NAT configuration, without DHCP since it will be provisioned with **bastion** VM. Defaults can be OK if you don't have any overlapping network.


**vars/infra_nodes.yml**

    domain: hetzner.lab
    cluster_name: ocp4
    nfs_registry: false
    infra_nodes:
      host_list:
        bastion:
          - ip: 192.168.100.4
        loadbalancer:
          - ip: 192.168.100.5
    dhcp:
      timezone: "Europe/Rome"
      ntp: 204.11.201.10

Where **domain** is the dns domain assigned to the nodes and **cluster_name** is the name chosen for our OCP cluster installation.

The variable **nfs_registry** is set to false by default. If set to true, it will deploy an additional 100Gi volume on **bastion** VM, create the PV and patch registry to use it in Managed mode.

**vars/cluster_nodes.yml**

    three_node: false
    cluster_nodes:
      host_list:
        bootstrap:
          - ip: 192.168.100.6
        masters:
          - ip: 192.168.100.7
          - ip: 192.168.100.8
          - ip: 192.168.100.9
        workers:
          - ip: 192.168.100.10
            role: infra
          - ip: 192.168.100.11
          - ip: 192.168.100.12
      specs:
        bootstrap:
          vcpu: 4
          mem: 16
          disk: 40
        masters:
          vcpu: 4
          mem: 16
          disk: 40	  
        workers:
          vcpu: 2
          mem: 8
          disk: 40
            
    cluster:
      ocp_user: admin
      ocp_pass: openshift
      pullSecret: ''

**mem** and **disk** are intended in GB

The **role** for workers is intended for nodes labelling. Omitting labels sets them to their default value, **worker**

The count of VMs is taken by the elements of the list, in this example, we got:

- 3 master nodes with 4vcpu and 16G memory
- 3 worker nodes with 2vcpu and 8G memory  

Recommended values are:

| Role | vCPU | RAM | Storage |
|--|--|--|--|
| bootstrap | 4 | 16G | 120G |
| master | 4 | 16G | 120G |
| worker | 2 | 8G | 120G |

For testing purposes, minimum storage value is set at **40GB**.

**The playbook now supports three nodes setup (3 masters with both master and worker node role) intended for pure testing purposes and you can enable it with the three_node boolean var** 

Pull Secret can be retrived easily at [https://cloud.redhat.com/openshift/install/pull-secret](https://cloud.redhat.com/openshift/install/pull-secret)  

HTPasswd provider is created after the installation, you can use ocp_user and ocp_pass to login!

**DISCLAIMER**
This project is for testing/lab only, it is not supported in any way by Red Hat nor endorsed.

Feel free to suggest modifications/improvements.

Alex
