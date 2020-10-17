# variables that can be overriden
variable "hostname" { default = "bastion" }
variable "domain" { default = "hetzner.lab" }
variable "cluster_name" { default = "ocp4" }
variable "memory" { default = 6 }
variable "cpu" { default = 2 }
variable "iface" { default = "eth0" }
variable "libvirt_network" { default = "ocp4" }
variable "libvirt_pool" { default= "ocp4" }
variable "vm_volume_size" { default = 20 }
variable "enable_nfs" { default = false }
variable "nfs" { default = { nfs_storage = "storage_image" } }
#variable "mac" { default = "FF:FF:FF:FF:FF:FF" }
variable "network_data" { 
  type = map
  default = {
       hostIP = "192.168.100.31"
       broadcast = "192.168.100.255"
       dns = "192.168.100.1"
       gateway = "192.168.100.1"
       network = "192.168.100.0"
    }
}
# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

# fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "os_image" {
  name = "${var.hostname}-os_image"
  pool = var.libvirt_pool
  source = "https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.1.1911-20200113.3.x86_64.qcow2"
  format = "qcow2"
}

# fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "storage_image" {
  count = var.enable_nfs ? 1 : 0
  name = "${var.hostname}-storage_image"
  pool = var.libvirt_pool
  size = 100*1080000000
  format = "qcow2"
}

# Use CloudInit ISO to add ssh-key to the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "${var.hostname}-commoninit.iso"
  pool = var.libvirt_pool 
  user_data = data.template_file.user_data.rendered
  meta_data = data.template_file.meta_data.rendered
}


data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    hostname = "${var.hostname}.${var.cluster_name}.${var.domain}"
    fqdn = "${var.hostname}.${var.cluster_name}.${var.domain}"  
    iface = "${var.iface}"
  }
}

#Fix for centOS
data "template_file" "meta_data" {
  template = file("${path.module}/network_config.cfg")
  vars = {
    domain = "${var.cluster_name}.${var.domain}"
    hostIP = var.network_data["hostIP"]
    dns = var.network_data["dns"]
    gateway = var.network_data["gateway"]
    network = var.network_data["network"]
    broadcast = var.network_data["broadcast"]
    iface = var.iface
  }
}


# Create the machine
resource "libvirt_domain" "bastion" {
  # domain name in libvirt, not hostname
  name = var.hostname
  memory = var.memory*1024
  vcpu = var.cpu

  disk {
     volume_id = libvirt_volume.os_image.id
  }

  dynamic "disk"  {
     for_each = var.enable_nfs ? var.nfs : {}
     content {
     
     volume_id = libvirt_volume.storage_image[0].id
     }
   }
 
  network_interface {
       network_name = var.libvirt_network
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
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

output "ips" {
  value = "${flatten(libvirt_domain.bastion.*.network_interface.0.addresses)}"
}

output "macs" {
  value = "${flatten(libvirt_domain.bastion.*.network_interface.0.mac)}"
}
