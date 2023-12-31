pid_file = "./pidfile"

vault {
   address = "$VAULT_ADDR"
   tls_skip_verify = true
}

auto_auth {
   method {
      type = "token_file"
      config = {
         token_file_path = "/.vault-token"
      }
   }
}