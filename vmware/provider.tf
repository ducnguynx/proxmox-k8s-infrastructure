terraform {
  required_version = ">= 1.5.0"
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.14.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Credentials come from sensitive Terraform variables.
provider "vsphere" {
  user                 = var.vcenter_user
  password             = var.vcenter_password
  vsphere_server       = var.vcenter_server
  allow_unverified_ssl = var.allow_unverified_ssl
}
