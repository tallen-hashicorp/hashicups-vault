# hashicups-vault
Hashicups + Vault Demo using the [hashicups-demosetup](https://github.com/hashicorp/hashicups-setups) the wider hashcups repo can be [here](https://github.com/hashicorp-demoapp)


## Start the PostgreSQL DB
This needs to be started in order to configure our vault
```bash
docker compose up -d product-db
``` 

## Setup Vault
```bash
export VAULT_ADDR='http://127.0.0.1:8200'
vault login

vault write database/config/my-postgresql-database \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="my-role" \
    connection_url="postgresql://{{username}}:{{password}}@localhost:5432/products" \
    username="postgres" \
    password="password" \
    password_authentication="scram-sha-256"

vault write database/roles/my-role \
    db_name="my-postgresql-database" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

## Test Vault
Do a quick test to ensure you can get the DB creds
```bash
vault read database/creds/my-role
psql -h 127.0.0.1 -p 5432 -d products -U v-root-my-role-7z2wfZPqTfVldzlkA0Cs-1697484634
```

## Setup Vault Agent
The hashicups application doesnt curranlty have a vault intergation so we will use the vault agent. This will configure the config file in this directory. 
**You will need to update the vault-agent/agent-template.hcl file to point to your directory**, I have not found a better way to do this yet.
```
cd cd vault-agent/
vault agent -config=agent-config.hcl \                                                                                                                                  ✔  08:49:03 pm  
   -config=agent-template.hcl
```

## Deploying HashiCups
Navigate to this folder using your CLI and run the following.

```
docker compose up -d
```

## Clean-up
Run the following command to clean up and remove the HashiCups resources.

```
docker compose down
```

