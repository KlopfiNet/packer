source "proxmox-iso" "rocky-generic" {
  boot_wait = "5s"
  boot_command = [
    "<tab><bs><bs><bs><bs><bs>",
    "inst.text inst.ks=cdrom:/ks.cfg<wait><enter>",
  ]
  
  additional_iso_files {
    iso_storage_pool = "local"
    cd_files         = ["${path.root}/ks/ks.cfg"]
    cd_label         = "cidata"
    unmount          = true
  }

  # Rocky doesn't detect disks with LSI
  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "30G"
    storage_pool = "vms"
    type         = "scsi"
  }

  # Memory must be >512MB and cpu_type = x86-64*
  memory   = 2048 #1024
  cpu_type = "x86-64-v2-AES"
  sockets  = 2

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  vm_id          = 10311

  iso_url          = "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/${var.iso_filename}"
  iso_storage_pool = "local"
  iso_download_pve = true
  iso_checksum     = "sha256:${var.iso_hash}"
  unmount_iso      = true

  ssh_username = "ansible"
  ssh_password = var.template_user_password
  ssh_timeout  = "20m"

  node                     = "hv"
  proxmox_url              = var.pm_api_url
  username                 = var.pm_api_token_id
  token                    = var.pm_api_token_secret
  insecure_skip_tls_verify = true

  template_name        = "rocky-server-generic"
  template_description = "Rocky 9.3 - Generated on ${timestamp()}"
  task_timeout         = "10m"
}

build {
  sources = ["source.proxmox-iso.rocky-generic"]

  provisioner "ansible" {
    playbook_file = "${path.root}/../playbooks/provision.yaml"
  }
}
