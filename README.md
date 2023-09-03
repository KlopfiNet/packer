# Packer

## Usage
```bash
export ISO_CHECKSUM="sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"

export VAULT_ADDR=http://10.0.1.152:8200

vault login
#export VAULT_TOKEN=$(vault token create -policy="proxmox" -period=4h | awk '$1 == "token" { print $2 }')
export VAULT_TOKEN="$(vault token create -policy="proxmox" -ttl=4h | awk '$1 == "token" { print $2 }')"
# Command may fail when executing for the first time.

# Check if target ISO already exists - required as checksum is set to "none"
bash pm_iso_prep.sh

TEMPLATE=ubuntu.pkr.hcl
packer init $TEMPLATE
packer build -var "iso_hash=$ISO_CHECKSUM" $TEMPLATE
```