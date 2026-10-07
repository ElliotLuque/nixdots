"""Confirmed, commit-preserving merge for the explicitly selected Herdr space."""

from dataclasses import dataclass
import hashlib
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
    return result.stdout.rstrip("\n")


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


def no_operation(path):
    for marker in ("MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "rebase-merge", "rebase-apply", "sequencer"):
        marker_path = Path(git(path, "rev-parse", "--git-path", marker))
        if not marker_path.is_absolute():
            marker_path = path / marker_path
        if marker_path.exists():
            raise WorkflowError(f"Finish or abort the existing Git operation in {path} first.")


def status(path):
    return git(path, "status", "--porcelain", "--untracked-files=all", "--ignore-submodules=none")


def clean_checkout(path):
    no_operation(path)
    if status(path):
        raise WorkflowError(f"Commit or stash changes (including untracked files) in {path} first.")


def source_state(path):
    """Fingerprint contents as well as status: editing an already dirty file matters."""
    digest = hashlib.sha256()
    for args in (("status", "--porcelain=v2", "-z", "--untracked-files=all", "--ignore-submodules=none"),
                 ("diff", "--no-ext-diff", "--no-textconv", "--binary", "--ignore-submodules=none"),
                 ("diff", "--cached", "--no-ext-diff", "--no-textconv", "--binary", "--ignore-submodules=none")):
        value = git(path, *args)
        if args[0] == "status":
            for entry in value.split("\0"):
                fields = entry.split(" ")
                if fields[0] in ("1", "2") and fields[2].startswith("S") and fields[2][2:] != "..":
                    raise WorkflowError("Commit or stash changes inside submodules first; they cannot be committed here.")
        digest.update(value.encode())
        digest.update(b"\0")
    # Use NUL-separated filenames; spaces/newlines and symlinks are valid Git paths.
    names = git(path, "ls-files", "--others", "--exclude-standard", "-z").split("\0")
    for name in filter(None, names):
        file = path / name
        digest.update(os.fsencode(name))
        digest.update(str(file.lstat().st_mode).encode())
        if file.is_symlink():
            digest.update(os.fsencode(os.readlink(file)))
        else:
            with file.open("rb") as stream:
                for chunk in iter(lambda: stream.read(65536), b""):
                    digest.update(chunk)
        digest.update(b"\0")
    return digest.hexdigest()


@dataclass(frozen=True)
class Plan:
    source: Path
    target: Path
    source_branch: str
    target_branch: str
    source_head: str
    target_head: str
    changes: str
    source_state: str
    commits_ahead: int


def inspect(source, target):
    source, target = source.resolve(), target.resolve()
    if source == target:
        raise WorkflowError("The main checkout cannot be merged and deleted.")
    for path in (source, target):
        if Path(git(path, "rev-parse", "--show-toplevel")).resolve() != path:
            raise WorkflowError(f"Not a checkout root: {path}")
        no_operation(path)
    clean_checkout(target)
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
                git(source, "rev-parse", "HEAD"), git(target, "rev-parse", "HEAD"),
                status(source), source_state(source),
                int(git(source, "rev-list", "--count", f"{target_branch}..HEAD")))


def validate(herdr, workspace_id, plan):
    # Confirmation is not authority to commit changed files or merge newer commits.
    if workspace(herdr, workspace_id) != (plan.source, plan.target) or inspect(plan.source, plan.target) != plan:
        raise WorkflowError("The checkouts changed since confirmation. Reopen the action and review them again.")


def merge_and_delete(herdr, workspace_id, plan, message=None, report=print):
    validate(herdr, workspace_id, plan)
    if plan.changes:
        if not message or not message.strip():
            raise WorkflowError("Write a commit message before committing and merging these changes.")
        report("Committing staged, unstaged, and untracked changes…")
        git(plan.source, "add", "--all")
        git(plan.source, "commit", "-m", message.strip())
        clean_checkout(plan.source)
        committed = inspect(plan.source, plan.target)
        if (committed.source_branch != plan.source_branch
                or committed.target_branch != plan.target_branch
                or committed.target_head != plan.target_head
                or git(plan.source, "rev-parse", "HEAD^") != plan.source_head):
            raise WorkflowError("A checkout changed during the commit. The worktree has been kept.")
        plan = committed
        validate(herdr, workspace_id, plan)
    # Detect conflicts without changing the target's index or working tree.
    report("Checking for merge conflicts…")
    git(plan.target, "merge-tree", "--write-tree", plan.target_head, plan.source_head)
    report(f"Merging {plan.source_branch} into {plan.target_branch}…")
    git(plan.target, "-c", "merge.autoStash=false", "merge", "--no-edit", "--no-autostash", plan.source_head)
    # Hooks and concurrent agents may change either checkout. Never force cleanup.
    clean_checkout(plan.source)
    current = inspect(plan.source, plan.target)
    if (current.source_head != plan.source_head or current.source_branch != plan.source_branch
            or current.target_branch != plan.target_branch):
        raise WorkflowError("A checkout changed during the merge. The worktree has been kept.")
    git(plan.target, "merge-base", "--is-ancestor", plan.source_head, current.target_head)
    if workspace(herdr, workspace_id) != (plan.source, plan.target):
        raise WorkflowError("The selected space changed during the merge. No checkout was deleted.")
    report("Merge succeeded. Removing the worktree checkout…")
    # Herdr removes the checkout and its space together. No --force, branch
    # deletion, shell interpolation, or independent filesystem cleanup.
    run(herdr, "worktree", "remove", "--workspace", workspace_id)
    report(f"Done. Branch {plan.source_branch} is retained; nothing was pushed.")


def main():
    herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
    # Popup context in upstream 0.9.3 refers to the focused space, not necessarily
    # the right-clicked one. The menu passes an explicit id; never fall back.
    workspace_id = os.environ.get("HERDR_MERGE_WORKSPACE_ID")
    # Import lazily so the Git workflow can also be tested without a terminal UI.
    from merge_delete_ui import MergeDeleteApp
    return MergeDeleteApp(herdr, workspace_id).run() or 0


if __name__ == "__main__":
    sys.exit(main())
