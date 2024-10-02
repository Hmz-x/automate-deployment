# Set Up Workflow and Manifests Bash Script

This script automates the process of checking for a workflow file (`check_workflows()`), generating Kubernetes configurations (`generate_k8s_configs()`),
and pushing these configurations to a GitOps repository (`push_to_gitops_repo()`). The script is designed to work with multiple repositories, including a microservice repository, pipeline repository, and GitOps repository, using environment variables for configuration and GitHub API for repo interactions.

## Customization

### Environment Variables
The script is configured using a set of environment variables stored in a `.env` file. These variables control key
aspects of the script's behavior, including which repositories are accessed and how configurations are generated.
Users should edit the `.env` file to customize the script for their specific use cases. The variables in the `.env` file include:

- **`GITHUB_TOKEN`**: GitHub Token used to authenticate requests against repositories.

- **`MICROSERVICE_REPO`**: The microservice repository where the workflow file will be uploaded.
- **`MICROSERVICE_REPO_BRANCH`**: The branch in the microservice repository where the workflow file will be added.

- **`PIPELINE_REPO`**: The repository from which the workflow file will be fetched.
- **`PIPELINE_REPO_BRANCH`**: The branch in the pipeline repository that contains the workflow file.
- **`PIPELINE_WORKFLOW_FILE`**: The workflow file to be downloaded and uploaded.

- **`GITOPS_REPO`**: The GitOps repository where Kubernetes configuration files will be pushed.
- **`GITOPS_REPO_BRANCH`**: The branch in the GitOps repository where the files will be added.
- **`GITOPS_MICROSERVICES_DIR`**: The directory in the GitOps repository where the files will be pushed.

- **`APP_NAME`**: The name of the application being deployed.
- **`REPLICA_COUNT`**: The number of replicas for the application in the Kubernetes configuration.
- **`APP_IMAGE`**: The Docker image to be used for the application.
- **`TARGET_PORT`**: The port that the application exposes internally.
- **`SERVICE_PORT`**: The port that the application exposes externally.

This is what `.env` might look like:

```
# GitHub Token
GITHUB_TOKEN="ghp_AbCdEf1234567890ghijklmnopqrstUVWXyz"

# Microservice Repo
MICROSERVICE_REPO="frostlinegames-backend/microservice-test"
MICROSERVICE_REPO_BRANCH="main"

# Pipeline Repo
PIPELINE_REPO="frostlinegames-backend/GithubActionsPipeline"
PIPELINE_REPO_BRANCH="combined-workflows"
PIPELINE_WORKFLOW_FILE="full_security_and_build_pipeline.yml"

# GitOps Repo
GITOPS_REPO="frostlinegames-backend/gitops-test"
GITOPS_REPO_BRANCH="main"
GITOPS_MICROSERVICES_DIR="manifests/microservices"

# Kubernetes Configuration
APP_NAME="my-app-service"
REPLICA_COUNT=4
APP_IMAGE="registry.frostlinegames.com/my-app-service:v2.5.1"
TARGET_PORT=8080
SERVICE_PORT=443
```

## How to Use

1. Clone this repository and navigate to the directory.
2. Edit the `.env` file with your repository information and application details.
3. Run the script:
   ```bash
   ./setup_workflow_and_manifests.sh
   ```
