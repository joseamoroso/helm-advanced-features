#!/bin/bash

# Check if a file path is provided as an argument
if [ $# -eq 0 ]; then
  VALUES_FILE="values.yaml"
else
  VALUES_FILE="$1"
fi

# Check if the provided file exists
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
  fi
done

# If no password-related field was found
if [[ $found_key -eq 0 ]]; then
  echo "No password-related field (passwords, pwd, credentials, pass) found in $VALUES_FILE"
else
  echo "Validation successful! All password-related fields meet the security requirements."
fi

exit 0
