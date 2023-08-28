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

locals {
  pm_api_token_id     = vault("secret/proxmox/api_token_id", "value")
  pm_api_token_secret = vault("secret/proxmox/api_token_secret", "value")
  pm_api_url          = "https://10.0.1.10:8006/api2/json"
}

variable "ubuntu_release" {
  type    = string
  default = "22.04.3"
}

variable "iso_hash" {
  type    = string
  default = "none"
  # Prefix with sha256:<hash>
  # https://developer.hashicorp.com/packer/plugins/builders/proxmox/iso#iso_checksum
}

variable "http_directory" {
  type    = string
  default = "ubuntu-init"
}

source "proxmox-iso" "ubuntu-generic" {
  boot_wait = "10s"
  boot_command = [
    # CD install
    "e<down><down><down><end>",
    " autoinstall ds=nocloud;",
    "<F10>"
  ]

  # TODO: Find a way to get ubuntu-init data

  disks {
    disk_size    = "30G"
    storage_pool = "vms"
    type         = "scsi"
  }

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  http_directory = var.http_directory

  iso_url          = "https://releases.ubuntu.com/jammy/ubuntu-${var.ubuntu_release}-live-server-amd64.iso"
  iso_storage_pool = "local"
  iso_download_pve = true
  iso_checksum     = var.iso_hash
  unmount_iso      = true

  cloud_init = true

  node                     = "hv"
  proxmox_url              = local.pm_api_url
  username                 = local.pm_api_token_id
  password                 = local.pm_api_token_secret
  insecure_skip_tls_verify = true

  template_name        = "ubuntu-server-generic-${var.ubuntu_release}"
  template_description = "Generated on ${timestamp()}"
}

build {
  sources = ["source.proxmox-iso.ubuntu-generic"]
}