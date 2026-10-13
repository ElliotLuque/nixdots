# Pi terminal statusline

The Pi Home Manager feature installs [Pi Terminal Statusline](https://github.com/ElliotLuque/pi-terminal-statusline), a separate repository, at `~/.pi/agent/extensions/terminal-statusline`. nixdots owns the Nix integration only; extension code, tests, previews, CI and npm releases live upstream.

## Source and updates

`flake.nix` declares a non-flake input:

```nix
pi-terminal-statusline = {
  url = "github:ElliotLuque/pi-terminal-statusline";
  flake = false;
};
```

`flake.lock` pins the exact upstream commit and content hash. `modules/ai/pi.nix` links `${inputs.pi-terminal-statusline}/extensions/statusline` into the user's extension directory. Pi loads `index.ts` and its sibling TypeScript files directly; activation needs no npm installation or build and does not depend on a local source checkout.

After an upstream change, update only this input and validate:

```sh
nix flake update pi-terminal-statusline
nix flake check --no-build
nix build .#checks.x86_64-linux.architecture
```

Apply Home Manager through your normal nixdots deployment, then run `/reload` in Pi or start a new session. Do not rebuild or activate the whole workstation just to preview upstream code; from a clone of the standalone repository, use:

```sh
pi --extension ./extensions/statusline/index.ts
```

## Footer and account usage

The footer has two rows. The directory is on row one; the Git branch, context percentage and other extensions' statuses are bottom-left. The provider logo, model and effort (in Pi's input-border color) are right on row one; the usage meters are right on row two. Each meter starts with the time left until its window resets (five-hour first, weekly second) instead of a `5h`/`week` label. The editor, header and session transcript are unchanged.

Colors use the terminal's ANSI palette, not a hard-coded Catppuccin RGB copy. The rest of Pi's UI uses the generated Living Code theme. Icons default to Nerd mode: provider logos come from the Herdr Agent Icons font already mapped in Kitty by the Radar feature. Use `/statusline icons unicode` or `ascii` as fallbacks. These preferences are writable user state in `~/.pi/agent/terminal-statusline.json`, not store-backed files.

Quota bars show account-wide **percentage used**, not remaining allowance or conversation cost. Pi's `openai` Sign in with ChatGPT token cannot read usage, so the extension asks `codex app-server` (run `codex login` once; Codex keeps its own token fresh). Legacy `openai-codex` and `anthropic` Claude OAuth are read directly. API keys/local models/custom proxies show unavailable quota; context and model data still work. Unavailable is `--`, loading is `...`, errors are `!`, and stale readings have `!` after the percentage. `/statusline` explains the last state.

Use `/statusline off` to restore the built-in footer or `/statusline on` to re-enable. Disable other footer-replacement extensions first. **Do not also install this package with `pi install` while the Nix-managed extension is enabled:** that loads the same behavior twice. To use the Git/npm package instead, remove this module's `home.file` declaration and apply Home Manager before installing it.

## Development and releases

Work on the extension in its own repository:

```sh
git clone https://github.com/ElliotLuque/pi-terminal-statusline.git
cd pi-terminal-statusline
npm ci --ignore-scripts
npm run release                 # Type-checks, tests and verifies the tarball; no publication
```

The standalone repository's CI runs the package checks. nixdots' architecture check verifies that its Home Manager extension source is the pinned upstream directory and that the entry point exists.

Git installation is available independently of npm publication. Marketplace publication remains pending npm authentication and final package-name confirmation; follow the [upstream release checklist](https://github.com/ElliotLuque/pi-terminal-statusline#mandatory-marketplace-release-checklist). A GitHub repository is not an npm release or proof of a Pi gallery listing.
