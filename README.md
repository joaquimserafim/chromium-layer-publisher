# 🪣 chromium-layer-publisher

[![Create Release](https://github.com/joaquimserafim/chromium-layer-publisher/actions/workflows/release.yml/badge.svg)](https://github.com/joaquimserafim/chromium-layer-publisher/actions/workflows/release.yml)
[![Lint Shell Scripts](https://github.com/joaquimserafim/chromium-layer-publisher/actions/workflows/lint.yml/badge.svg)](https://github.com/joaquimserafim/chromium-layer-publisher/actions/workflows/lint.yml)
![Shell Script](https://img.shields.io/badge/bash-5.1+-blue?logo=gnu-bash)
![AWS Lambda](https://img.shields.io/badge/AWS-Lambda-orange?logo=awslambda)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

Automate the process of publishing [Sparticuz Chromium](https://github.com/Sparticuz/chromium)
as an AWS Lambda Layer — fully scripted, robust, and production-ready.

---

## 🚀 Overview

This tool:

- ✅ Performs **AWS CLI + credential preflight** checks
- 🪣 Creates **random, region-aware S3 buckets** automatically
- ⬇️ **Downloads** Chromium layer ZIPs directly from GitHub
- ⬆️ **Uploads** them to S3 with retry logic
- 🪄 **Publishes** the layer to AWS Lambda
- 🔁 Uses **exponential backoff** (2s → 4s → 8s → 16s → 32s) for retries
- 🔗 Outputs and saves the **Lambda Layer ARN** (`layer_arn.txt`)
- 🧹 Cleans up temporary S3 buckets unless you tell it to keep them

---

## 📦 Features

| Feature                      | Description                                                                          |
| ---------------------------- | ------------------------------------------------------------------------------------ |
| 🧠 **Safe Preflight**        | Validates AWS CLI, credentials, region, and identity before doing anything.          |
| 🪣 **Smart Bucket Handling** | Creates a random bucket or reuses an existing one (with cleanup flags).              |
| 🔄 **Retry Logic**           | Retries failed downloads, S3 uploads, and Lambda publishes with exponential backoff. |
| 💾 **ARN Output**            | Prints and saves the published Lambda Layer ARN to `layer_arn.txt`.                  |
| 💻 **Cross-Platform**        | Works on macOS, Linux, and CI environments (GitHub Actions, GitLab CI, etc.).        |

---

## ⚙️ Usage

### 🔧 Basic Command

```bash
./publish-chromium-layer.sh [ARCH] [VERSION] [AWS_REGION] [--keep-bucket|--cleanup] [--bucket NAME] [--profile NAME]
```

## 🧠 Examples

```bash
# Default run: creates random bucket and cleans up after
./publish-chromium-layer.sh

# Specify architecture and region
./publish-chromium-layer.sh arm64 v141.0.0 eu-west-1

# Keep the random bucket after publishing
./publish-chromium-layer.sh x64 v141.0.0 --keep-bucket

# Use a specific AWS CLI profile
./publish-chromium-layer.sh arm64 --profile dev --cleanup

# Publish to an existing bucket
./publish-chromium-layer.sh --bucket my-chromium-layers --cleanup

```

## 🧩 Run Without Installation

You can run **chromium-layer-publisher** instantly — no clone or setup required.  
Just execute the script directly from GitHub:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/joaquimserafim/chromium-layer-publisher/v1.0.0/publish-chromium-layer.sh) x64 v141.0.0 us-east-1 --cleanup
```
