#!/usr/bin/env bash
set -euo pipefail

# === Usage ===
# ./publish-chromium-layer.sh [ARCH] [VERSION] [AWS_REGION] [--keep-bucket|--cleanup] [--bucket NAME] [--profile NAME]
#
# Examples:
#   ./publish-chromium-layer.sh x64 v141.0.0
#   ./publish-chromium-layer.sh arm64 v141.0.0 eu-west-1 --keep-bucket
#   ./publish-chromium-layer.sh x64 v141.0.0 us-east-1 --cleanup --profile dev

archType="${1:-x64}"
chromiumVersion="${2:-v141.0.0}"
awsRegion="${3:-us-east-1}"

# Shift args
if [ $# -ge 1 ]; then shift; fi
if [ $# -ge 1 ]; then shift; fi
if [ $# -ge 1 ]; then shift; fi

# Flags
userBucket=""
forceCleanup=""
awsProfile=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-bucket) forceCleanup="false"; shift ;;
    --cleanup)     forceCleanup="true";  shift ;;
    --bucket)      userBucket="${2:?Provide a bucket name after --bucket}"; shift 2 ;;
    --profile)     awsProfile="${2:?Provide a profile name after --profile}"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -n "$awsProfile" ]]; then
  export AWS_PROFILE="$awsProfile"
fi
export AWS_DEFAULT_REGION="${awsRegion}"

lambdaArch="$([ "$archType" = "x64" ] && echo "x86_64" || echo "$archType")"
zipFile="chromium-${chromiumVersion}-layer.${archType}.zip"
s3Key="chromiumLayers/${zipFile}"
layerName="chromium"

# === Utility Functions ===
fail() { echo "❌ $*" >&2; exit 1; }
note() { echo "ℹ️  $*"; }

# --- Retry wrapper with exponential backoff ---
retry() {
  local max_attempts="${2:-5}"
  local attempt=1
  local delay=2
  local cmd="$1"

  until eval "$cmd"; do
    if (( attempt >= max_attempts )); then
      fail "Command failed after ${max_attempts} attempts: $cmd"
    fi
    echo "⚠️  Attempt ${attempt}/${max_attempts} failed. Retrying in ${delay}s..."
    sleep "${delay}"
    attempt=$(( attempt + 1 ))
    delay=$(( delay * 2 )) # exponential backoff
  done
}

# --- macOS-safe random suffix generator ---
gen_suffix() {
  if suffix="$(LC_ALL=C tr -dc 'a-z0-9' 2>/dev/null </dev/urandom | head -c 8)"; then
    printf "%s" "${suffix}"
  else
    openssl rand -hex 4
  fi
}

# --- create bucket (region-safe) ---
create_bucket() {
  local name="$1"
  if [ "${awsRegion}" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "${name}" --region "${awsRegion}" >/dev/null
  else
    aws s3api create-bucket \
      --bucket "${name}" \
      --region "${awsRegion}" \
      --create-bucket-configuration "LocationConstraint=${awsRegion}" >/dev/null
  fi
}

# --- Preflight checks ---
preflight() {
  command -v aws >/dev/null 2>&1 || fail "AWS CLI not found."
  command -v curl >/dev/null 2>&1 || fail "curl not found."
  [[ -n "${AWS_DEFAULT_REGION:-}" || -n "${AWS_REGION:-}" ]] || fail "No AWS region set."

  note "Checking AWS credentials..."
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    fail "AWS credentials missing or expired. Run 'aws configure' or 'aws sso login'."
  fi
}

preflight

# --- Create or reuse bucket ---
bucketCreated="false"
if [[ -n "$userBucket" ]]; then
  bucketName="$userBucket"
  echo "🪣 Using provided bucket: ${bucketName}"
  if ! aws s3api head-bucket --bucket "${bucketName}" >/dev/null 2>&1; then
    echo "Bucket not found; creating it..."
    retry "create_bucket ${bucketName}"
    bucketCreated="true"
  fi
else
  while : ; do
    suffix="$(gen_suffix)"
    bucketName="chromium-upload-${suffix}"
    echo "🪣 Creating random bucket: ${bucketName} in ${awsRegion}..."
    if retry "create_bucket ${bucketName}"; then
      bucketCreated="true"
      break
    fi
    note "Retrying bucket creation..."
    sleep 1
  done
fi
echo "✅ Bucket ready: ${bucketName}"

# --- Cleanup policy ---
if [[ -z "$forceCleanup" ]]; then
  if [[ "$bucketCreated" == "true" && -z "$userBucket" ]]; then
    forceCleanup="true"
  else
    forceCleanup="false"
  fi
fi

cleanup() {
  if [[ "${forceCleanup}" == "true" ]]; then
    echo "🧹 Cleaning up bucket: ${bucketName}"
    aws s3 rm "s3://${bucketName}" --recursive >/dev/null 2>&1 || true
    aws s3api delete-bucket --bucket "${bucketName}" --region "${awsRegion}" >/dev/null 2>&1 || true
    echo "✅ Bucket deleted: ${bucketName}"
  else
    echo "ℹ️ Keeping bucket: ${bucketName}"
  fi
}
trap cleanup EXIT

# --- Download Chromium ZIP ---
downloadUrl="https://github.com/Sparticuz/chromium/releases/download/${chromiumVersion}/${zipFile}"
echo "⬇️  Downloading: ${downloadUrl}"
retry "curl -Lf -o '${zipFile}' '${downloadUrl}'"

# --- Upload to S3 ---
echo "⬆️  Uploading ${zipFile} to s3://${bucketName}/${s3Key} ..."
retry "aws s3 cp '${zipFile}' 's3://${bucketName}/${s3Key}'"

# --- Publish Lambda layer with retry ---
echo "🪄 Publishing Lambda layer version..."
publish_output=""
retry "publish_output=\$(aws lambda publish-layer-version \
  --layer-name '${layerName}' \
  --description 'Chromium ${chromiumVersion}' \
  --content 'S3Bucket=${bucketName},S3Key=${s3Key}' \
  --compatible-runtimes nodejs20.x nodejs22.x \
  --compatible-architectures '${lambdaArch}' \
  --output json)"

# --- Extract and display ARN ---
if command -v jq >/dev/null 2>&1; then
  layerArn=$(echo "$publish_output" | jq -r '.LayerVersionArn')
else
  layerArn=$(echo "$publish_output" | grep -o '"LayerVersionArn": *"[^"]*"' | sed 's/.*"LayerVersionArn": *"\([^"]*\)".*/\1/')
fi

echo "🔗 Lambda Layer ARN: ${layerArn}"
echo "${layerArn}" > layer_arn.txt
echo "💾 Saved ARN to layer_arn.txt"

echo "🎉 Published layer '${layerName}' for ${chromiumVersion} (${archType})."
echo "🪣 Bucket: ${bucketName}"