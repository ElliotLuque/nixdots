"""Confirmed, commit-preserving merge for the explicitly selected Herdr space."""

from dataclasses import dataclass
import json
import os
from pathlib import Path
import subprocess
import sys


class WorkflowError(Exception):
    pass


def run(*args):
    result = subprocess.run(args, text=True, capture_output=True)
    if result.returncode:
        raise WorkflowError(result.stderr.strip() or result.stdout.strip() or f"{args[0]} failed")
    return result.stdout.strip()


def git(path, *args):
    return run("git", "-C", str(path), *args)


def workspace(herdr, workspace_id):
    response = json.loads(run(herdr, "workspace", "get", workspace_id))
    if "error" in response or "result" not in response:
        raise WorkflowError(f"Cannot read selected space: {response.get('error')}")
    worktree = response["result"]["workspace"].get("worktree")
    if not worktree or not worktree["is_linked_worktree"]:
        raise WorkflowError("Select a linked worktree, not the main checkout.")
    return Path(worktree["checkout_path"]).resolve(), Path(worktree["repo_root"]).resolve()


def clean_checkout(path):
    for marker in ("MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "rebase-merge", "rebase-apply", "sequencer"):
        marker_path = Path(git(path, "rev-parse", "--git-path", marker))
        if not marker_path.is_absolute():
            marker_path = path / marker_path
        if marker_path.exists():
            raise WorkflowError(f"Finish or abort the existing Git operation in {path} first.")
    if git(path, "status", "--porcelain", "--untracked-files=all", "--ignore-submodules=none"):
        raise WorkflowError(f"Commit or stash changes (including untracked files) in {path} first.")


@dataclass(frozen=True)
class Plan:
    source: Path
    target: Path
    source_branch: str
    target_branch: str
    source_head: str
    target_head: str


def inspect(source, target):
    source, target = source.resolve(), target.resolve()
    if source == target:
        raise WorkflowError("The main checkout cannot be merged and deleted.")
    for path in (source, target):
        if Path(git(path, "rev-parse", "--show-toplevel")).resolve() != path:
            raise WorkflowError(f"Not a checkout root: {path}")
        clean_checkout(path)
    source_common = Path(git(source, "rev-parse", "--path-format=absolute", "--git-common-dir")).resolve()
    target_common = Path(git(target, "rev-parse", "--path-format=absolute", "--git-common-dir")).resolve()
    if source_common != target_common:
        raise WorkflowError("The selected worktree and main checkout belong to different repositories.")
    if Path(git(source, "rev-parse", "--absolute-git-dir")).resolve() == source_common:
        raise WorkflowError("The selected checkout is not a linked worktree.")
    if Path(git(target, "rev-parse", "--absolute-git-dir")).resolve() != target_common:
        raise WorkflowError("The merge target must be the main checkout.")
    try:
        source_branch = git(source, "symbolic-ref", "--short", "HEAD")
        target_branch = git(target, "symbolic-ref", "--short", "HEAD")
    except WorkflowError as error:
        raise WorkflowError("Both checkouts must be on branches, not detached HEADs.") from error
    return Plan(source, target, source_branch, target_branch,
                git(source, "rev-parse", "HEAD"), git(target, "rev-parse", "HEAD"))


def merge_and_delete(herdr, workspace_id, plan):
    # Confirmation is not authority to merge a different branch or newer commits.
    if workspace(herdr, workspace_id) != (plan.source, plan.target) or inspect(plan.source, plan.target) != plan:
        raise WorkflowError("The checkouts changed since confirmation. Reopen the action and review them again.")
    # Detect conflicts without changing the target's index or working tree.
    git(plan.target, "merge-tree", "--write-tree", plan.target_head, plan.source_head)
    print(f"Merging {plan.source_branch} into {plan.target_branch}…", flush=True)
    git(plan.target, "-c", "merge.autoStash=false", "merge", "--no-edit", "--no-autostash", plan.source_head)
    # Hooks and concurrent agents may change either checkout. Never force cleanup.
    current = inspect(plan.source, plan.target)
    if (current.source_head != plan.source_head or current.source_branch != plan.source_branch
            or current.target_branch != plan.target_branch):
        raise WorkflowError("A checkout changed during the merge. The worktree has been kept.")
    git(plan.target, "merge-base", "--is-ancestor", plan.source_head, current.target_head)
    if workspace(herdr, workspace_id) != (plan.source, plan.target):
        raise WorkflowError("The selected space changed during the merge. No checkout was deleted.")
    print("Merge succeeded. Removing the worktree checkout…", flush=True)
    # Herdr removes the checkout and its space together. No --force, branch
    # deletion, shell interpolation, or independent filesystem cleanup.
    run(herdr, "worktree", "remove", "--workspace", workspace_id)
    print(f"Done. Branch {plan.source_branch} is retained; nothing was pushed.")


def main():
    herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
    # Popup context in upstream 0.9.3 refers to the focused space, not necessarily
    # the right-clicked one. The menu passes an explicit id; never fall back.
    workspace_id = os.environ.get("HERDR_MERGE_WORKSPACE_ID")
    try:
        if not workspace_id:
            raise WorkflowError("Open this action from a worktree's right-click menu.")
        plan = inspect(*workspace(herdr, workspace_id))
        print("Merge & delete worktree\n")
        print(f"From:   {plan.source_branch}\n        {plan.source}")
        print(f"Into:   {plan.target_branch}\n        {plan.target}\n")
        print("Preserves commits. Removes the checkout and closes its space.\n"
              "Keeps the branch. Does not push. Stop agents using this worktree first.\n"
              "Ignored files in the checkout are removed with it.\n")
        if input("Type 'merge' to continue; Enter cancels: ").strip() != "merge":
            return 0
        merge_and_delete(herdr, workspace_id, plan)
        return 0
    except (WorkflowError, OSError, ValueError, KeyError) as error:
        print(f"\nStopped: {error}\n\nNo further cleanup was attempted. If the merge succeeded, it remains\n"
              "in the target branch. Check Git status before retrying.", file=sys.stderr)
        try:
            input("\nPress Enter to close.")
        except EOFError:
            pass
        return 1
    except (EOFError, KeyboardInterrupt):
        return 130


if __name__ == "__main__":
    sys.exit(main())
