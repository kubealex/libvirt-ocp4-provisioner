# variables that can be overriden
variable "domain" { default = "hetzner.lab" }
variable "network_cidr" { 
  type = list
  default = ["192.168.100.0/24"] 
}
variable "cluster_name" { default = "ocp4" }
variable "libvirt_pool_path" { default = "/var/lib/libvirt/images" }
# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

# A pool for all cluster volumes
resource "libvirt_pool" "cluster" {
  name = var.cluster_name
  type = "dir"
  path = "${var.libvirt_pool_path}/${var.cluster_name}"
}

resource "libvirt_network" "kube_network" {
  # the name used by libvirt
  name = var.cluster_name

  # mode can be: "nat" (default), "none", "route", "bridge"
  mode = "nat"

  #  the domain used by the DNS server in this network
  domain = var.domain

  #  list of subnets the addresses allowed for domains connected
  # also derived to define the host addresses
  # also derived to define the addresses served by the DHCP server
  addresses = var.network_cidr

  # (optional) the bridge device defines the name of a bridge device
  # which will be used to construct the virtual network.
  # (only necessary in "bridge" mode)
  bridge = var.cluster_name

  # (optional) the MTU for the network. If not supplied, the underlying device's
  # default is used (usually 1500)
  # mtu = 9000
  dhcp {
    enabled = false
  }
  dns { 
    enabled = true
  }
}

terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.11"
    }
  }
}

output "test" {
  value = var.network_cidr
}


