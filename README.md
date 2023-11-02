# hashicups-vault
Hashicups + Vault Demo using the [hashicups-demosetup](https://github.com/hashicorp/hashicups-setups) the wider hashcups repo can be [here](https://github.com/hashicorp-demoapp). 

## Start the PostgreSQL DB
This needs to be started in order to configure our vault
```bash
docker compose up -d product-db
``` 

## Setup Vault
```bash
export VAULT_ADDR='http://127.0.0.1:8200'
vault login

vault secrets enable database

vault write database/config/hashicups-database \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="hashicups-role" \
    connection_url="postgresql://{{username}}:{{password}}@localhost:5432/products" \
    username="postgres" \
    password="password" \
    password_authentication="scram-sha-256"

vault write database/roles/hashicups-role \
    db_name="hashicups-database" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{vname}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

## Test Vault
Do a quick test to ensure you can get the DB creds
```bash
vault read database/creds/hashicups-role
psql -h 127.0.0.1 -p 5432 -d products -U v-root-my-role-7z2wfZPqTfVldzlkA0Cs-1697484634
```

## Setup Vault Agent
The hashicups application doesnt curranlty have a vault intergation so we will use the vault agent. This will configure the config file in this directory. 
**You will need to update the VAULT_ADDR in the docker-compose file to point at vault**, you can leave this as `- VAULT_ADDR=http://host.docker.internal:8200` if you are running Vault on the local machine
```
docker compose up -d vault-agent 
```

## Deploying HashiCups
```
docker compose up -d
```

## Clean-up
Run the following command to clean up and remove the HashiCups resources.

```
docker compose down
```

---

# K8s
We can also run this in K8s, **note this will deploy into default, you may need to add -n NAMESPACE to each kubectl command if you are not using default**

## Start the PostgreSQL DB
This needs to be started in order to configure our vault
```bash
kubectl apply -f k8s/0-config-files.yaml
kubectl apply -f k8s/1-product-db.yaml
```

## Setup Vault
**Make sure to update the localhost:30000 to point at the node running the service**
```bash
export VAULT_ADDR='http://127.0.0.1:8200'
vault login

vault secrets enable database

vault write database/config/hashicups-database \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="hashicups-role" \
    connection_url="postgresql://{{username}}:{{password}}@localhost:30000/products" \
    username="postgres" \
    password="password" \
    password_authentication="scram-sha-256"

vault write database/roles/hashicups-role \
    db_name="hashicups-database" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

## Test Vault
Do a quick test to ensure you can get the DB creds
```bash
vault read database/creds/hashicups-role
```

## Create a secret with a vault token
For this we are going to use a root token, replace TOKEN with your token. **In Production we should look at using something like app role**
```bash
kubectl create secret generic vault-token --from-literal=vault-token=[TOKEN]
```

## Create a secret with a vault URL
Create a vault secret with the external URL of the vault server, replece `http://host.docker.internal:8200` if not using docker localy. 
```bash
kubectl create secret generic vault-addr --from-literal=vault-addr=http://host.docker.internal:8200

kubectl get secret vault-addr -o jsonpath='{.data}' | jq -r '.["vault-addr"]' | base64 -d
```

## Setup Vault Agent
The hashicups application doesnt curranlty have a vault intergation so we will use the vault agent. This will configure the config file in this directory. 
**You will need to update the VAULT_ADDR in k8s/2-product-api.yaml to point at vault**,
```
kubectl apply -f k8s
```