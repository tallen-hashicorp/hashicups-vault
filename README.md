# HashiCups-Vault

This README provides a guide for setting up a HashiCups + Vault demo using the [hashicups-demosetup](https://github.com/hashicorp/hashicups-setups). You can find the wider HashiCups repository [here](https://github.com/hashicorp-demoapp).

## Start the PostgreSQL DB
To configure Vault, you'll need to start the PostgreSQL database:

```bash
docker compose up -d product-db
```

## Setup Vault
Configure Vault with the following steps:

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
Quickly test to ensure you can retrieve the database credentials:

```bash
vault read database/creds/hashicups-role
psql -h 127.0.0.1 -p 5432 -d products -U v-root-my-role-7z2wfZPqTfVldzlkA0Cs-1697484634
```

## Setup Vault Agent
Since the HashiCups application doesn't currently have Vault integration, we'll use the Vault agent. Update the `VAULT_ADDR` in the Docker Compose file to point at Vault:

```bash
docker compose up -d vault-agent
```

## Deploying HashiCups
Deploy HashiCups using the following command:

```bash
docker compose up -d
```

## Clean-up
To remove the HashiCups resources, run the following command:

```bash
docker compose down
```

---

# K8s
You can also run this in Kubernetes. Please note that it will deploy into the default namespace. If you're using a different namespace, add `-n NAMESPACE` to each `kubectl` command.

## Start the PostgreSQL DB
To configure Vault, start the PostgreSQL database:

```bash
kubectl apply -f k8s/0-config-files.yaml
kubectl apply -f k8s/1-product-db.yaml
```

## Setup Vault
Ensure you update `localhost:30000` to point at the node running the service:

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
Quickly test to ensure you can retrieve the database credentials:

```bash
vault read database/creds/hashicups-role
```

## Create a secret with a Vault token
Create a secret using a root token (replace **[TOKEN]** with your token). In production, consider using a more secure method, like AppRole:

```bash
kubectl create secret generic vault-token --from-literal=vault-token=[TOKEN]
```

## Create a secret with a Vault URL
Create a Vault secret with the external URL of the Vault server. Replace `http://host.docker.internal:8200` if not using Docker locally:

```bash
kubectl create secret generic vault-addr --from-literal=vault-addr=http://host.docker.internal:8200

kubectl get secret vault-addr -o jsonpath='{.data}' | jq -r '.["vault-addr"]' | base64 -d
```

## Run the rest of the app
The HashiCups application currently lacks Vault integration, so we will use the Vault agent. The agent this will be deployed alongside `product-api`, you can see the definition of all this in [2-product-api.yaml](./k8s/2-product-api.yaml). **Make sure to update the `VAULT_ADDR` in `k8s/2-product-api.yaml` to point at Vault:**

```bash
kubectl apply -f k8s
```

## Access
To access the application, use port forwarding since the `NEXT_PUBLIC_PUBLIC_API_URL` in `k8s/4-frontend.yaml` is configured to use an API found at "http://127.0.0.1:8080" via the Nginx service:

```bash
kubectl port-forward svc/nginx-service 8080:80
```

Access the application at [http://127.0.0.1:8080](http://127.0.0.1:8080).