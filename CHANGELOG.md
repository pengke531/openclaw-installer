# Changelog

## v1.3.2 - 2026-04-09

- Switched the macOS wrapper path from official `install.sh` to official `install-cli.sh`.
- Reduced macOS dependence on Homebrew for one-click installs on clean machines.
- Kept Linux/WSL on the standard official `install.sh` path.

## v1.3.1 - 2026-04-09

- Changed the installer default OpenClaw target from `latest` to the pinned stable version `2026.4.2`.
- Updated help text, diagnostics, and docs so default one-click installs now consistently target 4.2.

## v1.3.0 - 2026-04-08

- Added self-healing bootstrap for OpenClaw 2026.4.8 environments with broken or incompatible existing config.
- Installers now detect config read failures, back up the old config, and write a minimal local config to finish gateway/token/dashboard setup.
- Strengthened one-click deploy behavior on machines with old plugin residue or broken channel config.

## v1.1.0 - 2026-04-07

- Added one-click uninstall support for Windows and Bash entrypoints.
- Added optional full data purge for state, workspace, config, and explicit git checkout paths.
- Windows uninstaller now prefers `openclaw uninstall` and falls back to task/startup/npm residue cleanup.
- Bash wrapper now supports `--uninstall --purge-data` and platform-specific manual cleanup fallbacks.
- Fixed the Windows git installer argument ordering bug for official `install.ps1` delegation.
- Rewrote the main Chinese documentation to include install and uninstall workflows.

## v1.2.0 - 2026-04-08

- Added first-launch bootstrap after install: gateway token generation, gateway service install/refresh, and dashboard auto-open.
- Added Windows npm cache permission repair alongside prefix and PATH fixes.
- Added `-NoDashboard` / `--no-dashboard` to opt out of auto-opening the Control UI.
- Updated docs to describe the new post-install dashboard/token flow.

## v1.0.0 - 2026-04-06

- Rebuilt the project as a thin wrapper around the official OpenClaw installers.
- Added stable Windows and Bash entrypoints for local and remote use.
- Removed unfinished offline and legacy custom installer logic.
- Aligned docs with supported behavior only.
- Added Windows branding banner with developer contact.
- Added Windows Git preflight auto-install to avoid official portable-Git bootstrap failures.
- Added Windows auto-elevation for real install runs.
