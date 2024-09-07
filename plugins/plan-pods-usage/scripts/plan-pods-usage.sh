#!/bin/bash

# Function to display usage and describe options
usage()  {
  echo "Usage: helm plan-pods-usage [path-to-helm-chart]"
  echo ""
  echo "Description:"
  echo "This script renders a Helm chart to YAML and extracts CPU and RAM resource requests."
  echo "Arguments:"
  echo "  <chart-path>        Path to the Helm chart directory."
  echo "Options:"
  echo "  -h, --help          Show this help message and exit."
  echo ""
  echo "Example Usage:"
  echo "  helm plan-pods-usage /path/to/chart"
  echo "  helm plan-pods-usage /path/to/chart -f /path/to/custom-values.yaml"
  echo "  helm plan-pods-usage /path/to/chart -f /path/to/custom-values.yaml -n my-namespace"
  echo ""
}

# Check if the help flag is provided
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

# Check if the chart path is provided
if [ -z "$1" ]; then
  echo "Error: No chart path provided."
  usage
  exit 1
fi

# Path to the Helm chart
chart_path=$1
# Render the Helm chart to YAML
rendered_yaml=$($HELM_BIN template "$chart_path")

deployments=$(echo "$rendered_yaml" | yq e 'select(.kind == "Deployment")' -)
daemonsets=$(echo "$rendered_yaml" | yq e 'select(.kind == "DaemonSet")' -)
statefulsets=$(echo "$rendered_yaml" | yq e 'select(.kind == "StatefulSet")' -)

# Initialize an empty array
resources=()

# Add non-empty results to the array
if [[ -n "$deployments" ]]; then
  resources+=("$deployments")
fi

if [[ -n "$daemonsets" ]]; then
  resources+=("$daemonsets")
fi

if [[ -n "$statefulsets" ]]; then
  resources+=("$statefulsets")
fi

total_cpu_usage=0
total_memory_usage=0
# Print the array elements
for resource in "${resources[@]}"; do
  cpu_usage=$(echo "$resource" | yq '.spec.template.spec.containers[].resources.requests.cpu')
  memory_usage=$(echo "$resource" | yq '.spec.template.spec.containers[].resources.requests.memory')
  replicas=$(echo "$resource" | yq '.spec.replicas')
  #validate if replicas is equal to null
  if [[ $replicas == "null" ]]; then
    replicas=1
  fi
  cpu_request_m=$(echo $cpu_usage | sed 's/m//')
  memory_request_m=$(echo $memory_usage | sed 's/Mi//')
  total_cpu_usage=$((total_cpu_usage + cpu_request_m * replicas))
  total_memory_usage=$((total_memory_usage + memory_request_m * replicas))
done

echo "Total CPU Requests: $total_cpu_usage"m
echo "Total RAM Requests: $total_memory_usage"Mi
exit 0

