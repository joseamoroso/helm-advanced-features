#!/bin/bash

# Function to display usage and describe options
usage() {
  echo "Usage: helm plugin secrets-manager <chart-path> <chart-name> [values.yaml path] [options]"
  echo ""
  echo "Description:"
  echo "  This script validates passwords in the Helm chart's values.yaml file, creates a Kubernetes Secret for the"
  echo "  password values, updates Helm templates to reference the secret, and installs the Helm chart."
  echo ""
  echo "Arguments:"
  echo "  <chart-path>        Path to the Helm chart directory."
  echo "  <chart-name>        Name of the Helm release (used in helm install)."
  echo "  [values.yaml path]  (Optional) Path to the values.yaml file. Defaults to '<external-path>/values.yaml'."
  echo ""
  echo "Options:"
  echo "  -h, --help          Show this help message and exit."
  echo ""
  echo "Example Usage:"
  echo "  helm plugin secrets-manager /path/to/chart my-release"
  echo "  helm plugin secrets-manager /path/to/chart my-release /path/to/custom-values.yaml"
  echo "  helm plugin secrets-manager /path/to/chart my-release /path/to/custom-values.yaml -n my-namespace"
  echo ""
  exit 0
}

# Check if the help flag is provided
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
fi

# Check if at least 2 arguments (chart-path and chart-name) are provided
if [ $# -lt 2 ]; then
  usage
fi

# Read the chart path and chart name from arguments
CHART_PATH="$1"
CHART_NAME="$2"

# Set the values.yaml file path (use argument or default to chart-path/values.yaml)
if [ $# -ge 3 ]; then
  VALUES_FILE="$3"
else
  VALUES_FILE="$CHART_PATH/values.yaml"
fi

# Check if the values.yaml file exists
if [[ ! -f "$VALUES_FILE" ]]; then
  echo "Error: $VALUES_FILE file not found!"
  exit 1
fi

# Define an array of keys to check
KEYS=("passwords" "pwd" "credentials" "pass")

# Regular expressions for validation
MIN_LENGTH=8
UPPERCASE_REGEX='[A-Z]'
LOWERCASE_REGEX='[a-z]'
DIGIT_REGEX='[0-9]'
SPECIAL_CHAR_REGEX='[^a-zA-Z0-9]'

SECRET_TEMPLATE=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: userpassword
type: Opaque
data:
EOF
)

# Flag to track if any password-related field was found and validated
found_key=0

# Loop through each key and check if it exists in the values.yaml file
for key in "${KEYS[@]}"; do
  # Extract the value associated with the key from values.yaml
  VALUE=$(grep -E ".*$key:" "$VALUES_FILE" | sed -E 's/^ *[^:]+: *//' | sed 's/"//g')
  # If a value is found for the key
  if [[ ! -z "$VALUE" ]]; then
    found_key=1

    # Check if the length of the value is at least 8
    if [[ ${#VALUE} -lt $MIN_LENGTH ]]; then
      echo "Error: The value for '$key' must be at least 8 characters long"
      exit 1
    fi

    # Check if the password contains at least one uppercase letter
    if ! [[ "$VALUE" =~ $UPPERCASE_REGEX ]]; then
      echo "Error: The value for '$key' must contain at least one uppercase letter"
      exit 1
    fi

    # Check if the password contains at least one lowercase letter
    if ! [[ "$VALUE" =~ $LOWERCASE_REGEX ]]; then
      echo "Error: The value for '$key' must contain at least one lowercase letter"
      exit 1
    fi

    # Check if the password contains at least one digit
    if ! [[ "$VALUE" =~ $DIGIT_REGEX ]]; then
      echo "Error: The value for '$key' must contain at least one digit"
      exit 1
    fi

    # Check if the password contains at least one special character
    if ! [[ "$VALUE" =~ $SPECIAL_CHAR_REGEX ]]; then
      echo "Error: The value for '$key' must contain at least one special character"
      exit 1
    fi

    # Add the password to the secret, base64 encoding the value
    BASE64_VALUE=$(echo -n "$VALUE" | base64)
    SECRET_TEMPLATE+=$'\n'"  passwords: $BASE64_VALUE"

  fi
done

# If no password-related field was found
if [[ $found_key -eq 0 ]]; then
  echo "No password-related field (passwords, pwd, credentials, pass) found in $VALUES_FILE"
else
  echo "Validation successful! All password-related fields meet the security requirements."

  # Write the secret to a YAML file
  SECRET_FILE="$CHART_PATH/templates/password-secret.yaml"
  echo "$SECRET_TEMPLATE" > "$SECRET_FILE"
  
  echo "Secret YAML has been generated: $SECRET_FILE"

  # Replace password references in the Helm chart
  echo "Updating Helm chart templates to reference the secret..."

  # Path to the Helm chart's templates directory
  TEMPLATES_DIR="$CHART_PATH/templates"
  
  # Loop through all template files in the Helm chart
  for template in $TEMPLATES_DIR/*.yaml; do
    for key in "${KEYS[@]}"; do
      # Replace instances of password values with references to the Kubernetes secret
      sed -E -i.bak 's/(value:.*(passwords|pass).*)/valueFrom:\n                secretKeyRef:\n                  name: userpassword\n                  key: passwords/g' $template
    done
  done

  $HELM_BIN install "$CHART_NAME" "$CHART_PATH" -f "$VALUES_FILE"

  rm $TEMPLATES_DIR/*.bak $TEMPLATES_DIR/password-secret.yaml
fi

exit 0
