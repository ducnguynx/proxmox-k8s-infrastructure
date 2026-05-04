# Proxmox Kubernetes Infrastructure

This repository contains the Terraform infrastructure-as-code (IaC) required to provision the virtual machines for a Kubernetes cluster from scratch on Proxmox. It handles the virtualization and OS-level bootstrapping phase before Kubernetes is installed.

## Why I Built This
This project is part of a larger blog series documenting the process of setting up a full Kubernetes cluster from scratch. Instead of clicking through the Proxmox GUI, I wanted to define the infrastructure declaratively. This allows the cluster to be recreated consistently, versioned alongside the rest of the project, and provides a solid foundation for zero-touch Kubernetes provisioning.

## Prerequisites

To run this Terraform code, you will need:
1. A **Proxmox Virtual Environment** host or cluster.
2. An **API Token** or username/password from Proxmox with appropriate privileges.
3. **Terraform** installed on your local machine.
4. An SSH key pair generated (`tf_rsa` and `tf_rsa.pub`) placed in the root of this project.
5. A local `terraform.tfvars` file containing your specific secrets and values. Copy the provided template (after you clone the repo) to get started:
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
   ssh-keygen -t rsa -b 4096 -f tf_rsa -N ""
   ```

3. Initialize Terraform
   Downloads the required providers (like `bpg/proxmox`).
   ```bash
   terraform init
   ```

4. Apply the Configuration
   Provisions the virtual machines and cloud-init configurations.
   ```bash
   terraform apply
   ```
