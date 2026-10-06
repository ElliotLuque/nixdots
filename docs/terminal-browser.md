# Terminal Browser

The `herdr` Home Manager feature installs [terminal-browser](https://github.com/zenbu-labs/terminal-browser) on both workstations, pinned to **0.13.4**. The Linux x86-64 and ARM64 release archives have fixed SHA-256 hashes in `modules/ai/_terminal-browser-package.nix`. Nix patches the bundled Electron executable, native renderer, and agent-browser binary for NixOS; no curl installer or runtime dependency download is needed.

## Activation

Rebuild/activate the normal configuration for your host. Activation links the Nix-managed `zenbu-labs.terminal-browser` Herdr plugin. It does not stop the Herdr server or any running agent panes.

After activation, run `/reload` in Pi to discover the new skill, or start a new Pi session. The upstream portable skill is installed at `~/.agents/skills/terminal-browser/SKILL.md`, which Pi discovers natively. No Claude-specific plugin, Pi extension, or MCP server is required for browser control.

## Usage

Inside Herdr, choose **Open terminal-browser (right split)** from the pane’s right-click menu or the global plugin actions, or run:

```bash
terminal-browser open http://localhost:3000 --split right
terminal-browser open ./report.html --split down
terminal-browser ls --json
terminal-browser action -- snapshot
terminal-browser action -- click @e14
terminal-browser action -- eval 'document.title'
terminal-browser action done
```

In Pi, `/skill:terminal-browser` explicitly loads the instructions. You can then ask Pi to open a local preview or inspect an already-open browser. Always open in a split from an agent session rather than taking over its pane. The action CLI uses the active browser in the current terminal tab by default; use the browser/tab selectors from `terminal-browser ls` when there are multiple targets.

Upstream already implements Herdr detection, splitting and graphics transport. A Kitty-graphics-capable terminal (for example Kitty or Ghostty) is still required for visual rendering. The package checks validate the CLI and native renderer loading, not live graphics, mouse input, or end-to-end browser control in a terminal.

Telemetry is disabled by default through `TERMINAL_BROWSER_NO_TELEMETRY=1` in the launcher. Browser settings and browsing state remain mutable in the normal upstream locations. Do not use `terminal-browser upgrade`, the curl installer, or `terminal-browser setup` to replace/reconfigure the Nix-managed installation; update the version and archive hashes here and rebuild instead. The Herdr manifest intentionally omits upstream's curl-based build step.

## Standalone selection and validation

`modules.homeManager.terminal-browser` installs only the package and shared skill. `modules.homeManager.terminal-browser-herdr` adds plugin registration; `herdr` imports it automatically.

```bash
nix build .#terminal-browser .#checks.x86_64-linux.terminal-browser --no-link
nix build .#checks.x86_64-linux.architecture --no-link
nix flake check --no-build
```

The dedicated check exercises version/help output, the bundled agent-browser, loading the native renderer, the skill's presence, and the installer-free Herdr manifest. ARM64 is packaged but has not been runtime-tested on the x86-64 workstation.
