# variables that can be overriden
variable "hostname" { default = "master" }
variable "memory" { default = 16 }
variable "cpu" { default = 4 }
variable "vm_count" { default = 3 }
variable "vm_volume_size" { default = 40 }
variable "libvirt_network" { default = "ocp" }
variable "libvirt_pool" { default = "default" }

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "os_image" {
  count = var.vm_count
  name = "${var.hostname}-os_image-${count.index}"
  size = var.vm_volume_size*1073741824
  pool = var.libvirt_pool
  format = "qcow2"
}

# Create the machine
resource "libvirt_domain" "master" {
  count = var.vm_count
  name = "${var.hostname}-${count.index}"
  memory = var.memory*1024
  vcpu = var.cpu

  cpu = {
    mode = "host-passthrough"
  }

  disk {
       volume_id = libvirt_volume.os_image[count.index].id
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
  value = "${flatten(libvirt_domain.master.*.network_interface.0.mac)}"
}
