# cloud-config snippets: one per VM so we can set hostname differently
data "local_file" "ssh_public_key" {
  filename = "./tf_rsa.pub"
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  for_each     = var.vms
  node_name    = each.value.n_name
  datastore_id = var.iso_ds
  content_type = "snippets"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ${each.key}
    users:
      - default
      - name: duc
        groups: sudo
        shell: /bin/bash
        ssh-authorized-keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    package_update: true
    packages:
      - qemu-guest-agent
    runcmd:
      - [ systemctl, enable, --now, qemu-guest-agent ]
    EOF

    file_name = "${each.key}.cloud-config.yaml"
  }
}