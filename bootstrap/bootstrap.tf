# variables that can be overriden
variable "hostname" { default = "master" }
variable "memoryMB" { default = 1024*1 }
variable "cpu" { default = 1 }
variable "vm_count" { default = 2 }


# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

# fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "os_image" {
  count = var.vm_count
  name = "${var.hostname}-os_image-${count.index}"
  size =  30737418240
  pool = "default"
  format = "qcow2"
}

# Create the machine
resource "libvirt_domain" "master" {
  # domain name in libvirt, not hostname
  count = var.vm_count
  name = "${var.hostname}-${count.index}"
  memory = var.memoryMB
  vcpu = var.cpu

  disk {
       volume_id = libvirt_volume.os_image[count.index].id
  }
  network_interface {
       network_name = "ocp_auto"
  }

  boot_device {
    dev = [ "hd", "network" ]
  }

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
  required_version = ">= 0.12"
}

output "macs" {
  value = "${flatten(libvirt_domain.master.*.network_interface.0.mac)}"
}

