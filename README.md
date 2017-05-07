# Vault with Consul Backend On Kubernetes

This is a combination of two repos [kelseyhightower/consul-on-kubernetes](https://github.com/kelseyhightower/consul-on-kubernetes) and [drud/vault-consul-on-kube](https://github.com/drud/vault-consul-on-kube). 

This first starts with taking the Consul StatefulSets and upgrading them to 0.8.1 and then taking the vault deployments from drud/vault-consul-on-kube and modifing them to work with the statefulset deployments.

## Consul + Vault = Profit

1. Set up [consul](./consul/README.md)
2. Set up [vault](./vault/README.md)
3. Profit!


### Custom Vault Image

:stuck_out_tongue_closed_eyes:

Since we use environment varialbes in our vault config, we are forced to use a custom image for now. It's on the todo to get rid of this, but until that is figured out, we still have to use the custom image.
