# OS REBRANDING PRODUCTION PIPELINE 

## Table of Contents
- [0.1 Prerequisites](#01-prerequisites)
- [0.2 Stable Branch of Official HAOS](#02-stable-branch-of-official-haos)
- [0.3 Rebranded Branch](#03-rebranded-branch)
- [0.4 Upload Image to GHCR](#04-upload-image-to-ghcr)
- [1.0 Frontend](#10-frontend)
  - [1.1 Rebranding Scripts](#11-rebranding-scripts)
  - [1.2 How to Compile / Build](#12-how-to-compile--build)
- [2.0 Core](#20-core)
  - [2.1 Repack Official Core with Modified Frontend](#21-repack-official-core-with-modified-frontend)
  - [2.2 Custom Core Image](#22-custom-core-image)
- [3.0 Supervisor](#30-supervisor)
- [6. Operating System](#6-operating-system)

---

## 0.1 Prerequisites 
* All repositories and packages are at the `github siksil` organisation. 
* The version JSON is hosted via GitHub repo pages at: `https://siksil.github.io/version/`. 
* Update this regularly to match both official and custom registries and versions.

## 0.2 Stable Branch of Official HAOS 
You should rebase our codebase from here: 
* `core` -> `master` 
* `frontend` -> `master` 
* `supervisor` -> `main` 
* `op-system` -> `main` 

## 0.3 Rebranded Branch 
These are not to be used for other purposes:
* `production`: For stable production rollout (after testing everything on dev). 
* `dev`: For testing rollout.
* `base`: For rebasing with the official HAOS stable release branch. 
* Other branches may be created, but make sure to delete them after use. 

## 0.4 Upload Image to GHCR 
* Make sure the docker daemon is properly loaded (e.g., Docker Desktop or others).
* Login to GitHub Docker:
  ```bash
  docker login ghcr.io -u YOUR_PERSONAL_GITHUB_USERNAME
  ```
  *(Note: You will have to create a personal token first for read, write, and delete permissions.)* 
* Upload to ghcr: 
  ```bash
  docker push <image>
  ```
  **Example:**
  ```bash
  docker push ghcr.io/siksil/qemuarm-64-airadeck-core:2026.4.2
  ```

## 1.0 Frontend (dev container)

### 1.1 Rebranding Scripts
Run the rebranding scripts: 
```bash
./patch_brand.sh # rebrand text [cite: 35]
./patch_colors.sh # swap palette [cite: 36]
```
Run the image replacement script (work in progress). 

### 1.2 How to Compile / Build 
1. Install dependencies (first time only): 
   ```bash
   script/setup
   ```
2. Production build (output goes to `hass_frontend/` for HA)
   * For normal frontend output .whl goes to dist/ directory
     ```bash
     ./script/release
     ```
   * For landing page:
     ```bash
     landing-page/script/develop
     ```

## 2.0 Core

### 2.1 Repack Official Core with Modified Frontend (Easy for Testing)

* The example is for `qemuarm-64`. Change it to your architecture and tag your version (Intel: `qemux86-64` | Rasp-Pi: `qemuarm64`).
* Create a `Dockerfile` in an empty directory, and place the `.whl` file there.

```dockerfile
# Create this Dockerfile in an empty directory [cite: 55]
# Start with the official Home Assistant Core image as the base. [cite: 56]
# Using the qemux86-64/qemuarm-64 machine type as a standard baseline. [cite: 57]
FROM ghcr.io/home-assistant/qemuarm-64-homeassistant:2026.4.2 [cite: 58, 59]

# Copy your custom wheel file into the container's temporary directory [cite: 60]
COPY home_assistant_frontend-*.whl /tmp/ [cite: 61]

# Force pip to install your custom wheel, overwriting the vanilla Home Assistant core/frontend packages [cite: 62]
RUN pip3 install --no-cache-dir --upgrade --force-reinstall /tmp/home_assistant_frontend-*.whl [cite: 63]

# Clean up the temporary file to keep the image size small [cite: 63]
RUN rm /tmp/home_assistant_frontend-*.whl [cite: 64]
```

**Build and Tag:** 
```bash
docker build -t <package:tag>
```
**Example:** 
```bash
docker build -t ghcr.io/siksil/qemuarm-64-airadeck-core:2026.4.2
```

### 2.2 Custom Core Image 
* **Note:** Place the `.whl` frontend package on the root directory of the core workspace.
* Docker build the core: 
* Extract the version from `pyproject.toml` (currently 2026.4.3):
  ```bash
  export VERSION=$(grep -E '^version = ".*"' pyproject.toml | cut -d '"' -f 2)
  ```
* Build the AeonDeck image (tag it appropriately; there can be multiple tags): *
  ```bash
  docker build --build-arg BUILD_FROM=<codebase> -t package:tag .
  ``` 
  *Note that there can be multiple `-t package:tag`. Also note the `.` at the end.

**Example: for amd64 (Intel)** 
```bash
docker build --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base-python:3.14-alpine3.21" -t ghcr.io/siksil/qemux86-64-airadeck-core:2026.4.2 -t aeon-core:latest .
```

**Example for arm64 (Raspberry Pi, Mac)** 
```bash
docker build --platform linux/arm64 --build-arg BUILD_FROM="ghcr.io/home-assistant/aarch64-base-python:3.14-alpine3.21" -t ghcr.io/siksil/qemuarm-64-airadeck-core:2026.4.2 .
```

Push it to ghcr. [See 0.4 Upload Image to GHCR](#04-upload-image-to-ghcr). 

## 3.0 Supervisor [cite: 87]
*(Must run in a devcontainer)* 
* Check the links given in `FILES_TO_PATCH.txt`. 

**Build:** [
```bash
docker buildx build --platform linux/arm64 --tag YOUR_REGISTRY_PATH/aarch64-hassio-supervisor:latest --load .
```
* Upload to ghcr 

## 6. Operating System 
*(Dev container recommended)* 
* Check the file for replacements: `LIST_OF_FILES.txt`. 
* Enter Build:
  ```bash
  ./scripts/enter.sh
  ```
* Make: `make <arch>` 
  * **Example:**
    ```bash
    make generic_aarch64
    ```
* Check `output>images`. 
