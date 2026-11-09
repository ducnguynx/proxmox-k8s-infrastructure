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
  endpoint = var.pve_api_url
  username = var.PM_USER
  password = var.PM_PASSWORD
  insecure = true

  ssh {
    agent    = true
    username = "root"
    password = var.pve_ssh_password
  }
}