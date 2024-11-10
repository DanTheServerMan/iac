provider "proxmox" {
  pm_api_url = var.pve_api_url
  pm_api_token_id = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "ubuntu" {
 name        = "apollo-ubuntu-${count.index}"
 target_node = "caerus-pmx"
 count       = 1
 cores       = 2
 memory      = 2048
 onboot      = true
 scsihw      = "virtio-scsi-single"
 desc        = "Ubuntu VM deployed via Terraform"
 disk {
   storage = "caerus-nfs-datastore"
   size = "50G"
   format = "qcow2"
   type = "disk"
   slot = "scsi0"
 }
 disk {
   storage = "caerus-iso-datastore"
   iso = "caerus-nfs-iso:iso/ubuntu-22.04.4-live-server-amd64.iso"
   type = "cdrom"
   slot = "ide2"
 }
 network {
   model = "virtio"
   bridge = "vmbr0"
   firewall = false
  }

  serial {
   id = 1
 }
}
