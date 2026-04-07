# Changelog

## v1.1.0 - 2026-04-07

- Added one-click uninstall support for Windows and Bash entrypoints.
- Added optional full data purge for state, workspace, config, and explicit git checkout paths.
- Windows uninstaller now prefers `openclaw uninstall` and falls back to task/startup/npm residue cleanup.
- Bash wrapper now supports `--uninstall --purge-data` and platform-specific manual cleanup fallbacks.
- Fixed the Windows git installer argument ordering bug for official `install.ps1` delegation.
- Rewrote the main Chinese documentation to include install and uninstall workflows.

## v1.0.0 - 2026-04-06

- Rebuilt the project as a thin wrapper around the official OpenClaw installers.
- Added stable Windows and Bash entrypoints for local and remote use.
- Removed unfinished offline and legacy custom installer logic.
- Aligned docs with supported behavior only.
- Added Windows branding banner with developer contact.
- Added Windows Git preflight auto-install to avoid official portable-Git bootstrap failures.
- Added Windows auto-elevation for real install runs.
