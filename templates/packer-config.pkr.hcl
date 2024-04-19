packer {
  required_plugins {
    prxomox = {
      version = ">= 1.1.7"
      source  = "github.com/hashicorp/proxmox"
    }

    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}