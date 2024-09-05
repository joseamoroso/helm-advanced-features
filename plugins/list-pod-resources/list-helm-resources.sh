#!/bin/bash

# Check if helm is installed
if ! command -v helm &> /dev/null
then
    echo "Helm could not be found. Please install Helm to use this plugin."
    exit 1
fi

# Render the Helm chart to YAML
rendered_yaml=$(helm template "$@")

# Extract CPU resource requests and limits, considering the number of replicas
echo "CPU Resources in the Helm chart:"
echo "$rendered_yaml" | awk '
/kind: Deployment/ { in_deployment = 1 }
/replicas:/ { if (in_deployment) replicas = $2 }
/resources:/ { if (in_deployment) in_resources = 1 }
/limits:/ { if (in_resources) in_limits = 1 }
/requests:/ { if (in_resources) in_requests = 1 }
/cpu:/ {
    if (in_limits) {
        limits_cpu = $2
        total_limits_cpu += limits_cpu * replicas
        in_limits = 0
    }
    if (in_requests) {
        requests_cpu = $2
        total_requests_cpu += requests_cpu * replicas
        in_requests = 0
    }
}
/---/ { in_deployment = 0; in_resources = 0; replicas = 1 }
END {
    print "Total CPU Requests: " total_requests_cpu
    print "Total CPU Limits: " total_limits_cpu
}'

exit 0
