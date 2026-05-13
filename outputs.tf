resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory.ini"
  content  = <<-EOT
[control_nodes]
%{ for k, v in var.vms }%{ if length(regexall("control", k)) > 0 }${k} ansible_host=${split("/", v.ip4)[0]} ansible_user=duc ansible_ssh_private_key_file=../tf_rsa
%{ endif }%{ endfor }

[worker_nodes]
%{ for k, v in var.vms }%{ if length(regexall("worker", k)) > 0 }${k} ansible_host=${split("/", v.ip4)[0]} ansible_user=duc ansible_ssh_private_key_file=../tf_rsa
%{ endif }%{ endfor }
  EOT
}

