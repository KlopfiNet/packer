# REF:
# https://tekanaid.com/posts/hashicorp-packer-build-ubuntu22-04-vmware

# -------------------------------------------------

source "proxmox-iso" "ubuntu-generic" {
  boot_wait = "5s"
  boot_command = [
    "<wait>c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>",
  ]

  additional_iso_files {
    iso_storage_pool = "local"
    cd_files         = ["${path.root}/cloud-init"]
    cd_label         = "cidata"
    unmount          = true
  }

  disks {
    disk_size    = "30G"
    storage_pool = "local-lvm" #"vms"
    type         = "scsi"
  }

  memory = 1536 #1024

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  vm_id = var.packer_vm_template_id

  iso_url          = "https://releases.ubuntu.com/jammy/${var.iso_filename}"
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

  template_name        = "ubuntu-server-generic"
  template_description = "${var.iso_filename} - Generated on ${timestamp()}"
  task_timeout         = "10m"
}

build {
  sources = ["source.proxmox-iso.ubuntu-generic"]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo -n '.'; sleep 1; done"
    ]
  }

  provisioner "ansible" {
    playbook_file = "${path.root}/../playbooks/provision.yaml"
  }
}