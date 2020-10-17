# variables that can be overriden
variable "hostname" { default = "bootstrap" }
variable "memory" { default = 16 }
variable "cpu" { default = 4 }
variable "vm_volume_size" { default = 40 }
variable "libvirt_network" { default = "ocp" }
variable "libvirt_pool" { default = "default" }

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

# fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "os_image" {
  name = "${var.hostname}-os_image"
  size = var.vm_volume_size*1073741824
  pool = var.libvirt_pool
  format = "qcow2"
}

# Create the machine
resource "libvirt_domain" "bootstrap" {
  name = var.hostname
  memory = var.memory*1024
  vcpu = var.cpu

  disk {
       volume_id = libvirt_volume.os_image.id
  }
  network_interface {
       network_name = var.libvirt_network
  }

  boot_device {
    dev = [ "hd", "network" ]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }
}

terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.2"
    }
  }
}

output "macs" {
  value = "${flatten(libvirt_domain.bootstrap.*.network_interface.0.mac)}"
}

