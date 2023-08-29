# Packer

## Usage
```bash
export VAULT_ADDR=http://10.0.1.152:8200

# Unseal maybe
vault login #...
export VAULT_TOKEN=$(vault token create -policy="default" -period=4h | awk '$1 == "token" { print $2 }')

packer init
packer build main.pkr.hcl
```