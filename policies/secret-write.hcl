# Allow renewal of leases for secrets
path "sys/renew/" {
    policy = "write"
}

# Allow renewal of token leases
path "auth/token/renew/" {
    policy = "write"
}

# Allow full access to secret/*
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
