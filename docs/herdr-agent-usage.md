# Herdr Agent Usage

The `herdr` Home Manager feature includes [herdr-agent-usage](https://github.com/levi-qiao/herdr-agent-usage), pinned to v1.6.2 in `flake.lock`. Both workstation hosts receive it through `modules/ai/herd/agent-usage.nix`. This stable release still uses upstream's previous plugin id and binary name, **`herdr-agent-quota`**; the Nix package is `herdr-agent-usage` and also provides that name as a CLI alias.

## Nix and Radar integration

Nix builds the Rust binary from the pinned source and vendored, hash-checked Cargo dependencies. No Rust toolchain or downloads are needed during activation. The package preserves the upstream `target/release` layout, replaces its Cargo build action with a no-op, and uses an absolute shell for plugin commands.

Radar still owns the sidebar's identity/state rows, font and activity ordering. `_append_usage.py` appends usage-only rows to Radar's default and per-agent rows at build time, preserving its TOML comments. These show model, context, short/weekly/monthly quota and errors; empty tokens collapse. This is a stacked usage presentation, not a second set of brand icons or a replacement Agents panel.

The usage package is patched so configure/uninstall never rewrite Herdr's config or install/remove fonts, and its order-setting function never replaces Radar's agent view. Its reversible agent hook installer and credential-scoped collectors remain available. Popup settings cannot replace Nix's row layout or Radar's ordering.

Activation links the plugin into Herdr's existing registry, then invokes its configure action after Home Manager links the new config. The action selects this repository's clients (`claude,codex,opencode,pi`), saves the stacked layout, installs the Claude statusLine collector, reloads config and starts collection. Upstream preserves/chains an existing command statusLine and backs it up in the plugin state directory. Hook files and plugin caches are mutable user state, not Nix store files.

## Keys and verification

- `prefix+shift+q`: usage settings
- `prefix+shift+r`: refresh usage
- `prefix+r`: Radar's activity/recent toggle, unchanged
- `prefix+a`: Herdr Projects popup, unchanged

After rebuilding the desired host:

```sh
herdr plugin list
herdr plugin log list --plugin herdr-agent-quota --limit 20
herdr integration status
```

Plugin actions run asynchronously: check the configure/refresh logs rather than treating command submission as proof of successful setup. To repair or start collection without restarting Herdr:

```sh
herdr plugin action invoke herdr-agent-quota.configure
```

Attribution requires the relevant Herdr agent integration. If `herdr integration status` reports a selected client missing, install that specific integration (`herdr integration install claude`, `codex`, `opencode` or `pi`). Restart only the affected agent pane if it needs to load a newly installed integration; Claude also needs a new turn to publish statusLine observations. **Do not stop the Herdr server**: that ends running pane processes.

Quota depends on supported account credentials and identifiable sessions; an installed plugin cannot guarantee that every provider will expose a quota. Pi currently uses canonical Codex quota only when the recorded account matches. No credentials are added to Nix. Other supported agents can be configured deliberately through the plugin CLI/settings; they are not enabled by this repository's configure action.

The icon font and Kitty mapping come from Radar; open a new terminal window if necessary. Neither build checks nor activation verify visual rendering in a live terminal.

## Validation

```sh
nix build .#herdr-agent-usage .#checks.x86_64-linux.herdr-agent-usage --no-link
nix flake check --no-build
```

The package runs upstream's library tests. Its imperative config round-trip suite assumes ownership of Herdr/font files and is not run for the patched package. The repository integration check instead parses the composed sidebar and exercises Claude hook installation/removal against a temporary home with a store-backed Herdr config, verifying that unrelated settings and the config symlink survive. Tests never contact the live server or provider endpoints.
