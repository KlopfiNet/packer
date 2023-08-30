# Packer

## Usage
```bash
export ISO_CHECKSUM=...
if [ "$ISO_CHECKSUM" == "none" ]; then
    # Check if target ISO already exists - required as checksum is set to "none"
    bash launch.sh
fi

export VAULT_ADDR=http://10.0.1.152:8200

vault login
export VAULT_TOKEN=$(vault token create -policy="default" -period=4h | awk '$1 == "token" { print $2 }')

packer init
packer build main.pkr.hcl
```