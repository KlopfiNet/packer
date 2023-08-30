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
  default = "ubuntu-22.04-live-server-amd64" #"ubuntu-init"
}

# -------------------------------------------------

source "proxmox-iso" "ubuntu-generic" {
  boot_wait = "3s"

  # TODO: https://askubuntu.com/a/1425813
  boot_command = [
    "e<down><down><down><end>",
    " autoinstall cloud-config-url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/user-data<wait>",
    " ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
    "<F10>"
  ]

  disks {
    disk_size    = "30G"
    storage_pool = "vms"
    type         = "scsi"
  }
  cloud_init = true

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  http_directory = var.http_directory

  iso_url          = "https://releases.ubuntu.com/jammy/${var.ubuntu_release_full}.iso"
  iso_storage_pool = "local"
  iso_download_pve = true
  iso_checksum     = var.iso_hash
  unmount_iso      = true

  ssh_username = "ubuntu"
  ssh_password = local.template_user_password

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
}