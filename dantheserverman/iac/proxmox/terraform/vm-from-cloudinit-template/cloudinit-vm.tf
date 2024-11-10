provider "proxmox" {
  pm_api_url = var.pve_api_url
  pm_api_token_id = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "ci-ubuntu" {
 name        = "terraform-test-1"
 target_node = "caerus-pmx"
 cores       = 4
 memory      = 4096
 clone       = "ubuntu24-cloudinit-template"
 onboot      = true
 bootdisk    = "scsi0"
 scsihw      = "virtio-scsi-single"
 desc        = "Ubuntu VM deployed via Terraform and cloudinit"

  disk {
   storage = "caerus-nfs-datastore"
   size = "10G"
   format = "qcow2"
   type = "disk"
   slot = "scsi0"
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