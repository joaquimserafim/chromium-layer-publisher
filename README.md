# 🪣 chromium-layer-publisher

![Shell Script](https://img.shields.io/badge/bash-5.1+-blue?logo=gnu-bash)
![AWS Lambda](https://img.shields.io/badge/AWS-Lambda-orange?logo=awslambda)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

Automate the process of publishing [Sparticuz Chromium](https://github.com/Sparticuz/chromium) as an AWS Lambda Layer — fully scripted, robust, and production-ready.

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
