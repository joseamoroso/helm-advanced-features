# Enforce Security Policies Helm Plugin

## Overview

The `enfore-secrets-policies` Helm plugin validates passwords in the Helm chart's values.yaml file, creates a Kubernetes Secret for the password values, updates Helm templates to reference the secret, and installs the Helm chart."

## Installation

To install the `enfore-secrets-policies` plugin, follow these steps in the [plugins/enfore-secrets-policies](./) directory:

```sh
helm plugin install ./
```

## Usage

This section provides detailed usage instructions, including the command syntax, description, arguments, options, and example usage scenarios.

```sh
helm enfore-secrets-policies [options] <path-to-helm-chart> <chart-release-name>
```

### Arguments

- `<chart-path>`: Path to the Helm chart directory.
- `<chart-name>`: Name of the Helm release (used in helm install).

### Options

- `-h, --help`: Show this help message and exit.
- `-f, --file [file/path]`:  (Optional) Path to the values.yaml file. Default to chart-path/values.yaml

### Example Usage

```sh
helm enfore-secrets-policies /path/to/chart my-release
helm enfore-secrets-policies -f /path/to/custom-values.yaml /path/to/chart my-release
helm enfore-secrets-policies -f /path/to/custom-values.yaml /path/to/chart my-release -n my-namespace
```

## Clean-up

```sh
helm plugin uninstall enfore-secrets-policies
```
