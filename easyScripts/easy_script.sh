#!/bin/bash

# Check that exactly two arguments were provided
if [ $# -ne 2 ]; then
  echo "Usage: $0 method_name value"
  exit 1
fi

method_name="$1"
value="$2"

echo "method_name: $method_name"
echo "value: $value"

# Path to the .env file
env_file=".env"

# Define a mapping from method names to variable names
# Add more mappings as needed
if [ "$method_name" == "deploy-relay" ]; then
  var_name="DEPLOY_RELAY_CONFIG_FILE"
elif [ "$method_name" == "setup-relay" ]; then
  var_name="SETUP_RELAY_CONFIG_FILE"
elif [ "$method_name" == "setManager" ]; then
  var_name="SET_CCMANAGER_CONFIG_FILE"
elif [ "$method_name" == "deploy-cc-manager" ]; then
  var_name="SET_CCMANAGER_CONFIG_FILE"
else
  echo "Invalid method name: $method_name"
  exit 2
fi

# print the variable name
echo $var_name

# Check if the variable exists in the .env file
if grep -q "^$var_name=" "$env_file"; then
  # If it does, use sed to replace the line with the new value
  # show command before executing
  echo "sed -i \"\" \"s/^$var_name=.*/$var_name=\"$value\"/\" \"$env_file\""
  sed -i "" "s|^$var_name=.*|$var_name=\"$value\"|" "$env_file"
  echo "$var_name has been updated to $value in $env_file file."
else
  # If it doesn't, append the new variable and value to the .env file
  echo "$var_name=$value" >> "$env_file"
  echo "$var_name has been added with value $value to $env_file file."
fi