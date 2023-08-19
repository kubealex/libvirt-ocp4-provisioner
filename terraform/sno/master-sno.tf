# variables that can be overriden
variable "hostname" { default = "master-sno" }
variable "memory" { default = 32 }
variable "cpu" { default = 4 }
variable "coreos_iso_path" { default = "" }
variable "vm_volume_size" { default = 40 }
variable "vm_net_ip" { default = "192.168.100.7" }
variable "local_volume_size" { default = 50 }
variable "local_volume_enabled" { default = false }
variable "vm_additional_nic" { default = false }
variable "vm_additional_nic_network" { default = "default" }
variable "libvirt_network" { default = "ocp" }
variable "libvirt_pool" { default = "default" }

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "os_image" {
  name = "${var.hostname}-os_image"
  size = var.vm_volume_size*1073741824
  pool = var.libvirt_pool
  format = "qcow2"
}

resource "libvirt_volume" "local_disk" {
  count = tobool(lower(var.local_volume_enabled)) ? 1 : 0
  name = "${var.hostname}-local_disk"
  pool = var.libvirt_pool
  size = var.local_volume_size*1073741824
  format = "qcow2"
}

# Create the machine
resource "libvirt_domain" "master" {
  count = 1
  name = "${var.hostname}"
  memory = var.memory*1024
  vcpu = var.cpu

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.os_image.id
  }

  dynamic "disk" {
    for_each = tobool(lower(var.local_volume_enabled)) ? { storage = true } : {}
    content {
    volume_id = libvirt_volume.local_disk[count.index].id
    }
   }

  disk {
    file = "${var.coreos_iso_path}"
  }

  network_interface {
    network_name = var.libvirt_network
    addresses = [ "${var.vm_net_ip}" ]
  }

  dynamic "network_interface" {
     for_each = tobool(lower(var.vm_additional_nic)) ? { nic = true } : {}
     content {
       network_name = var.vm_additional_nic_network
     }
  }

  boot_device {
    dev = [ "hd", "cdrom" ]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "vnc"
    listen_type = "address"
    autoport = "true"
  }

}

terraform {
 required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}

output "macs" {
  value = "${flatten(libvirt_domain.master.*.network_interface.0.mac)}"
}
