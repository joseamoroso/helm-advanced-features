# Helm Advanced Features

This repository provides some examples of Helm's advanced techniques.

## Table of Contents

1. [Helm Post Rendering with Kustomize](#helm-post-rendering-with-kustomize)
2. [Listing CPU and Memory Requests with Helm Plugin](#listing-cpu-and-memory-requests-with-helm-plugin)
3. [Validating Passwords and Enforcing Security Policies](#validating-passwords-and-enforcing-security-policies)

## Pre-requirements

- kubectl
- helm
- yq

## Helm Post Rendering with Kustomize

To use Helm post rendering we will use a script that uses Kustomize to patch the manifests in a chart without making changes to the project. To use post-rendering with the current configuration and add `NodeAffinity` to the manifests, we need to follow these steps:

Execute the command:

```sh
helm install helm-post-rendering-demo ./charts/helm-advanced-features --post-renderer ./kustomize/kustomize
```

The [kustomize](./kustomize/kustomize) script set the environment variables `$NODE_LABEL_KEY` and `NODE_LABEL_VALUE` that will be used to for to set the nodeAffinity to the corresponding nodes. Then with `kustomize` we applies the patchs to include `nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution`.

### TODO

- [ ] Add support for multiple node labels.

## Listing CPU and Memory Requests with Helm Plugin

To list all CPU and memory requests using the Helm plugin located in [`plugins/plan-pods-usage`](./plugins/plan-pods-usage/), follow the instruction in the plugin [README.md](./plugins/plan-pods-usage/README.md) file.

After installing the Helm plugin we can use the chart in [charts/helm-advanced-features](./charts/helm-advanced-features/) to test the plugin:

```sh
helm plan-pods-usage ./charts/helm-advanced-features
```

This solution will calculate the total CPU and memory resources request for every pod in the chart. This will consider the number of replicas and the resources types: `Deployment`, `StatefullSet`, and `DaemonSet`. We used `yq` to parse the rendered template and make the corresponding operation on each resources.

### TODO

- [ ] Add support for multiple resources units. E.g. CPU(m) and memory(Mi)
- [ ] Improve daemonset calculation as it deploy a replica per node.

## Validating Passwords and Enforcing Security Policies

To validate passwords in the `values.yaml` file and enforce security policies using the `secrets-enforce-policies` plugin, follow the plugin [README.md](./plugins/enfore-secrets-policies/README.md) file instructions.

After installing the Helm plugin we can use the chart in [charts/helm-advanced-features](./charts/helm-advanced-features/) to test the plugin:

```sh
helm enfore-secrets-policies ./charts/helm-advanced-features enfore-secrets-demo
```

This solution consists of two parts:

### First Part

The script validates if it exists a value in the `values.yaml` file that matches the key name with one of the following list `"passwords" "pwd" "credentials" "pass"`. If it finds one, then it validate all these conditions are met:

- Min. length of 8 characters.
- At least 1 upper-case letter.
- At least 1 lower-case letter.
- At least 1 number.
- At least 1 special character.

If a condition is not met, then it throws an error. If everything passes, then we continue to the second part.

### Second Part

After all validations pass, we generate a Kubernetes secret from the value we found on the first part. Then, we replace any reference using the plain secret (e.g. `env[0].value: mysecret`) with a secret reference, e.g: `env[0].valueFrom.secretKeyRef.`. Finally, the script install the Helm chart with all the previous changes.
