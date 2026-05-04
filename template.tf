resource "proxmox_virtual_environment_download_file" "cloudimg_per_node" {
  for_each           = var.nodes
  node_name          = each.key
  datastore_id       = var.iso_ds
  content_type       = var.content_type
  url                = var.image_url
}

resource "proxmox_virtual_environment_vm" "template_per_node" {
  
    depends_on = [proxmox_virtual_environment_download_file.cloudimg_per_node]
  
  for_each  = var.nodes
  node_name = each.key
  vm_id     = each.value.vm_id  
  template  = true
  started   = false
  name      = "template-debian-clouds-${each.key}"

  agent { enabled = false }

  cpu {
    type  = "host"
    cores = 1
  }

  memory {
    dedicated = 2048
  }

  network_device {
    model     = "virtio"
    bridge   = var.bridge
    firewall = false
  }

  serial_device { device = "socket" }

  disk {
    interface    = "scsi0"
    file_id      = proxmox_virtual_environment_download_file.cloudimg_per_node[each.key].id
    file_format  = "qcow2"
    size         = 10
  }


  boot_order = ["scsi0"]
}

