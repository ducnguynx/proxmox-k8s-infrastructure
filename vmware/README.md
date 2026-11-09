# Kubernetes VMs on ESXi through vCenter

This is a separate Terraform root: run Terraform here, with a separate state
from the Proxmox root. It creates new VMs on existing ESXi infrastructure managed
by vCenter. It does not migrate Proxmox VMs, disks, state, or Kubernetes data.
Standalone ESXi without vCenter is outside this configuration's scope.

## Repository review and design

Terraform creates the VM folder and content library, imports Canonical's Ubuntu
24.04 OVA directly from its URL, and deploys the nodes. No manual template build,
Python preparation script, or local image cache is needed. Each VM gets its SSH
user/key, passwordless sudo, hostname, static IPv4 network, DNS, guest tools and
Python through cloud-init. The private SSH key stays local.

### Cloud-init through the virtual CD/DVD

The stock Ubuntu OVA uses ISO transport for its OVF environment. Each VM includes
`cdrom { client_device = true }`, and Terraform sets the image's existing
`instance-id`, `hostname`, and base64 `user-data` vApp properties.

The OVA does not expose a `network-config` property. The cloud-init template
therefore uses a one-time `bootcmd` to write persistent Netplan settings and apply
the static IP before package installation. It also disables subsequent cloud-init
network generation so reboots keep those settings. On a network without DHCP,
the first boot may wait for the initial DHCP attempt to time out before the
static configuration runs. The NIC is matched by its VMXNET3 driver; its original
interface name is preserved.

The readable guest configuration lives in
[`templates/cloud-init.yaml.tftpl`](templates/cloud-init.yaml.tftpl) and
[`templates/netplan.yaml.tftpl`](templates/netplan.yaml.tftpl).

This intentionally keeps the mount approach simple. After cloud-init completes,
you may still need to disconnect the virtual CD/DVD before vMotion. If vCenter
requires removing the device, that may require powering off the VM. Terraform
keeps the device declared for provisioning, so a later apply can restore a
manually removed device. There is no automatic detach or hot-removal guarantee.
Do not disconnect the media while first-boot cloud-init is still running.

