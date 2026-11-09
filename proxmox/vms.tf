resource "proxmox_virtual_environment_vm" "vm" {
  for_each        = var.vms
  stop_on_destroy = false
  node_name       = each.value.n_name
  vm_id           = each.value.id
  name            = each.key

  # CLONE from the template created above
  clone {
    vm_id     = proxmox_virtual_environment_vm.template_per_node[each.value.n_name].vm_id
    node_name = each.value.n_name
    # datastore_id = var.vm_ds   # uncomment to force target storage
    full = true # default is linked clone when supported
  }

  agent { enabled = true } # MUST BE FALSE FOR THE FIRST TIME, and then apply again with TRUE

  cpu {
    type  = "host"
    cores = each.value.cpu
  }

  memory {
    dedicated = each.value.memory # Can be different from the template
  }

  network_device {
    model  = "virtio"
    bridge = var.bridge
  }

  # Per-VM cloud-init: hostname, SSH key, and IP config
  initialization {
    datastore_id      = var.vm_ds
    user_data_file_id = proxmox_virtual_environment_file.cloud_config[each.key].id

    ip_config {
      ipv4 {
        address = each.value.ip4
        gateway = (each.value.ip4 == "dhcp" ? null : each.value.gw4)
      }

      dynamic "ipv6" {
        for_each = each.value.ip6 == null ? [] : [each.value]

        content {
          address = ipv6.value.ip6
          gateway = contains(["dhcp", "auto"], ipv6.value.ip6) ? null : ipv6.value.gw6
        }
      }
    }
  }

  serial_device { device = "socket" } # matches template for Ubuntu/Debian
  scsi_hardware = "virtio-scsi-pci"
  boot_order    = ["scsi0"]
}
