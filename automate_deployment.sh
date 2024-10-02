#!/bin/bash

# Change to the directory where the script is located
cd "$(dirname "$0")" || exit 1
# Source .env for configured environment variables
set -o allexport
. .env
set +o allexport

# Project constants
PROJ_NAME="automate_deployment"
TEMPLATE_DIR="k8s_config_templates"

# Microservice Repo Constants
MICROSERVICE_WORKFLOW_DIR=".github/workflows"
MICROSERVICE_REPO_API_BASE="https://api.github.com/repos/${MICROSERVICE_REPO}"

# Pipeline Repo Constants
PIPELINE_WORKFLOW_DIR=".github/workflows"
PIPELINE_REPO_RAW="https://raw.githubusercontent.com/${PIPELINE_REPO}/${PIPELINE_REPO_BRANCH}/${PIPELINE_WORKFLOW_DIR}/${PIPELINE_WORKFLOW_FILE}"
TEMP_WORKFLOW_FILE="/tmp/${PROJ_NAME}/${PIPELINE_WORKFLOW_FILE}"

# Array for dependencies
deps_arr=("jq" "envsubst")

# Array for required environment variables
env_vars_arr=("GITHUB_TOKEN" "MICROSERVICE_REPO" "MICROSERVICE_REPO_BRANCH"
  "PIPELINE_REPO" "PIPELINE_REPO_BRANCH" "PIPELINE_WORKFLOW_FILE" "APP_NAME"
  "REPLICA_COUNT" "APP_IMAGE" "TARGET_PORT" "SERVICE_PORT")

check_env_vars() {
  for env_var in "${env_vars_arr[@]}"; do
    if [ -z "${!env_var}" ]; then
      echo "Error: Environment variable $env_var is not set. Exiting." >&2
      exit 1
    fi
  done
}

check_deps() {
  for dep in "${deps_arr[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      echo "Dependency $dep not found in PATH. Exit Code 1" >&2
      exit 1
    fi
  done
}

# Function to upload a new file to the repo
upload_file_to_repo() {
  local file_path=$1
  local file_name="$(basename "$file_path")"
  
  # Read the file content and base64 encode it
  base64_content=$(base64 -w 0 "$file_path")
  
  # Construct the JSON payload correctly and escape double quotes
  json_payload=$(jq -nc --arg content "$base64_content" --arg branch "$MICROSERVICE_REPO_BRANCH" \
    --arg message "Add $file_name to workflows" \
    '{message: $message, content: $content, branch: $branch}')
  
  # Send API request to upload the file
  response=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT -H "Authorization: token $GITHUB_TOKEN" \
    -d "$json_payload" \
    "${MICROSERVICE_REPO_API_BASE}/contents/${MICROSERVICE_WORKFLOW_DIR}/${file_name}")

  if [ "$response" -eq 201 ]; then
    echo "Successfully uploaded $file_name."
  else
    echo "Failed to upload $file_name. Response code: $response"
  fi
}

# Function to download the workflow file from the pipeline repo with authentication
download_pipeline_workflow() {
  echo "Downloading ${PIPELINE_WORKFLOW_FILE} from ${PIPELINE_REPO} to /tmp..."
  
  # Create directory if it doesn't exist
  mkdir -p "/tmp/${PROJ_NAME}"

  # Use GITHUB_TOKEN for authentication when accessing a private repository
  curl -H "Authorization: token $GITHUB_TOKEN" \
       -s -o "${TEMP_WORKFLOW_FILE}" "${PIPELINE_REPO_RAW}"

  if [ -f "${TEMP_WORKFLOW_FILE}" ]; then
    echo "Downloaded ${PIPELINE_WORKFLOW_FILE} to ${TEMP_WORKFLOW_FILE}."
  else
    echo "Failed to download ${PIPELINE_WORKFLOW_FILE}."
    exit 1
  fi
}

check_workflows() {
  echo -e "~~~~~ Checking For Workflows ~~~~~\n"

  # Check if the file exists in the repository
  response=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $GITHUB_TOKEN" \
    "${MICROSERVICE_REPO_API_BASE}/contents/${MICROSERVICE_WORKFLOW_DIR}/${PIPELINE_WORKFLOW_FILE}?ref=${MICROSERVICE_REPO_BRANCH}")

  if [ "$response" -eq 200 ]; then
    echo "File ${PIPELINE_WORKFLOW_FILE} already exists in the microservice repository. Skipping..."
  else
    echo "File ${PIPELINE_WORKFLOW_FILE} does not exist in the microservice repository. Checking /tmp for existing file..."
    
    if [ -f "${TEMP_WORKFLOW_FILE}" ]; then
      echo "Using existing file from ${TEMP_WORKFLOW_FILE}."
    else
      echo "File not found in /tmp. Downloading it..."
      download_pipeline_workflow
    fi

    echo "Uploading ${TEMP_WORKFLOW_FILE} to microservice repository..."
    upload_file_to_repo "${TEMP_WORKFLOW_FILE}"
  fi
}

# Function to generate Kubernetes configs from templates
generate_k8s_configs() {
  echo -e "\n~~~~~ Generating K8s Configs ~~~~~\n"

  local OUTPUT_DIR="/tmp/${PROJ_NAME}"
  [ ! -d "$OUTPUT_DIR" ] && mkdir -p "$OUTPUT_DIR"

  # Find all .yaml and .yml files in TEMPLATE_DIR
  find "$TEMPLATE_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \) | while read -r template; do
    # Extract OBJECTTYPE from the filename (before .yaml or .yml)
    filename=$(basename -- "$template")
    OBJECTTYPE="${filename%%.*}"

    # Output file name format: $APP_NAME-$OBJECTTYPE.yaml
    OUTPUT_FILE="$OUTPUT_DIR/${APP_NAME}-${OBJECTTYPE}.yaml"

    # Substitute environment variables using envsubst and write the result to the output file
    envsubst < "$template" > "$OUTPUT_FILE"

    echo "$OUTPUT_FILE generated."
  done
}

# Step 0: Check if all required environment variables are set
check_env_vars

# Step 1: Check if dependencies are installed
check_deps

# Step 2: Check if the workflow file exists in the repo, if not upload to repo
check_workflows

# Step 3: Generate Kubernetes configurations from templates and output to /tmp/$PROJ_NAME
generate_k8s_configs
