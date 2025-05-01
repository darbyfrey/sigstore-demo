#!/bin/bash
set -euo pipefail

# --- Required Environment Variables ---
# IMAGE_NAME: fully qualified image name (e.g. registry.gitlab.com/owner/project/image:tag)
# CI_COMMIT_SHA: current Git commit SHA
# CI_REPOSITORY_URL: GitLab repository URL
# CI_PROJECT_PATH: GitLab namespace/project
# CI_PIPELINE_ID: GitLab pipeline ID

if [[ -z "${IMAGE_NAME:-}" ]]; then
  echo "Error: IMAGE_NAME is not set"
  exit 1
fi

echo "Generating SLSA provenance for $IMAGE_NAME..."

# Get image digest
IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE_NAME" | cut -d@ -f2)

# Build timestamps
BUILD_STARTED=$(date --utc +%Y-%m-%dT%H:%M:%SZ)
sleep 2  # simulate build time
BUILD_FINISHED=$(date --utc +%Y-%m-%dT%H:%M:%SZ)

# Output file
OUTPUT_FILE="provenance.json"

cat <<EOF > "$OUTPUT_FILE"
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "subject": [
    {
      "name": "$IMAGE_NAME",
      "digest": {
        "sha256": "$IMAGE_DIGEST"
      }
    }
  ],
  "predicate": {
    "builder": {
      "id": "https://gitlab.com/$CI_PROJECT_PATH"
    },
    "buildType": "https://gitlab.com/gitlab-ci",
    "invocation": {
      "configSource": {
        "uri": "$CI_REPOSITORY_URL",
        "digest": {
          "sha1": "$CI_COMMIT_SHA"
        },
        "entryPoint": ".gitlab-ci.yml"
      },
      "parameters": {},
      "environment": {
        "CI_PIPELINE_ID": "$CI_PIPELINE_ID"
      }
    },
    "metadata": {
      "buildStartedOn": "$BUILD_STARTED",
      "buildFinishedOn": "$BUILD_FINISHED",
      "completeness": {
        "parameters": true,
        "environment": true,
        "materials": true
      },
      "reproducible": false
    },
    "materials": [
      {
        "uri": "$CI_REPOSITORY_URL",
        "digest": {
          "sha1": "$CI_COMMIT_SHA"
        }
      }
    ]
  }
}
EOF

echo "Provenance written to $OUTPUT_FILE"