References: [provider vApp ISO transport requirements](https://registry.terraform.io/providers/vmware/vsphere/2.14.2/docs/resources/virtual_machine),
[cloud-init bootcmd](https://docs.cloud-init.io/en/latest/reference/modules.html#bootcmd).

The existing `../ansible/` roles target Debian/Ubuntu and are shared. Inventory
here groups VMs by an explicit `role` instead of matching their names. Nothing
writes to the Proxmox inventory. Control-plane hosts are sorted by name; keep the
bootstrap host first when extending a cluster.

The existing bootstrap has limitations that this platform addition does not
resolve: Kubernetes 1.30.14 is end-of-life, kube-vip is pinned to a release
candidate, the kubeadm configuration uses v1beta3, and a CNI must be installed
separately. The shared kubeadm template uses IPv4-only Pod and Service networks,
matching the IPv4 node networking configured here. Changes to shared roles and
templates affect both stacks.
Review the [Ansible runbook](../ansible/README.md) before running playbooks.

The existing Proxmox provider also contains a literal SSH password and disables
TLS verification. Rotate that credential if it has been used. This root uses
provider credential environment variables and verifies TLS by default.

## Prerequisites

Install Terraform on the controller. The provider/controller and vSphere
environment need access to the OVA URL and the vCenter/ESXi upload endpoints.

Provide a vCenter account permitted to manage VM folders and content libraries,
import/deploy OVF items, allocate resources/storage, and assign the target
network. The datacenter, resource pool, datastore, and port group must exist.
Use storage and a network available on the hosts you intend to migrate between.
The stack creates the configured folder and library. If they already exist,
import them into their corresponding Terraform resources before applying.

Create an SSH key pair if you do not already have one. Set `ssh_public_key_file`
and `ssh_private_key_file` to the matching files; defaults are `~/.ssh/tf_rsa.pub`
and `~/.ssh/tf_rsa`. Only the public key is supplied to cloud-init.

The supported image is Canonical's single-disk Ubuntu 24.04 cloud OVA, which
includes cloud-init and VMware Tools support. Other appliances are not
interchangeable with this configuration. Disk
sizes must be at least the upstream image's 10 GiB; cloud-init grows the root
partition/filesystem to the requested virtual disk size.

## Two-host placement and storage

The top-level `datastore` holds the content library and is the default destination
for VM disks. The library stores one copy of the OVA; a VM can be deployed onto a
different datastore. It does not need a separate library for each ESXi host.

Each VM may override these settings:

| VM field | Purpose | If omitted |
| --- | --- | --- |
| `host` | ESXi hostname/IP as registered in vCenter | vCenter selects a host within the resource pool |
| `datastore` | Destination datastore for that VM's disks | Uses the top-level `datastore` |
| `resource_pool` | VM resource pool path | Uses the top-level `resource_pool` |

For two hosts **in the same cluster**, use the cluster pool (for example
`Cluster/Resources`) globally. Set each VM's `host` and, with local storage, its
`datastore`. The [example variables](terraform.tfvars.example) show this layout.

For two hosts **outside a shared cluster**, use their separate resource pools:

```hcl
resource_pool = "esxi-01.lab.internal/Resources"
datastore     = "esxi-01-local"

vms = {
  control-0 = {
    role = "control", cpu = 2, memory = 4096, disk_gb = 40
    ip4  = "192.168.1.170/24"
    host = "esxi-01.lab.internal"
  }
  worker-0 = {
    role = "worker", cpu = 4, memory = 8192, disk_gb = 60
    ip4           = "192.168.1.171/24"
    host          = "esxi-02.lab.internal"
    datastore     = "esxi-02-local"
    resource_pool = "esxi-02.lab.internal/Resources"
  }
}
```

The selected datastore and port group must be accessible to the selected host,
and the host must belong to the selected pool's compute resource. Both hosts
must be managed by the same vCenter/datacenter for this root. Use unique datastore
names or datacenter-relative datastore paths if names are ambiguous.

With shared storage, use its name globally and omit per-VM datastore overrides.
With local storage, moving a VM to the other host also requires moving its disks
unless the destination host can access the source datastore. Disconnecting the
cloud-init CD/DVD alone does not make local VM disks accessible on another host.

Explicit placement is managed configuration: after a manual vMotion/storage move,
a subsequent plan may propose moving a VM back to its configured host/datastore.
Update the placement fields to keep the new location, or omit `host` to let
vCenter manage host placement. A configured host is not a DRS affinity rule.

Reference: [provider host selection and VM migration](https://registry.terraform.io/providers/vmware/vsphere/2.14.2/docs/resources/virtual_machine).

## Provision

From this directory:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit all vCenter inventory names, networking and VM sizes in terraform.tfvars.
export TF_VAR_vcenter_user='terraform@vsphere.local'
read -rsp 'vCenter password: ' TF_VAR_vcenter_password
export TF_VAR_vcenter_password
terraform init
terraform fmt -check
terraform validate
terraform plan -out=cluster.tfplan
terraform apply cluster.tfplan
```

The example has one control-plane VM and one worker; use three control-plane VMs
for stacked-etcd HA and distribute them across hosts with appropriate vSphere
placement policies. Reserve static addresses and an unused kube-vip address on the
same Layer 2 network as the control-plane nodes. Trust your vCenter CA on the
controller; `allow_unverified_ssl = true` is an explicit lab-only option.

The default `image_url` follows Canonical's `current` build. Prefer a dated build
URL for reproducible deployments. Reapplying an unchanged URL reuses the library
item; it does not poll for newer builds. Changing the URL replaces the library
item and can replace VMs that reference it. Review the plan before refreshing it.

Keep state and saved plans private. Do not reuse the Proxmox Terraform state.
Commit `.terraform.lock.hcl` for reproducible provider installs. Terraform does
not wait for all cloud-init package installs to finish. Before running the
Kubernetes roles, wait on every node:

```bash
cd ../ansible
ansible -i ../vmware/inventory.ini all -b -m command -a 'cloud-init status --wait'
cd ../vmware
```

Cloud-init settings are first-boot settings; editing a key, user or IP does not
reliably reconfigure an already bootstrapped guest. Update existing nodes
deliberately, or explicitly replace disposable VMs after reviewing the plan.
Switching from the earlier prepared GuestInfo image to this stock OVA also
replaces the library item and can replace its VMs. Nothing has been applied as
part of this repository change.

## Bootstrap with the shared Ansible roles

Copy the shared variables into an ignored local override file, then review
versions, VIP, networking, and interface names:

```bash
cp ../ansible/group_vars/all.yml cluster-vars.yml
cd ../ansible
ansible-inventory -i ../vmware/inventory.ini --graph
ansible -i ../vmware/inventory.ini all -m ping
ansible -i ../vmware/inventory.ini control_nodes -m command -a 'ip -brief address'
```

Cloud-init matches the single VMXNET3 NIC by driver. Verify its actual name
(often `ens192`) and set `kube_vip_interface` in `vmware/cluster-vars.yml`
accordingly. The Kubernetes version pin is intentional for the planned migration;
keep the later CNI installation compatible with that version and IPv4 subnets.
All playbook commands below run from `ansible/`, so the
existing Ansible configuration and shared role paths are used. The explicit
inventory selects the new VMs; extra variables override shared defaults.

```bash
ansible-playbook -i ../vmware/inventory.ini setup-control-plane.yaml \
  -e @../vmware/cluster-vars.yml --list-hosts
ansible-playbook -i ../vmware/inventory.ini setup-control-plane.yaml \
  -e @../vmware/cluster-vars.yml --forks 1
# Follow the shared runbook to verify the API and install a compatible CNI.
ansible-playbook -i ../vmware/inventory.ini join-worker-nodes.yaml \
  -e @../vmware/cluster-vars.yml
```

This creates kubeadm VMs; VMware cloud-provider integration and vSphere CSI
storage are separate follow-up work. Offline validation does not prove
compatibility with your vCenter environment; review a real plan, verify
`cloud-init status --wait`, and test vMotion on a disposable VM first.

## Offline checks

```bash
terraform fmt -check -recursive
terraform validate
# Terraform >= 1.7; mocks prevent downloads and vCenter calls.
terraform test
```
