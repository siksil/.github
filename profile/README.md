# Inpui Rebranding & Architecture Workflow

This document outlines the architecture, update strategy, and exact workflow for maintaining the Inpui ecosystem, minimizing maintenance overhead while maximizing user-facing brand presence.

## 1. System Architecture (Debian Supervised)
To avoid the immense engineering burden of maintaining a custom embedded Linux operating system (like HAOS), the Inpui physical hubs use a **Supervised** architecture:
- **Base OS:** Standard, un-modified Debian Linux.
- **OS Updates:** Managed automatically via Debian's native `unattended-upgrades` (silent background security patching, automatic 3 AM reboots for kernel updates).
- **Docker Orchestrator:** The **Supervisor** runs as a privileged Docker container. It manages the lifecycle, OTA updates, and configuration of the `core` container and system plugins.
- **Application Engine:** The **Core** container runs the backend Python logic and serves the rebranded Inpui frontend.

## 2. Repositories You MUST Rebrand & Maintain
These are the user-facing repositories that must be forked and modified:

*   **`frontend`**: The web interface, UI components, SVG logos, CSS, and manifest.
    *   *Build:* Compiles via GitHub Actions into a `.whl` package (Python Wheel).
*   **`core`**: The main backend engine.
    *   *Build:* The CI/CD (`builder.yml`) fetches the frontend `.whl` artifact, pulls the secure upstream base image, and pushes the final rebranded `ghcr.io/siksil/amd64-homeassistant` images.
*   **`supervisor`**: The Docker orchestrator.
    *   *Modifications:* Needs to be forked to replace hardcoded `ghcr.io/home-assistant` URLs with `ghcr.io/siksil` so it pulls the custom Inpui core image during OTA updates.
*   **`supervised-installer`**: The Debian installation script.
    *   *Modifications:* Must be modified to install your custom `supervisor` container instead of the official one.
*   **`android` / `iOS`**: The mobile companion apps.

## 3. Repositories You Do NOT Touch
Maintaining these is an unnecessary burden and breaks community compatibility.
*   **`operating-system` (HAOS):** Replaced by standard Debian.
*   **`docker` (Base Images):** The upstream Alpine/Python base images containing FFmpeg and C-libraries.
*   **Third-Party Add-ons & HACS:** All community integrations and Add-ons (like Frigate) will continue to work perfectly because the internal Python namespace (`import homeassistant`) remains untouched.

## 4. Disaster Recovery & Backup Mirrors
To ensure Inpui remains operational even if the upstream Home Assistant repositories go offline, you should mirror the exact multi-architecture manifests of the following hidden infrastructure images into your `ghcr.io/siksil` registry:

1.  **Build Bases:** 
    *   `amd64-homeassistant-base` (Required for building Core)
    *   `amd64-base` (Required for building Supervisor)
2.  **CI/CD Tools:**
    *   `hassfest`
3.  **Supervisor Runtime Plugins:**
    *   `plugin-dns`, `plugin-multicast`, `plugin-audio`, `plugin-observer`, `plugin-cli`
4.  **Binaries:**
    *   `os-agent` (.deb releases)

*(Use the script in `base-mirror/mirror.sh` to quickly clone these from `ghcr.io/home-assistant` to `ghcr.io/siksil`.)*

## 5. Maintenance & OTA Update Flow
When you want to release a new version of Inpui to your users, you will utilize the GitHub Actions CI/CD pipeline. The core Supervisor will handle pulling and applying these updates automatically on the user's hub.

---

## 6. Build Instructions & CI/CD Pipeline

The build architecture is separated into two decoupled components: the **Frontend** and the **Core**. They communicate via `.whl` (Python Wheel) artifacts during the build phase.

### A. Local Development & Testing

#### Building the Frontend Locally
If you want to test UI changes locally without triggering a GitHub Action:
1. Navigate to the `frontend` repository.
2. Ensure you have Node.js and Yarn installed.
3. Run `yarn install` to fetch dependencies.
4. Run `script/build_frontend` to compile the frontend assets.
5. The output will be a Python wheel in the `dist/` directory (e.g., `dist/home_assistant_frontend-2026xxxx.x-py3-none-any.whl`).

#### Running the Core Locally
If you want to test the Core engine locally on your Mac/PC:
1. Navigate to the `core` repository.
2. Create and activate a Python virtual environment: `python3 -m venv venv && source venv/bin/activate`
3. Run `script/setup` to install dependencies.
4. **Link the Frontend:** If you built a custom frontend wheel locally (from Step A), install it into your core venv: `pip install ../frontend/dist/home_assistant_frontend-*.whl --force-reinstall`
5. Run the core locally: `hass -c config/`
6. The UI will be available at `http://localhost:8123`

### B. The GitHub Actions Pipeline (Production Builds)

The production pipeline is heavily optimized to save compute minutes and prevent accidental releases. It uses a **Dual-Channel Strategy** (`stable` and `dev`).

#### 1. Frontend Actions (Manual Trigger)
The frontend builds are **manual-only**. Committing code does not trigger a build.
*   **Build Stable (`build_stable.yaml`):** Go to the Actions tab and manually run this on the `master` branch. It will compile a stable wheel (e.g., `20260509.0`) and save it as an artifact named `wheels`.
*   **Build Dev (`build_dev.yaml`):** Manually run this on the `dev` branch. It will compile a nightly wheel (e.g., `20260509.0.dev0`) and save it as an artifact named `wheels-dev`.

#### 2. Core Actions (Release Trigger)
The core builds are triggered **only when you publish a GitHub Release**.
*   **Stable Release:** Create a standard Release in GitHub (e.g., Tag: `2026.5.0`). 
    *   The action (`builder.yml`) automatically downloads the `wheels` artifact from the frontend's `master` branch.
    *   It builds the production Docker image and pushes it to GHCR (`ghcr.io/siksil/amd64-homeassistant:2026.5.0` and `:stable`).
*   **Pre-Release (Dev):** Create a Release in GitHub, but check the **"Set as a pre-release"** checkbox (e.g., Tag: `2026.5.0.dev0`).
    *   The action automatically switches to the `dev` channel.
    *   It downloads the `wheels-dev` artifact from the frontend's `dev` branch.
    *   It builds the dev Docker image and pushes it to GHCR (`ghcr.io/siksil/amd64-homeassistant:2026.5.0.dev0` and `:dev`).

> **Important Versioning Note:** The core version is hardcoded in `pyproject.toml` and `inpui/const.py` (`MAJOR_VERSION`, `MINOR_VERSION`, `PATCH_VERSION`). Always update these files to match your Release tag before publishing a release!
