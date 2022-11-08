# variables that can be overriden
variable "domain" { default = "hetzner.lab" }
variable "dns" { default = "192.168.100.7" }
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

resource "libvirt_network" "ocp_network" {
  name = var.cluster_name

  mode = "nat"

  domain = var.domain

  addresses = var.network_cidr
  dhcp {
    enabled = false
  }
  dns {
    enabled = true
    local_only = true
  }
  dnsmasq_options {
    options  {
        option_name = "server"
        option_value = "/${var.domain}/${var.dns}"
      }
  }
}

terraform {
 required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.0"
    }
  }
}

