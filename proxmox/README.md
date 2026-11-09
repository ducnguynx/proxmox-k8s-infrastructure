# Kubernetes VMs on Proxmox VE

This directory is the Terraform root for provisioning Kubernetes virtual machines on **Proxmox VE** using the `bpg/proxmox` provider.

## Prerequisites

1. A **Proxmox Virtual Environment** host or cluster.
2. An **API Token** or username/password from Proxmox with appropriate privileges.
3. **Terraform** (`>= 1.5.0`) installed on the controller.
4. An SSH key pair at `~/.ssh/tf_rsa` and `~/.ssh/tf_rsa.pub`.

## Usage

From this directory (`proxmox/`):

1. Create your local variable definitions:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   Use static CIDR addresses in `vms` (`outputs.tf` writes `../ansible/inventory.ini` using those static IPv4 addresses).

2. Initialize and apply Terraform (Terraform will interactively prompt you for `PM_USER`, `PM_PASSWORD`, and `pve_ssh_password`):
   ```bash
   terraform init
   terraform fmt -check
   terraform validate
   terraform plan
   terraform apply
   ```

3. Bootstrap Kubernetes using the shared [Ansible runbook](../ansible/README.md).
