# Proxmox Kubernetes Infrastructure

This repository provisions Kubernetes virtual machines on Proxmox with
Terraform, then bootstraps a highly available kubeadm cluster with Ansible and
kube-vip.

## Why I Built This

This project is part of a larger blog series documenting the process of setting up a full Kubernetes cluster from scratch. Instead of clicking through the Proxmox GUI, I wanted to define the infrastructure declaratively. This allows the cluster to be recreated consistently, versioned alongside the rest of the project, and provides a solid foundation for zero-touch Kubernetes provisioning.

## Prerequisites

To run this project, you will need:

1. A **Proxmox Virtual Environment** host or cluster.
2. An **API Token** or username/password from Proxmox with appropriate privileges.
3. **Terraform** installed on your local machine.
4. **Ansible Core** and the `community.general` collection.
5. An SSH key pair at `~/.ssh/tf_rsa` and `~/.ssh/tf_rsa.pub`.
6. A local `terraform.tfvars` file containing your specific secrets and values. Copy the provided template (after you clone the repo) to get started:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

## How to Use

1. Clone the repository
   ```bash
   git clone https://github.com/ducnguynx/terraform-proxmox-k8s.git
   cd terraform-proxmox-k8s
   ```

2. Generate an SSH key pair for the cluster
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/tf_rsa -N ""
   ```

3. Initialize Terraform
   Downloads the required providers (like `bpg/proxmox`).
   ```bash
   terraform init
   ```

4. Review and apply the configuration
   Provisions the virtual machines and cloud-init configurations.
   ```bash
   terraform fmt -check
   terraform validate
   terraform plan
   terraform apply
   ```

   Use static VM addresses. Terraform generates `ansible/inventory.ini`, and a
   VM configured with `ip4 = "dhcp"` will not produce a usable Ansible target.

5. Bootstrap Kubernetes

   Follow the detailed [Ansible cluster runbook](ansible/README.md). It covers
   the reviewed role sequence, required preflight checks, kube-vip, the required
   CNI installation step, validation, reruns, and failure recovery.

> [!WARNING]
> The checked-in Kubernetes `1.30.14` pin is end-of-life, no CNI is bundled,
> and the kube-vip pin is a release candidate. Read the runbook's review status
> and update/test these choices before using the project outside a disposable
> lab.
