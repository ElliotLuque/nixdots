# Contributing

Thanks for your interest in improving `nixdots`.

This repository is primarily my personal NixOS configuration, but reusable improvements, documentation fixes and well-scoped suggestions are welcome.

## Good contributions

Contributions are especially useful when they:

- fix a reproducibility or configuration issue;
- improve documentation for a reusable module;
- simplify or clarify existing Nix code;
- improve portability across machines;
- update configuration for upstream NixOS, Home Manager or Hyprland changes;
- improve security without introducing secrets or machine-specific assumptions.

## Before opening a pull request

1. Fork the repository and create a focused branch.
2. Keep changes small and scoped to one concern where possible.
3. Avoid adding personal credentials, API keys, private host data or unencrypted secrets.
4. Run relevant Nix checks before submitting.

At minimum, try:

```bash
nix flake check
```

If your change affects a specific host, evaluate or rebuild that host locally when possible.

## Pull requests

Please explain:

- what changed;
- why the change is useful;
- which host/module it affects;
- whether it changes existing behaviour;
- how you tested it.

Because this repository tracks a live personal setup, not every generally useful change will necessarily fit the configuration. In those cases, opening an issue first may be preferable.

## Security issues

Do not disclose credentials, private keys or exploitable security issues in a public issue. See [SECURITY.md](SECURITY.md) instead.
