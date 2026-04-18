# OS REBRANDING PRODUCTION PIPELINE [cite: 1]

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

## 0.1 Prerequisites [cite: 3]
* All repositories and packages are at the `github siksil` organisation. [cite: 4]
* The version JSON is hosted via GitHub repo pages at: `https://siksil.github.io/version/`. [cite: 5] 
* Update this regularly to match both official and custom registries and versions. [cite: 5]

## 0.2 Stable Branch of Official HAOS [cite: 6]
You should rebase our codebase from here: [cite: 7]
* `core` -> `master` [cite: 8, 9]
* `frontend` -> `master` [cite: 10, 11]
* `supervisor` -> `main` [cite: 12, 13]
* `op-system` -> `main` [cite: 14, 15]

## 0.3 Rebranded Branch [cite: 16]
These are not to be used for other purposes: [cite: 16]
* `production`: For stable production rollout (after testing everything on dev). [cite: 17, 20]
* `dev`: For testing rollout. [cite: 18, 21]
* `base`: For rebasing with the official HAOS stable release branch. [cite: 19, 22]
* Other branches may be created, but make sure to delete them after use. [cite: 23]

## 0.4 Upload Image to GHCR [cite: 24]
* Make sure the docker daemon is properly loaded (e.g., Docker Desktop or others). [cite: 25]
* Login to GitHub Docker: [cite: 26]
  ```bash
  docker login ghcr.io -u YOUR_PERSONAL_GITHUB_USERNAME
  ```
  *(Note: You will have to create a personal token first for read, write, and delete permissions.)* [cite: 27]
* Upload to ghcr: [cite: 28]
  ```bash
  docker push <image>
  ```
  **Example:** `docker push ghcr.io/siksil/qemuarm-64-airadeck-core:2026.4.2` [cite: 29, 30, 31]

## 1.0 Frontend [cite: 32]

### 1.1 Rebranding Scripts [cite: 33]
Run the rebranding scripts: [cite: 34]
```bash
./patch_brand.sh # rebrand text [cite: 35]
./patch_colors.sh # swap palette [cite: 36]
```
Run the image replacement script (work in progress). [cite: 37, 38]

### 1.2 How to Compile / Build [cite: 39]
1. Install dependencies (first time only): [cite: 40]
   ```bash
   script/setup
   ``` [cite: 41]
2. Production build (output goes to `hass_frontend/` for HA): [cite: 42]
   * For normal frontend: `script/build_frontend` [cite: 43]
   * For landing page: `landing-page/script/develop` [cite: 44]
3. Lint before committing: [cite: 45]
   ```bash
   yarn lint
   ``` [cite: 46]
4. Ensure 'build' is installed: `pip install build`. Then run `python3 -m build`. [cite: 47]
5. A `.whl` file will be created at `./dist/home_assistant_frontend-*.whl`. [cite: 48, 49]

## 2.0 Core [cite: 50]

### 2.1 Repack Official Core with Modified Frontend (Easy for Testing) [cite: 51]
* The example is for `qemuarm-64`. Change it to your architecture and tag your version (Intel: `qemux86-64` | Rasp-Pi: `qemuarm64`). [cite: 52, 53]
* Create a `Dockerfile` in an empty directory, and place the `.whl` file there. [cite: 54]

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

**Build and Tag:** [cite: 65]
```bash
docker build -t <package:tag> [cite: 66]
```
**Example:** `docker build -t ghcr.io/siksil/qemuarm-64-airadeck-core:2026.4.2` [cite: 67, 68]

### 2.2 Custom Core Image [cite: 69]
* **Note:** Place the `.whl` frontend package on the root directory of the core workspace. [cite: 70]
* Docker build the core: [cite: 71]
* Extract the version from `pyproject.toml` (currently 2026.4.3): [cite: 72]
  ```bash
  export VERSION=$(grep -E '^version = ".*"' pyproject.toml | cut -d '"' -f 2)
  ``` [cite: 73]
* Build the AeonDeck image (tag it appropriately; there can be multiple tags): [cite: 74]
  ```bash
  docker build --build-arg BUILD_FROM=<codebase> -t package:tag .
  ``` [cite: 74]
  *Note that there can be multiple `-t package:tag`. Also note the `.` at the end.* [cite: 75]

**Example: for amd64 (Intel)** [cite: 76]
```bash
docker build --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base-python:3.14-alpine3.21" -t ghcr.io/siksil/qemux86-64-airadeck-core:2026.4.2 -t aeon-core:latest .
``` [cite: 77, 78, 79, 80]

**Example for arm64 (Raspberry Pi, Mac)** [cite: 81]
```bash
docker build --platform linux/arm64 --build-arg BUILD_FROM="ghcr.io/home-assistant/aarch64-base-python:3.14-alpine3.21" -t ghcr.io/siksil/qemuarm-64-airadeck-core:2026.4.2 .
``` [cite: 82, 83, 84, 85]

Push it to ghcr. [See 0.4 Upload Image to GHCR](#04-upload-image-to-ghcr). [cite: 86]

## 3.0 Supervisor [cite: 87]
*(Must run in a devcontainer)* [cite: 87]
* Check the links given in `FILES_TO_PATCH.txt`. [cite: 88]

**Build:** [cite: 89]
```bash
docker buildx build --platform linux/arm64 --tag YOUR_REGISTRY_PATH/aarch64-hassio-supervisor:latest --load .
``` [cite: 90, 91, 92]
* Upload to ghcr [cite: 93]

## 6. Operating System [cite: 94]
*(Dev container recommended)* [cite: 94]
* Check the file for replacements: `LIST_OF_FILES.txt`. [cite: 95]
* Enter Build: `./scripts/enter.sh` [cite: 96]
* Make: `make <arch>` [cite: 97]
  * **Example:** `make generic_aarch64` [cite: 98]
* Check `output>images`. [cite: 99]
