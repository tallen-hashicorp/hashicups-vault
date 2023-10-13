# hashicups-vault
Hashicups + Vault Demo using the [hashicups-demosetup](https://github.com/hashicorp/hashicups-setups) the wider hashcups repo can be [here](https://github.com/hashicorp-demoapp)

## Configure Vault
```bash
vault secrets enable -path=lob_a/workshop/database database

```

## Deploying HashiCups

Navigate to this folder using your CLI and run the following.

```
docker compose up -d
```
## Details

## Clean-up

Run the following command to clean up and remove the HashiCups resources.

```
docker compose down
```
