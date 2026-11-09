resource "vsphere_folder" "kubernetes" {
  path          = var.folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_content_library" "homelab" {
  name            = var.content_library_name
  description     = "Kubernetes cloud images managed by Terraform"
  storage_backing = [data.vsphere_datastore.storage.id]
}

resource "vsphere_content_library_item" "ubuntu" {
  name        = "ubuntu-2404-cloudimg"
  description = "Canonical Ubuntu 24.04 cloud image"
  library_id  = vsphere_content_library.homelab.id
  type        = "ovf"
  file_url    = var.image_url
}

resource "vsphere_virtual_machine" "node" {
  for_each         = var.vms
  name             = each.key
  folder           = vsphere_folder.kubernetes.path
  host_system_id   = each.value.host == null ? null : data.vsphere_host.target[each.value.host].id
  resource_pool_id = each.value.resource_pool == null ? data.vsphere_resource_pool.pool.id : data.vsphere_resource_pool.vm[each.value.resource_pool].id
  datastore_id     = each.value.datastore == null ? data.vsphere_datastore.storage.id : data.vsphere_datastore.vm[each.value.datastore].id
  num_cpus         = each.value.cpu
  memory           = each.value.memory
  scsi_type        = "lsilogic"
  enable_disk_uuid = true

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  disk {
    label            = "disk0"
    size             = each.value.disk_gb
    thin_provisioned = true
  }
  clone {
    template_uuid = vsphere_content_library_item.ubuntu.id
  }
  # The stock Ubuntu OVA delivers cloud-init's OVF environment through a CD/DVD.
  cdrom {
    client_device = true
  }
  vapp {
    properties = {
      "instance-id" = "iid-${each.key}"
      "hostname"    = "${each.key}.${var.domain}"
      "user-data" = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
        hostname   = each.key
        domain     = var.domain
        user       = var.ansible_user
        public_key = trimspace(file(pathexpand(var.ssh_public_key_file)))
        netplan = templatefile("${path.module}/templates/netplan.yaml.tftpl", {
          address     = each.value.ip4
          gateway     = var.gateway
          dns_servers = var.dns_servers
          domain      = var.domain
        })
      }))
    }
  }
}

resource "local_file" "inventory" {
  filename        = "${path.module}/inventory.ini"
  file_permission = "0600"
  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    vms         = var.vms
    user        = var.ansible_user
    private_key = pathexpand(var.ssh_private_key_file)
  })
}
