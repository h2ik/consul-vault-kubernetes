# Running Consul+Vault on Kubernetes

!!! This is a modified clone from [drud/vault-consul-on-kube](https://github.com/drud/vault-consul-on-kube) !!!

This process will bring up a 3-member consul cluster and a two vault servers running in an HA configuration.

Consul starter was from [Kelsey Hightower's Consul-on-Kubernetes](https://github.com/kelseyhightower/consul-on-kubernetes)
Thanks!

## Overview

A cluster of three [consul](https://github.com/hashicorp/consul) servers provides an HA back-end for two [vault](https://github.com/hashicorp/vault) servers.

Consul is not exposed outside the cluster. Vault is exposed on a
load-balancer service via https.

## What makes this work

- Services for each consul member and vault member
- Deployments for each (because they require some minor separate configuration)
- One service exposes the consul UI
- One load-balancer service exposes the vault servers to outside world

### Usage

This guide assumes you have a running consul install in your cluster with ACL enabled, If you do not, please follow the [consul](../consul) guide before doing this.

### Create a key that vault will use to access consul (vault-consul-key)

#### Kubernetes Job

Generate a `uuid` for the vault token and set it in the payload
```
export CONSUL_VAULT_TOKEN=`uuid`
sed -Ei "s/\"ID\": \"(.*)\"/\"ID\": \"${CONSUL_VAULT_TOKEN}\"/" ./vault-acl-payload.json
```

Send the payload to Kubernetes
```
kubectl create configmap vault-acl-payload --from-file=./vault-acl-payload.json
```

Start the `create-vault-acl` job to complete create the acl token for Vault
```
kubectl create -f jobs/create-vault-acl.yaml
```

Ensure the `create-vault-acl` job has completed:

```
kubectl get jobs
```
```
NAME               DESIRED   SUCCESSFUL   AGE
create-vault-acl   1         1            33s
```

Save the key to a secret in kubernetes.

```
kubectl create secret generic vault-consul-key --from-literal=consul-key="${CONSUL_VAULT_TOKEN}"
```

#### Manual Way
We'll use the consul web UI to create this, which avoids all manner of
quote-escaping problems.

1. Port-forward port 8500 of <consul-0> to local: `kubectl port-forward consul-0 8500`
2. Hit http://127.0.0.1:8500/ui with browser.
3. Visit the settings page (gear icon) and enter your `acl_master_token`.
3. Click "ACL"
4. Add an ACL with name vault-token, type client, rules:
```
key "vault/" {
  policy = "write"
}
service "vault" {
  policy = "write"
}
session "" {
  policy = "write"
}
```
5. Capture the newly created vault-token and with it (example key here):
``` sh
$ kubectl create secret generic vault-consul-key --from-literal=consul-key=<token from consul here>
```

### Create the Services

```
kubectl apply -f services
```

### Optionaly create the ingress
If you want vault to be avaiable outisde the cluster, set the hostname in [ingress/vault-ingress.yaml](./ingress/vault-ingress.yaml) and then create the ingress in kubernetes 

```
kubectl apply -f ingress/vault-ingress.yaml
```


### Vault Deployment
You are now ready to deploy the vault instances:

``` sh
$ kubectl apply -f deployments/vault-1.yaml -f deployments/vault-2.yaml
```

### Vault Initialization

It's easiest to access the vault in its initial setup on the pod itself,
where HTTP port 9000 is exposed for access without https. You can decide
how many keys and the recovery threshold using args to `vault init`

``` sh
$ kubectl exec -it <vault-1*> /bin/sh

$ vault init
or
$ vault init -key-shares=1 -key-threshold=1

```

This provides the key(s) and initial auth token required.

Unseal with

``` sh
$ vault unseal
```

(You should not generally use the form `vault unseal <key>` because it probably will leave traces of the key in shell history or elsewhere.)

and auth with
``` sh
$ vault auth
Token (will be hidden): <initial_root_token>
```

Then access <vault-2*> in the exact same way (`kubectl exec -it vault-2* /bin/sh`) and unseal it.
It will go into standby mode.

### Vault usage

On your local/client machine:

``` sh
$ kubectl port-forward <vault-1*> 8200
$ export VAULT_ADDR=http://127.0.0.1:8200
$ vault status
$ vault auth <root_or_other_token>

$ vault write /secret/test1 value=1
Success! Data written to: secret/test1

$ vault list /secret
Keys
----
junk
test1

$ vault read /secret/test1
Key             	Value
---             	-----
refresh_interval	768h0m0s
value           	1
```

### Vault failover testing

* Both vaults must be unsealed
* Restart active vault pod with kubectl delete pod <vault-1*>
* <vault-2*> should become leader "Mode: active"
* Unseal <vault-1*> - `vault status` will find it in "Mode: standby"
* Restart/kill <vault-2*> or kill the process
* <vault-1*> will become active

Note that if a vault is sealed, its "READY" in `kubectl get po` will be 1/2, meaning
that although the logger container is ready, the vault container is not - it's not
considered ready until unsealed.
