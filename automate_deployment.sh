#!/bin/bash

# Source .env for GITHUB_TOKEN
. .env

# Microservice Repo Constants
MICROSERVICE_REPO="Hmz-x/auto-tagger"
MICROSERVICE_REPO_BRANCH="master"
WORKFLOW_DIR=".github/workflows"
MICROSERVICE_REPO_API_BASE="https://api.github.com/repos/${MICROSERVICE_REPO}"

LOCAL_WORKFLOW_DIR="workflows"

# GitOps Repo Constants
GITOPS_REPO="https://${GITHUB_TOKEN}@github.com/frostlinegames-backend/gitops-test.git"
GITOPS_REPO_BRANCH="main"

# Array for dependencies
deps_arr=("jq")

# Step 0) Function to check if dependencies are installed
check_deps() {
  for dep in "${deps_arr[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      echo "Dependency $dep not found in PATH. Exit Code 1" 2>&1
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
    "${MICROSERVICE_REPO_API_BASE}/contents/${WORKFLOW_DIR}/${file_name}")

  if [ "$response" -eq 201 ]; then
    echo "Successfully uploaded $file_name."
  else
    echo "Failed to upload $file_name. Response code: $response"
  fi
}

check_workflows()
{
  echo -e "~~~~~ Checking For Workflows ~~~~~\n"

  for local_file in "${LOCAL_WORKFLOW_DIR}"/*; do
    file_name="$(basename "$local_file")"
    
    # Check if the file exists in the repository
    response=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token $GITHUB_TOKEN" \
      "${MICROSERVICE_REPO_API_BASE}/contents/${WORKFLOW_DIR}/${file_name}?ref=${MICROSERVICE_REPO_BRANCH}")

    if [ "$response" -eq 200 ]; then
      echo "File ${file_name} already exists in the repository. Skipping..."
    else
      echo "File ${file_name} does not exist in the repository. Uploading..."
      upload_file_to_repo "$local_file"
    fi
  done
}

# Step 0: Check if dependencies are installed
check_deps

# Step 1: Check if workflow files exist in repo, if not upload to repo
check_workflows
