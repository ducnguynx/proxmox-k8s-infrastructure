terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.80.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pve_api_url
  username = var.PM_USER
  password = var.PM_PASSWORD
  insecure  = true

#   # bpg provider uses SSH to run a couple of qm/pvesm steps under the hood
#   ssh {
#     username    = var.pve_ssh_user         # e.g. "terraform" PAM user
#     private_key = var.pve_ssh_private_key  # path to private key
#     agent       = true
#   }

    ssh {
    agent       = true
    username = "root"
    password = "ducanh2376"
  }
}