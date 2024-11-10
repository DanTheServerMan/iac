# This defines our provider
# The API URL, TOKEN_ID, and TOKEN_SECRET are all stored in vars.tf (for now) and are in .gitignore for obvious reasons
p
provider "proxmox" {
  pm_api_url = var.pve_api_url
  pm_api_token_id = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "ci-ubuntu" {
 name        = var.vm_name
 # The PVE hostname as seen in the Datacenter object
 target_node = var.pve_hostname
 # The number of instances of this resource created
 count       = var.vm_count
 # Host CPU threads assigned to the VMs (cores)
 cores       = var.vm_cores
 # RAM assigned to the VM
 memory      = var.vm_memory
 # Boolean, defines if a VM will start with the host
 onboot      = var.vm_onboot
 # This is the storage controller
 scsihw      = var.vm_scsihw
 # This is the VM notes of our VM
 desc        = var.vm_desc
 # Sets the boot disk
 bootdisk    = var.vm_bootdisk
 # This is a full (not linked) clone operation. It is REQUIRED for use w/ cloudinit
 # The var is the name of the already-templated VM in ProxMox
 clone       = var.vm_template

 # This defines a disk, its location, size (In GiB), format (ex. qcow2, raw, etc.), type, and slot (ex. scsi0)
 disk {
   storage = var.vm_disk1_datastore
   size = var.vm_disk1_size
   format = var.vm_disk1_format
   type = "disk"
   slot = var.vm_disk1_slot
 }

 # This defines the NIC of our VM, its emulation type, which PVE host bridge it is assigned to, and toggles the firewall
 network {
   model = var.vm_nic1_model
   bridge = var.vm_nic1_bridge
   firewall = var.vm_nic1_firewallst
  }

  serial {
   id = 1
 }
}