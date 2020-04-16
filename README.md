
# Openshift libvirt provisioning
Welcome to the home of the project!
This project has been inspired by the great work of my friend @valentinouberti, that did a great job creating the playbooks to deploy infrastructure nodes on oVirt ().
I wanted to play around with terraform and port his great work to libvirt and so, here we are!

To give a quick overview, this project will allow you to provision a fully working OCP **stable** environment, consisting of:

- Bastion machine provisioned with:
	- dnsmasq (with SELinux module, compiled and activated) 
	- dhcp based on dnsmasq
	- nginx (for ignition files and rhcos pxe-boot)
	- pxeboot
- Loadbalancer machine provisioned with:
	- haproxy
- OCP Bootstrap machine
- OCP Master(s) VM(s)
- OCP Worker(s) VM(s)

It also takes care of preparing the host machine with needed packages, configuring:
- dedicated libvirt network (fully customizable)
- dedicated libvirt storage pool (fully customizable) 
- terraform 
- libvirt-terraform-provider ( compiled and initialized based on [https://github.com/dmacvicar/terraform-provider-libvirt](https://github.com/dmacvicar/terraform-provider-libvirt))

PXE is automatic, based on MAC binding to different OCP nodes role, so no need of choosing it from the menus, this means you can just run the playbook, take a beer and have your fully running OCP .4.3.10 stable up and running.

## **bastion** and **loadbalancer** VMs spec:

- OS: Centos8 Generic Cloud base image [https://cloud.centos.org/centos/8/x86_64/images/](https://cloud.centos.org/centos/8/x86_64/images/)  
- cloud-init:   
  - user: ocpinstall  
  - pass: ocprocks  
  - ssh-key: generated during vm-provisioning and store in the project folder  


## Quickstart
The playbook is meant to be ran on **localhost** so no inventory is needed.

    ansible-playbook main.yml

You can quickly make it work by configuring the needed vars, but you can go straight with the defaults!

**vars/libvirt.yml**

    libvirt:                       
      storage:                     
        pool_name: ocp4_vms        
        pool_path: /var/lib/libvirt/images/ocp4
      network:                     
        network_name: ocp4         
        network_gateway: 192.168.100.1
        network_bridge: ocpbr1     
        network_mask: 255.255.255.0

**vars/infra_nodes.yml**

    infra_nodes:
      host_list:
        bastion:
          ip: 192.168.100.4
        loadbalancer:
          ip: 192.168.100.5
      domain: hetzner.lab
      cluster_name: ocp4
     
    dhcp:
      timezone: "Europe/Rome"
      ntp: 204.11.201.10
Where **domain** is the dns domain assigned to the nodes and **cluster_name** is the name chosen for our OCP cluster installation.

**vars/cluster_nodes.yml**

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
          - ip: 192.168.100.11
          - ip: 192.168.100.12
      specs:
        masters:
          vcpu: 4
          mem: 16384
        workers:
          vcpu: 4
          mem: 16384
            
	cluster:
	  ocp_user: admin
      ocp_pass: openshift
      pull_secret: ''

The count of VMs is taken by the elements of the list, in this example, we got:

- 3 master nodes with 4vcpu and 16G memory
- 3 worker nodes with 4vcpu and 16G memory  

HTPasswd provider is created after the installation, you can use ocp_user and ocp_pass to login!


