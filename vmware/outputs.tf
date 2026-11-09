output "node_addresses" {
  value = { for name, vm in var.vms : name => split("/", vm.ip4)[0] }
}
output "inventory_file" {
  value = abspath(local_file.inventory.filename)
}
