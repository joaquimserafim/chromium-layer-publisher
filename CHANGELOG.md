## 🚀 What's New (v1.0.0)

### ✨ Features

- Fully automated publishing workflow for Chromium Lambda Layers
- Safe AWS preflight (credentials, region, identity)
- Automatic bucket creation & cleanup
- Exponential backoff retries for downloads, uploads, and Lambda publishes
- ARN output saved to `layer_arn.txt`

### 🧩 Improvements

- Better error handling
- Cleaner logging and UX
- macOS-safe random suffix generation

### 🧹 Housekeeping

- Added MIT license
- Added CI workflows and linting

---

**Install:**

```bash
chmod +x publish-chromium-layer.sh
./publish-chromium-layer.sh
```
