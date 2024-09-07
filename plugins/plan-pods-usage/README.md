# Plan Pods Usage Helm Plugin

## Overview

The `plan-pods-usage` Helm plugin helps you analyze and plan the resource usage of your Kubernetes pods. It extracts and processes resource definitions from your Helm charts, providing insights into CPU and memory allocations.

## Requirements

- `yq`

## Installation

To install the `plan-pods-usage` plugin, follow these steps in the [plugins/plan-pods-usage](./) directory:

```sh
helm plugin install ./
```

## Usage

This section provides detailed usage instructions, including the command syntax, description, arguments, options, and example usage scenarios.

```sh
helm plan-pods-usage [path-to-helm-chart]
```

### Arguments

- `<chart-path>`: Path to the Helm chart directory.

### Options

- `-h, --help`: Show this help message and exit.

### Example Usage

```sh
helm plan-pods-usage /path/to/chart
helm plan-pods-usage /path/to/chart -f /path/to/custom-values.yaml
helm plan-pods-usage /path/to/chart -f /path/to/custom-values.yaml -n my-namespace
```

## Clean-up

```sh
helm plugin uninstall plan-pods-usage
```

## TODO

- [ ] Add support for other resources units than CPU(m) and memory(Mi).
