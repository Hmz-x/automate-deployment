# Automate Deployment Bash Script

This script is designed to automate the process of adding a workflow file (`$PIPELINE_WORKFLOW_FILE`) from a pipeline repository (`$PIPELINE_REPO`) to the corresponding directory (`$MICROSERVICE_WORKFLOW_DIR`) in a microservice repository (`$MICROSERVICE_REPO`). The script checks whether the workflow file exists in the microservice repository's branch (`$MICROSERVICE_REPO_BRANCH`). If the file does not exist, it downloads the file from the pipeline repository and uploads it to the microservice repository.

The workflow file is cached locally in the directory `/tmp/$PROJ_NAME` (path: `/tmp/${PROJ_NAME}/${PIPELINE_WORKFLOW_FILE}`), so subsequent runs of the script avoid downloading the file multiple times. The script uses a GitHub API token for secure access to both public and private repositories.

## Customization

You can customize the script by modifying the following variables within the script to suit different repository configurations:

- **`$MICROSERVICE_REPO`**: The microservice repository where the workflow file will be uploaded.
- **`$MICROSERVICE_REPO_BRANCH`**: The branch in the microservice repository where the workflow file will be added.
- **`$PIPELINE_REPO`**: The repository from which the workflow file will be fetched.
- **`$PIPELINE_REPO_BRANCH`**: The branch in the pipeline repository that contains the workflow file.
- **`$PIPELINE_WORKFLOW_FILE`**: The workflow file to be downloaded and uploaded.

These variables allow flexibility in specifying different repositories, branches, and workflow file paths for various deployment environments.
