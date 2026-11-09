# Kubernetes Homelab Infrastructure (Proxmox & VMware vSphere)

This repository provisions Kubernetes virtual machines using Terraform on either **Proxmox VE** or **VMware vCenter / ESXi**, and bootstraps a highly available `kubeadm` cluster with **Ansible** and **kube-vip**.

## Repository Structure

| Directory | Purpose |
| --- | --- |
| [`proxmox/`](proxmox/README.md) | Terraform root for provisioning VMs on Proxmox VE (`bpg/proxmox`) |
| [`vmware/`](vmware/README.md) | Terraform root for provisioning VMs on VMware vCenter / ESXi (`vmware/vsphere`) |
| [`ansible/`](ansible/README.md) | Shared Ansible roles and playbooks to bootstrap `kubeadm` + `kube-vip` |
| `diagrams/` & `figures/` | Architecture and workflow Excalidraw diagrams |

## Quick Start

1. **Generate an SSH key pair** (if you don't already have one):
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/tf_rsa -N ""
   ```

2. **Provision VMs on your chosen platform**:
   - **Proxmox VE**: Follow [`proxmox/README.md`](proxmox/README.md) (`cd proxmox && cp terraform.tfvars.example terraform.tfvars`)
   - **VMware vSphere**: Follow [`vmware/README.md`](vmware/README.md) (`cd vmware && cp terraform.tfvars.example terraform.tfvars`)

3. **Bootstrap Kubernetes with Ansible**:
   Follow the [Ansible cluster runbook](ansible/README.md) in `ansible/` to prepare nodes, configure `kube-vip`, initialize the control plane, install a CNI, and join worker nodes.

> [!WARNING]
> The checked-in Kubernetes `1.30.14` pin is end-of-life, no CNI is bundled,
> and the kube-vip pin is a release candidate. Read the runbook's review status
> and update/test these choices before using the project outside a disposable
> lab.
