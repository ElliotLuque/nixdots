# Terminal Browser

The `herdr` Home Manager feature installs [terminal-browser](https://github.com/zenbu-labs/terminal-browser) on both workstations, pinned to **0.13.4**. The Linux x86-64 and ARM64 release archives have fixed SHA-256 hashes in `modules/ai/_terminal-browser-package.nix`. Nix patches the bundled Electron executable, native renderer, and agent-browser binary for NixOS; no curl installer or runtime dependency download is needed.

## Activation

Rebuild/activate the normal configuration for your host. Activation links the Nix-managed `zenbu-labs.terminal-browser` Herdr plugin. It does not stop the Herdr server or any running agent panes.

Herdr 0.9.3 does not populate its native right-click menu from plugin action contexts. `modules/ai/herd/_terminal-browser-menu.patch` adds the pane menu item explicitly and opens the plugin's `browser` split entrypoint beside the **clicked** pane. It also adds `plugin.pane.open` to the server's client-shell endpoint allowlist: upstream supports it on the CLI socket API but neither advertises nor accepts it on the right-click action transport.

This fix requires the rebuilt **server and client**. Reattaching only the client, reloading configuration, or relinking the plugin cannot update the running server's allowlist; an old server will still report “This server does not support plugin.pane.open yet.” Activate the rebuild, then restart Herdr only after saving work and deliberately ending the running pane sessions (or reboot when convenient). **Do not stop the server from an active agent session**, because that terminates its pane processes. Once the updated server is running, attach with the updated `herdr` binary.

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

## Rendering performance in Herdr

The packaged browser applies a small release-bundle patch in `modules/ai/_terminal-browser-performance.patch`:

- **Bounded frame rate:** `render.fps = display` uses at most **60 FPS in Herdr**. Electron can report a display frequency of `0` on Wayland or in headless mode; upstream treats this as uncapped rendering. Outside Herdr, an unknown frequency now falls back to 60 FPS rather than uncapped.
- **Whole-frame file transport:** automatic presenter/transport settings use `full` and `file` for Herdr panes. Herdr can forward one native file upload per scene. A scene with many image patches spills the remaining images into inline base64 transfers, which can saturate the terminal and delay input. Whole-frame files keep the native forwarding path usable and avoid shared-memory capability probing.
- **Per-session selection:** the profile follows the pane opening the browser, not the shared daemon's environment. Standalone and Herdr browsers can share a daemon without inheriting each other's defaults.

Explicit numeric/`uncapped` FPS settings, nonautomatic presenter/transport settings, and `TERMINAL_BROWSER_PRESENT` / `TERMINAL_BROWSER_FRAMES` overrides remain supported. If you previously selected `patched`, `animation`, or `inline`, restore automatic rendering to use the Herdr profile:

```bash
terminal-browser config unset render.fps
terminal-browser config unset render.presenter
terminal-browser config unset render.transport
```

Activate the rebuilt package/plugin and reopen browser panes to apply the new presenter/transport defaults. **No Herdr server restart is needed for this performance patch.** Do not shut down a shared browser daemon if other panes are still using it.

At 60 FPS, an isolated Herdr session with an animated 1744×2278 preview and a simulated Kitty host registered the browser in about 0.9 seconds, kept all uploads file-backed, and kept the main-loop API responsive over a 12-second sample. This exercises the rendering transport, not real Kitty GPU presentation; it does not establish a measured 15–20-second-to-subsecond improvement for the originally reported freeze.

Telemetry is disabled by default through `TERMINAL_BROWSER_NO_TELEMETRY=1` in the launcher. Browser settings and browsing state remain mutable in the normal upstream locations. Do not use `terminal-browser upgrade`, the curl installer, or `terminal-browser setup` to replace/reconfigure the Nix-managed installation; update the version and archive hashes here and rebuild instead. The Herdr manifest intentionally omits upstream's curl-based build step.

## Standalone selection and validation

`modules.homeManager.terminal-browser` installs only the package and shared skill. `modules.homeManager.terminal-browser-herdr` adds plugin registration; `herdr` imports it automatically.

```bash
nix build .#terminal-browser .#checks.x86_64-linux.terminal-browser .#checks.x86_64-linux.terminal-browser-performance --no-link
nix build .#herdr .#checks.x86_64-linux.herdr-terminal-browser-menu --no-link
nix build .#checks.x86_64-linux.architecture --no-link
nix flake check --no-build
```

The package check exercises version/help output, the bundled agent-browser, loading the native renderer, the skill's presence, and the installer-free Herdr manifest. The performance check executes the shipped bundle's render helpers and Session call sites without starting Chromium: it covers unknown/high/low display frequencies, explicit overrides, and alternating Herdr/standalone sessions in one daemon. The Herdr Rust check loads the server's actual advertised method list, verifies that the native pane menu dispatches an allowed right-split request targeting the clicked pane/workspace rather than the focused one, and checks the advertised plugin method's wire schema. ARM64 is packaged but has not been runtime-tested on the x86-64 workstation.
