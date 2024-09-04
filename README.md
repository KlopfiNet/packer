# Packer

## Usage
```bash
# Ubuntu
export ISO_CHECKSUM="sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
export VAULT_ADDR=https://vault.apps.klopfi.net

# Rocky
export ISO_CHECKSUM="c7e95e3dba88a1f68fff8b7d4e66adf6f76ac4fba2e246a83c46ab79574c78a8"
export ISO_FILENAME=Rocky-9.4-x86_64-boot.iso

# Check if target ISO already exists - required as checksum is set to "none"
bash pm_iso_prep.sh

export PKR_VAR_pm_api_token_id=$(vault read secret/data/proxmox/api_token_id -format=json | jq .data.data.value -r)
export PKR_VAR_pm_api_token_secret=$(vault read secret/data/proxmox/api_token_secret -format=json | jq .data.data.value -r)
export PKR_VAR_template_user_password=$(vault read secret/data/proxmox/ubuntu_template_vm_user -format=json | jq .data.data.value -r)

TEMPLATE=templates/ubuntu
packer init $TEMPLATE
packer build -var "iso_hash=$ISO_CHECKSUM" -var "iso_filename=$ISO_FILENAME" $TEMPLATE
```

## Notes
The self-hosted runner must have PowerShell installed at `/opt/powershell/`.