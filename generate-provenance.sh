#!/bin/bash
set -euo pipefail

# --- Usage ---
# ./generate-provenance.sh path/to/artifact [output-file]
# Example:
# ./generate-provenance.sh dist/my-app ./provenance.json

ARTIFACT_PATH="${1:-}"
OUTPUT_FILE="${2:-provenance.json}"

if [[ -z "$ARTIFACT_PATH" || ! -f "$ARTIFACT_PATH" ]]; then
  echo "Error: valid artifact file path must be provided as the first argument."
  exit 1
fi

ARTIFACT_NAME=$(basename "$ARTIFACT_PATH")
ARTIFACT_HASH=$(sha256sum "$ARTIFACT_PATH" | awk '{print $1}')
BUILD_STARTED=$(date --utc +%Y-%m-%dT%H:%M:%SZ)
sleep 1
BUILD_FINISHED=$(date --utc +%Y-%m-%dT%H:%M:%SZ)

echo "Generating SLSA provenance for artifact: $ARTIFACT_PATH"
echo "SHA256: $ARTIFACT_HASH"

cat <<EOF > "$OUTPUT_FILE"
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "subject": [
    {
      "name": "$ARTIFACT_NAME",
      "digest": {
        "sha256": "$ARTIFACT_HASH"
      }
    }
  ],
  "predicate": {
    "builder": {
      "id": "https://gitlab.com/${CI_PROJECT_PATH:-unknown}"
    },
    "buildType": "https://gitlab.com/gitlab-ci",
    "invocation": {
      "configSource": {
        "uri": "${CI_REPOSITORY_URL:-unknown}",
        "digest": {
          "sha1": "${CI_COMMIT_SHA:-unknown}"
        },
        "entryPoint": ".gitlab-ci.yml"
      },
      "parameters": {},
      "environment": {
        "CI_PIPELINE_ID": "${CI_PIPELINE_ID:-unknown}"
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
        "uri": "${CI_REPOSITORY_URL:-unknown}",
        "digest": {
          "sha1": "${CI_COMMIT_SHA:-unknown}"
        }
      }
    ]
  }
}
EOF

echo "✅ Provenance written to $OUTPUT_FILE"
