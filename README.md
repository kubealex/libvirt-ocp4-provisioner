[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# libvirt-ocp4-provisioner - Automate your cluster provisioning from 0 to OCP!

Welcome to the home of the project!
This project has been inspired by [@ValentinoUberti](https://github.com/ValentinoUberti), who did a GREAT job creating the playbooks to provision existing infrastructure nodes on oVirt and preparing for cluster installation.

I wanted to play around with terraform and port his great work to libvirt and so, here we are! I adapted his playbooks to libvirt needs, making massive use of in-memory inventory creation for provisioned VMs, to minimize the impact on customizable stuff in variables.

- [Project Overview](#project-overview)
- [Quickstart](#quickstart)
  - [HA Clusters](#ha-clusters)
  - [Single Node Openshift (SNO)](#single-node-openshift--sno-)
- [Quickstart with Execution Environment](#quickstart-with-execution-environment)
  - [Build EE image](#build-ee-image)
  - [Run playbooks](#run-playbooks)
- [Common vars](#common-vars)
  - [HA Configuration vars](#ha-configuration-vars)
  - [Single Node Openshift vars](#single-node-openshift-vars)
- [Cleanup](#cleanup)
  - [Full deployment cleanup](#full-deployment-cleanup)
  - [SNO deployment cleanup](#sno-deployment-cleanup)

## Project Overview

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

PXE is automatic, based on MAC binding to different OCP nodes role, so no need of choosing it from the menus, this means you can just run the playbook, take a beer and have your fully running OCP up and running.

The version can be selected freely, by specifying the desired one (i.e. 4.10.x, 4.13.2) or the latest stable release with "stable". **Versions before 4.6 are not supported anymore!!**

Now support for **Single Node Openshift - SNO** has been added!

**bastion** and **loadbalancer** VMs spec:

- OS: Centos8 Generic Cloud base image [https://cloud.centos.org/centos/8-stream/x86_64/images/](https://cloud.centos.org/centos/8-stream/x86_64/images/)
- cloud-init:
  - user: ocpinstall
  - pass: ocprocks
  - ssh-key: generated during vm-provisioning and stores in the project folder

The user is capable of logging via SSH too.

## Quickstart

First of all, you need to install required collections to get started:

```bash
ansible-galaxy collection install -r requirements.yml
```

The playbook is meant to run against local host/s, defined under **vm_host** group in your inventory, depending on how many clusters you want to configure at once.

### HA Clusters

```bash
ansible-playbook main.yml
```

### Single Node Openshift (SNO)

```bash
ansible-playbook main-sno.yml
```

You can quickly make it work by configuring the needed vars, but you can go straight with the defaults!

## Quickstart with Execution Environment

The playbooks are compatible with the newly introduced **Execution environments (EE)**. To use them with an execution environment you need to have [ansible-builder](https://ansible-builder.readthedocs.io/en/stable/) and [ansible-navigator](https://ansible-navigator.readthedocs.io/en/latest/) installed.

### Build EE image

To build the EE image, jump in the _execution-environment_ folder and run the build:

```bash
ansible-builder build -f execution-environment/execution-environment.yml -t ocp-ee
```

### Run playbooks

To run the playbooks use ansible navigator:

```bash
ansible-navigator run main.yml -m stdout
```

Or, in case of Single Node Openshift:

```bash
ansible-navigator run main-sno.yml -m stdout
```

## Common vars

The kind of network created is a simple NAT configuration, without DHCP since it will be provisioned with **bastion** VM. Defaults can be OK if you don't have any overlapping network.

### HA Configuration vars

**vars/infra_vars.yml**

```yaml
infra_nodes:
  host_list:
    bastion:
      - ip: 192.168.100.4
    loadbalancer:
      - ip: 192.168.100.5
dhcp:
  timezone: "Europe/Rome"
  ntp: 204.11.201.10
```

**vars/cluster_vars.yml**

```yaml
three_node: false
network_cidr: 192.168.100.0/24
domain: hetzner.lab
additional_block_device:
  enabled: false
  size: 100
additional_nic:
  enabled: false
  network:
cluster:
  version: stable
  name: ocp4
  ocp_user: admin
  ocp_pass: openshift
  pullSecret: ""
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
```

Where **domain** is the dns domain assigned to the nodes and **cluster.name** is the name chosen for our OCP cluster installation.

**mem** and **disk** are intended in GB

**cluster.version** allows you to choose a particular version to be installed (i.e. 4.5.0, stable)

**additional_block_device** controls whether an additional disk of the given size should be added to Workers or Control Plane nodes in case of compact (3 nodes) setup

**additional_nic** allows the creation of an additional network interface on all nodes. It is possible to customize the libvirt network to attach to it.

The **role** for workers is intended for nodes labelling. Omitting labels sets them to their default value, **worker**

The count of VMs is taken by the elements of the list, in this example, we got:

- 3 master nodes with 4vcpu and 16G memory
- 3 worker nodes with 2vcpu and 8G memory

Recommended values are:

| Role      | vCPU | RAM | Storage |
| --------- | ---- | --- | ------- |
| bootstrap | 4    | 16G | 120G    |
| master    | 4    | 16G | 120G    |
| worker    | 2    | 8G  | 120G    |

For testing purposes, minimum storage value is set at **60GB**.

**The playbook now supports three nodes setup (3 masters with both master and worker node role) intended for pure testing purposes and you can enable it with the three_node boolean var ONLY FOR 4.6+**

### Single Node Openshift vars

**vars/cluster_vars.yml**

```yaml
domain: hetzner.lab
network_cidr: 192.168.100.0/24
cluster:
  version: stable
  name: ocp4
  ocp_user: admin
  ocp_pass: openshift
  pullSecret: ""
cluster_nodes:
  host_list:
    sno:
      ip: 192.168.100.7
  specs:
    sno:
      vcpu: 8
      mem: 32
      disk: 120
local_storage:
  enabled: true
  volume_size: 50
additional_nic:
  enabled: false
  network:
```

**local_storage** field can be used to provision an additional disk to the VM in order to provision volumes using, for instance, rook-ceph or local storage operator.

**additional_nic** allows the creation of an additional network interface on the node. It is possible to customize the libvirt network to attach to it.

In both cases, Pull Secret can be retrived easily at [https://cloud.redhat.com/openshift/install/pull-secret](https://cloud.redhat.com/openshift/install/pull-secret)

**HTPasswd** provider is created after the installation, you can use **ocp_user** and **ocp_pass** to login!

## Cleanup

To clean all resources, you can simply run the cleanup playbooks.

### Full deployment cleanup

```bash
ansible-playbook -i inventory 99_cleanup.yml
```

### SNO deployment cleanup

```bash
ansible-playbook -i inventory 99_cleanup_sno.yml
```

**DISCLAIMER**
This project is for testing/lab only, it is not supported in any way by Red Hat nor endorsed.

Feel free to suggest modifications/improvements.

Alex
