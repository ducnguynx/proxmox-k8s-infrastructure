# Terraform >= 1.7 for mock providers. Plan only: no downloads or vCenter calls.
mock_provider "vsphere" {}
mock_provider "local" {}

variables {
  vcenter_server      = "vcenter.example.com"
  vcenter_user        = "test"
  vcenter_password    = "test"
  datacenter          = "Homelab"
  resource_pool       = "Cluster/Resources"
  datastore           = "shared"
  network             = "VM Network"
  gateway             = "192.168.1.1"
  dns_servers         = ["192.168.1.1"]
  ssh_public_key_file = "tests/fixtures/test_key.pub"
  vms = {
    control-0 = {
      role = "control", cpu = 2, memory = 4096, disk_gb = 40
      ip4  = "192.168.1.170/24"
    }
    worker-0 = {
      role = "worker", cpu = 4, memory = 8192, disk_gb = 60
      ip4  = "192.168.1.171/24"
    }
  }
}

run "cloud_init_with_iso_transport" {
  command = plan

  assert {
    condition     = length(vsphere_virtual_machine.node["control-0"].cdrom) == 1 && vsphere_virtual_machine.node["control-0"].cdrom[0].client_device
    error_message = "The stock Ubuntu OVA needs a client-device CD/DVD for ISO transport."
  }
  assert {
    condition     = yamldecode(yamldecode(base64decode(vsphere_virtual_machine.node["control-0"].vapp[0].properties["user-data"])).bootcmd[0][7]).network.ethernets.primary.addresses[0] == "192.168.1.170/24"
    error_message = "The first-boot netplan configuration must contain the node static CIDR."
  }
  assert {
    condition     = yamldecode(base64decode(vsphere_virtual_machine.node["worker-0"].vapp[0].properties["user-data"])).users[0].ssh_authorized_keys[0] == trimspace(file("tests/fixtures/test_key.pub"))
    error_message = "Cloud-init must install the configured public SSH key."
  }
  assert {
    condition     = yamldecode(base64decode(vsphere_virtual_machine.node["worker-0"].vapp[0].properties["user-data"])).users[0].sudo[0] == "ALL=(ALL) NOPASSWD:ALL"
    error_message = "Ansible needs passwordless sudo."
  }
  assert {
    condition     = vsphere_folder.kubernetes.path == "Kubernetes" && vsphere_content_library_item.ubuntu.file_url == var.image_url
    error_message = "Create the folder and import the upstream OVA directly."
  }
}

run "two_hosts_with_local_datastores_and_separate_pools" {
  command = plan

  variables {
    resource_pool = "esxi-01.lab.internal/Resources"
    vms = {
      control-0 = {
        role = "control", cpu = 2, memory = 4096, disk_gb = 40
        ip4  = "192.168.1.170/24"
        host = "esxi-01.lab.internal"
      }
      worker-0 = {
        role          = "worker", cpu = 4, memory = 8192, disk_gb = 60
        ip4           = "192.168.1.171/24"
        host          = "esxi-02.lab.internal"
        datastore     = "esxi-02-local"
        resource_pool = "esxi-02.lab.internal/Resources"
      }
    }
  }

  override_data {
    target = data.vsphere_host.target["esxi-01.lab.internal"]
    values = { id = "host-11" }
  }
  override_data {
    target = data.vsphere_host.target["esxi-02.lab.internal"]
    values = { id = "host-22" }
  }
  override_data {
    target = data.vsphere_datastore.storage
    values = { id = "datastore-11" }
  }
  override_data {
    target = data.vsphere_datastore.vm["esxi-02-local"]
    values = { id = "datastore-22" }
  }
  override_data {
    target = data.vsphere_resource_pool.pool
    values = { id = "resgroup-11" }
  }
  override_data {
    target = data.vsphere_resource_pool.vm["esxi-02.lab.internal/Resources"]
    values = { id = "resgroup-22" }
  }

  assert {
    condition = (
      vsphere_virtual_machine.node["control-0"].host_system_id == "host-11" &&
      vsphere_virtual_machine.node["control-0"].datastore_id == "datastore-11" &&
      vsphere_virtual_machine.node["control-0"].resource_pool_id == "resgroup-11"
    )
    error_message = "The control plane must use host 1 and the default datastore/pool."
  }
  assert {
    condition = (
      vsphere_virtual_machine.node["worker-0"].host_system_id == "host-22" &&
      vsphere_virtual_machine.node["worker-0"].datastore_id == "datastore-22" &&
      vsphere_virtual_machine.node["worker-0"].resource_pool_id == "resgroup-22"
    )
    error_message = "The worker must use host 2 and its overridden datastore/pool."
  }
  assert {
    condition     = one(vsphere_content_library.homelab.storage_backing) == "datastore-11"
    error_message = "VM datastore overrides must not move the content library."
  }
}
