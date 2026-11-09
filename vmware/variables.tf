variable "vcenter_user" {
  type      = string
  sensitive = true
}
variable "vcenter_password" {
  type      = string
  sensitive = true
}
variable "vcenter_server" {
  description = "vCenter hostname or IP, without https://."
  type        = string
}
variable "allow_unverified_ssl" {
  type    = bool
  default = false
}
variable "datacenter" { type = string }
variable "resource_pool" {
  description = "Default VM resource pool path, e.g. Cluster/Resources or esxi-01.lab.internal/Resources."
  type        = string
}
variable "datastore" {
  description = "Content library backing datastore and default VM datastore; VMs can override it."
  type        = string
}
variable "network" {
  description = "Port group accessible to the target ESXi hosts."
  type        = string
}
variable "image_url" {
  description = "Canonical Ubuntu 24.04 single-disk OVA URL; use a dated build for reproducibility."
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.ova"
  validation {
    condition     = startswith(var.image_url, "https://")
    error_message = "Use an HTTPS OVA URL."
  }
}
variable "content_library_name" {
  type    = string
  default = "homelab-templates"
}
variable "folder" {
  description = "VM folder managed by this stack, relative to the datacenter VM folder."
  type        = string
  default     = "Kubernetes"
}
variable "ssh_public_key_file" {
  description = "Public key installed in each VM; the private key stays on the controller."
  type        = string
  default     = "~/.ssh/tf_rsa.pub"
}
variable "domain" {
  type    = string
  default = "lab.internal"
}
variable "gateway" { type = string }
variable "dns_servers" {
  type = list(string)
  validation {
    condition     = length(var.dns_servers) > 0
    error_message = "Provide at least one DNS server."
  }
}
variable "ansible_user" {
  description = "User created by cloud-init with SSH access and passwordless sudo."
  type        = string
  default     = "duc"
}
variable "ssh_private_key_file" {
  type    = string
  default = "~/.ssh/tf_rsa"
}
variable "vms" {
  description = "Single-NIC VMs with static IPv4 CIDRs; memory in MiB and disk size in GiB."
  type = map(object({
    role          = string
    cpu           = number
    memory        = number
    disk_gb       = number
    ip4           = string
    host          = optional(string)
    datastore     = optional(string)
    resource_pool = optional(string)
  }))
  validation {
    condition = length(var.vms) > 0 && alltrue([
      for name, vm in var.vms :
      contains(["control", "worker"], vm.role) &&
      can(regex("^[a-z][a-z0-9-]{0,62}$", name)) &&
      can(cidrnetmask(vm.ip4)) && vm.cpu >= 2 &&
      floor(vm.cpu) == vm.cpu && vm.memory >= 2048 && vm.disk_gb >= 10
    ])
    error_message = "Use valid Linux hostnames, control/worker roles, IPv4 CIDRs, integer CPUs >= 2, memory >= 2048 MiB and disks >= 10 GiB."
  }
  validation {
    condition     = anytrue([for vm in var.vms : vm.role == "control"])
    error_message = "At least one control-plane VM is required."
  }
  validation {
    condition     = length(distinct([for vm in var.vms : split("/", vm.ip4)[0]])) == length(var.vms)
    error_message = "VM IPv4 addresses must be unique."
  }
}
