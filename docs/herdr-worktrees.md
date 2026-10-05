# Merge and delete a Herdr worktree

The `herdr` Home Manager module adds **Merge & delete worktree…** to the
right-click menu of **linked worktrees only**. It does not appear on ordinary
spaces, the main repository space (including collapsed worktree groups), tabs,
or panes. Rename, Close, New/Open worktree, and Delete worktree checkout retain
their existing behavior.

## Workflow

1. Stop agents, watchers, and terminals doing work in the checkout you intend to
   remove. Commit or stash changes in both that worktree and the main checkout.
2. Right-click the linked worktree and select **Merge & delete worktree…**.
3. Review the source and target branches and paths in the confirmation popup.
   The target is **the branch currently checked out in the main checkout**—not
   necessarily `main` or the remote default branch. The clicked worktree is used
   even if another space is focused.
4. Type `merge` to confirm, or press Enter to cancel.

The action uses a normal local Git merge, preserving the source commits rather
than squashing or rebasing them. It preflights conflicts with `git merge-tree`
without modifying either checkout. After a successful merge it asks Herdr to
remove the worktree checkout and close its space. The branch is retained and
nothing is pushed. Ignored files (for example build outputs and ignored local
configuration) are removed with the checkout.

Dirty checkouts, detached HEADs, in-progress Git operations, changed checkouts
since confirmation, and conflicts stop the workflow. Neither merging nor
removal is forced. If a merge succeeds but cleanup fails, the merge remains and
the worktree is retained; inspect Git status and address the reported problem
before retrying. Git hooks still run and can fail or change files. A Git merge
failure may leave a merge in progress in the main checkout; finish or abort it
there. Do not run this concurrently with other Git operations or active agents.

## Installation and activation

Rebuild/activate the normal NixOS or Home Manager configuration. The `herdr`
module installs the patched Herdr package and links the plugin automatically,
without replacing Herdr's mutable plugin registry or TOML configuration.
Restart Herdr with the newly installed binary to load the client-side menu
change. The existing running client does not gain this item just by reloading
configuration; plan a restart around active agents.

To build the packages without activating the host:

```bash
nix build .#herdr .#herdr-worktree-tools --no-link
```

Building alone does not install the plugin or update a running Herdr instance.

## Implementation and checks

- `modules/ai/herd/package.nix` provides the patched `packages.<system>.herdr`.
  All local Herdr integrations use this same package.
- `modules/ai/herd/_worktree-tools/context-menu.patch` adds a client-only menu
  action in Herdr 0.9.3. Plugin v1 has no native context-menu registration API,
  so an unpatched upstream binary cannot show the option.
- `modules/ai/herd/merge-delete.nix` packages the Python plugin with explicit
  runtime dependencies and links it during Home Manager activation.
- `modules/ai/herd/_worktree-tools/merge_delete.py` validates the clicked
  worktree, confirms, merges, and delegates removal to Herdr.

```bash
nix build .#checks.x86_64-linux.herdr-worktree-tools --no-link
nix build .#checks.x86_64-linux.herdr-worktree-menu --no-link
nix flake check --no-build
```

The first check runs real Git fixtures with a fake Herdr CLI, including
fast-forward/divergent merges, conflicts, dirty checkouts, cancellation, changed
branches, and failures. The second compiles the patched Herdr Rust unit tests
and checks menu visibility and propagation of the clicked (not focused)
workspace ID.

When updating the Herdr input, rebase the patch and rerun both checks. Remove the
patch when upstream exposes an equivalent native action or context-menu plugin
API. Do not use `herdr update` to replace the Nix-managed patched binary with an
upstream release; maintain the version through the flake instead.
