data "vsphere_datacenter" "dc" {
  name = var.datacenter
}
data "vsphere_resource_pool" "pool" {
  name          = var.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "storage" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_host" "target" {
  for_each      = toset([for vm in var.vms : vm.host if vm.host != null])
  name          = each.value
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "vm" {
  for_each      = toset([for vm in var.vms : vm.datastore if vm.datastore != null])
  name          = each.value
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_resource_pool" "vm" {
  for_each      = toset([for vm in var.vms : vm.resource_pool if vm.resource_pool != null])
  name          = each.value
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}