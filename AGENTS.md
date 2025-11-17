# Repository Guidelines

## Project Structure & Module Organization
The repository is intentionally small: `install_smi_usb_display.sh` is the lone executable and sits at the root with the operational references (`README.md`, `QUICKSTART.md`, `SETUP_GUIDE.md`, `TECHNICAL.md`, `TROUBLESHOOTING.md`, `COMMANDS.md`). Treat those Markdown guides as the contract for flows, diagnostics, and hardware checks—update them whenever installer behavior or prerequisites change. Keep temporary artifacts under `/tmp/smi_install_*` and never commit the proprietary SMI `.run` payload or generated binaries.

## Build, Test, and Development Commands
- `shellcheck install_smi_usb_display.sh` — primary linting gate; resolve or justify every warning before opening a PR.
- `sudo bash install_smi_usb_display.sh` — end-to-end validation; run from the directory that also contains `SMIUSBDisplay-driver.2.22.1.0.run` on Ubuntu 24.04 with kernel ≥6.14.
- `dkms status | grep evdi` — confirm EVDI 1.14.11 is registered with DKMS after edits that touch dependencies.
- `lsmod | grep evdi` and `sudo journalctl -u smiusbdisplay.service -f` — fast post-install checks that the module loads and the systemd service stays healthy.

## Coding Style & Naming Conventions
Stick to POSIX-friendly Bash, 4-space indentation inside control blocks, and lower_snake_case helper names (`print_status`, `install_evdi`). Reserve ALL_CAPS for constants (color codes, installer paths) and double-quote every variable to avoid globbing or word-splitting surprises. Keep the script self-contained, leverage the existing `print_*` helpers for user-facing output, and only add comments when documenting hardware quirks or non-obvious patches.

## Testing Guidelines
There is no automated test suite, so rely on scenario coverage. Exercise clean installs, reruns on already provisioned hosts, missing `.run` payloads, absent EVDI modules, and Secure Boot enabled/disabled flows. Capture `dkms status`, `systemctl status smiusbdisplay.service`, and `sudo dmesg | tail -50` after each scenario and attach concise excerpts to your PR.

## Commit & Pull Request Guidelines
History currently shows a single initial commit, so set the tone with imperative subjects (e.g., `Add secure boot retry prompt`) and descriptive bodies that include rationale plus testing evidence. Branch names like `feature/evdi-1.15` or `fix/mok-flow` keep CI noise low. Every PR needs a short summary, verification commands with outcomes, referenced docs, and links to related issues. Never commit SMI installers, signed modules, or secrets—reference their paths instead.

## Security & Configuration Tips
Most steps require sudo, so document any new privileged operations or kernel-module touches. Keep Machine Owner Keys in `/var/lib/shim-signed/mok/`, gitignore those paths, and wipe temporary work directories (`rm -rf \"$WORK_DIR\"`) to avoid leaving patched installers or keys behind. Redact device identifiers before sharing logs.
