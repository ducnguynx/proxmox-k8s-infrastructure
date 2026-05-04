variable "PM_USER" {
  description = "Proxmox API username (e.g., terraform-prov@pve)"
  type        = string
  # No default value is needed if you intend to load it from TF_VAR_ environment variable
}

# Define the PM_PASSWORD variable
variable "PM_PASSWORD" {
  description = "Proxmox API password"
  type        = string
  sensitive   = true # Recommended for passwords
  # No default value is needed
}


variable "pve_api_url"          { type = string }         # https://pve.example.com:8006/
variable "pve_ssh_user"         { type = string }         # "terraform"
variable "pve_ssh_private_key"  { type = string }         # "~/.ssh/terraform_ed25519"

variable "image_url"            { type = string }         # qcow2 cloud image URL


variable "template_id"          { type = number }         # e.g. 9000
variable "template_name"        { type = string }         # e.g. "ubuntu-24.04-cloud"
variable "bridge"               { type = string }         # e.g. "vmbr0"


variable "iso_ds" { type = string }     # e.g. "local" (must allow Import/Snippets)
variable "vm_ds" { type = string }     # e.g. "local" (must allow Import/Snippets)
variable "content_type" { type = string } # e.g. "iso" or "import" based on the dsownloaded image

variable "nodes" {
  type = map(object({
    vm_id = number
  }))
}

# Map of VMs to clone
variable "vms" {
  type = map(object({
    n_name  = string         # The node's name that the VMs will be on
    id      = number
    cpu     = number
    memory  = number         # MiB
    ip4     = string         # "dhcp" or "192.168.1.10/24"
    gw4     = optional(string)
  }))
}
