# Allow renewal of leases for secrets
path "sys/renew/" {
    policy = "write"
}

# Allow renewal of token leases
path "auth/token/renew/" {
    policy = "write"
}

path "/auth/token/renew-self" {
    policy = "write"
}

# Allow read and list of the secrets
path "secret/*" {
  capabilities = ["read", "list"]
}
