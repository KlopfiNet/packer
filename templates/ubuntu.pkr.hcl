# To use vault, env vars must be set (VAULT_ADDR / VAULT_TOKEN)

# REF:
# https://tekanaid.com/posts/hashicorp-packer-build-ubuntu22-04-vmware

packer {
  required_plugins {
    prxomox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# -------------------------------------------------

locals {
  pm_api_token_id        = vault("secret/proxmox/api_token_id", "value")
  pm_api_token_secret    = vault("secret/proxmox/api_token_secret", "value")
  template_user_password = vault("secret/proxmox/ubuntu_template_vm_user", "value")
  pm_api_url             = "https://10.0.1.10:8006/api2/json"
}

variable "ubuntu_release_full" {
  type    = string
  default = "ubuntu-22.04.3-live-server-amd64"
}

variable "iso_hash" {
  type = string
  # Prefix with sha256:<hash>
  # If set to 'none', execute pre-flight script first
  # https://developer.hashicorp.com/packer/plugins/builders/proxmox/iso#iso_checksum
}

variable "http_directory" {
  type    = string
  default = "ubuntu-init"
}

# -------------------------------------------------

source "proxmox-iso" "ubuntu-generic" {
  boot_wait = "5s"
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"<wait>",
    "<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  disks {
    disk_size    = "30G"
    storage_pool = "vms"
    type         = "scsi"
  }
  #cloud_init = true

  memory = 1536 #1024
  # Required, as packer only supplements 512MB by default, leading to kernel panics

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  http_directory = var.http_directory
  vm_id          = 10311

  iso_url          = "https://releases.ubuntu.com/jammy/${var.ubuntu_release_full}.iso"
  iso_storage_pool = "local"
  iso_download_pve = true
  iso_checksum     = var.iso_hash
  unmount_iso      = true

  ssh_username = "ansible"
  ssh_password = local.template_user_password
  ssh_timeout  = "20m"

  node                     = "hv"
  proxmox_url              = local.pm_api_url
  username                 = local.pm_api_token_id
  token                    = local.pm_api_token_secret
  insecure_skip_tls_verify = true

  template_name        = "ubuntu-server-generic"
  template_description = "${var.ubuntu_release_full} - Generated on ${timestamp()}"
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
    playbook_file = "./playbooks/provision.yml"
  }
}
