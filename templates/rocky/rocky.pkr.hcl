source "proxmox-iso" "rocky-generic" {
  boot_wait = "5s"
  boot_command = [
    "e<down><down><end>",
    "<bs><bs><bs><bs><bs>",
    "inst.text inst.ks=cdrom:/ks.cfg",
    "<leftCtrlOn>x<leftCtrlOff>"
  ]
  
  additional_iso_files {
    iso_storage_pool = "local"
    cd_files         = ["${path.root}/ks"]
    cd_label         = "cidata"
    unmount          = true
  }

  disks {
    disk_size    = "30G"
    storage_pool = "vms"
    type         = "scsi"
  }

  memory = 1536 #1024
  # Required, as packer only supplements 512MB by default, leading to kernel panics

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

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo -n '.'; sleep 1; done"
    ]
  }

  provisioner "ansible" {
    playbook_file = "${path.root}/../playbooks/provision.yaml"
  }
}
