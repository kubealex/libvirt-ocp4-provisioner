# variables that can be overriden
variable "hostname" { default = "worker" }
variable "memory" { default = 32 }
variable "cpu" { default = 4 }
variable "vm_count" { default = 3 }
variable "libvirt_network" { default = "ocp4" }
variable "libvirt_pool" { default = "ocp4" }
variable "vm_volume_size" { default = 20 }
variable "vm_block_device" { default = false }
variable "vm_block_device_size" { default = 100 }

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "os_image" {
  count = var.vm_count
  name = "${var.hostname}-os_image-${count.index}"
  pool = var.libvirt_pool
  size =  var.vm_volume_size*1073741824
  format = "qcow2"
}

resource "libvirt_volume" "storage_image" {
  count = var.vm_block_device ? var.vm_count : 0
  name = "${var.hostname}-storage_image-${count.index}"
  pool = var.libvirt_pool
  size = var.vm_block_device_size*1073741824
  format = "qcow2"
}

# Create the machine
resource "libvirt_domain" "worker" {
  count = var.vm_count
  name = "${var.hostname}-${count.index}"
  memory = var.memory*1024
  vcpu = var.cpu

  cpu {
    mode = "host-passthrough"
  }

  disk {
     volume_id = libvirt_volume.os_image[count.index].id
  }

  dynamic "disk" {
     for_each = var.vm_block_device ? "{ storage = true }" : {}
     content {
     volume_id = libvirt_volume.storage_image[count.index].id
     }
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
 required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}
output "macs" {
  value = "${flatten(libvirt_domain.worker.*.network_interface.0.mac)}"
}

