"""Real Git fixtures; a fake Herdr CLI exercises the selected-workspace contract."""

import contextlib
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import merge_delete as workflow


class GitFixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.target = self.root / "main checkout"
        self.source = self.root / "feature checkout"
        self.target.mkdir()
        workflow.git(self.target, "init", "-b", "main")
        workflow.git(self.target, "config", "user.name", "Test")
        workflow.git(self.target, "config", "user.email", "test@example.invalid")
        workflow.git(self.target, "config", "commit.gpgsign", "false")
        self.commit(self.target, "base", "base\n")
        workflow.git(self.target, "worktree", "add", "-b", "feature", str(self.source))
        self.commit(self.source, "feature", "feature\n", filename="feature.txt")
        self.workspace_id = "ws_clicked_not_focused"
        self.removed = False
        self.real_run = workflow.run

    def commit(self, path, message, content, filename="file.txt"):
        (path / filename).write_text(content)
        workflow.git(path, "add", "--", filename)
        workflow.git(path, "commit", "-m", message)

    def herdr(self, *args):
        if args[0] != "fake-herdr":
            return self.real_run(*args)
        if args[1:] == ("workspace", "get", self.workspace_id):
            return json.dumps({"id": "cli:workspace:get", "result": {"type": "workspace_info", "workspace": {
                "worktree": {"checkout_path": str(self.source), "repo_root": str(self.target),
                             "is_linked_worktree": True}}}})
        if args[1:] == ("worktree", "remove", "--workspace", self.workspace_id):
            # Mirrors Herdr's non-forced git worktree removal, with no branch delete.
            self.real_run("git", "-C", str(self.target), "worktree", "remove", str(self.source))
            self.removed = True
            return "{}"
        self.fail(f"Unexpected API call: {args}")

    def execute(self, plan=None, message=None):
        plan = plan or workflow.inspect(self.source, self.target)
        with patch.object(workflow, "run", side_effect=self.herdr), contextlib.redirect_stdout(io.StringIO()):
            workflow.merge_and_delete("fake-herdr", self.workspace_id, plan, message)


class MergeDeleteTests(GitFixture):
    def test_fast_forward_removes_only_selected_checkout_and_keeps_branch(self):
        source_head = workflow.git(self.source, "rev-parse", "HEAD")
        self.execute()
        self.assertTrue(self.removed)
        self.assertFalse(self.source.exists())
        self.assertEqual(workflow.git(self.target, "rev-parse", "HEAD"), source_head)
        self.assertEqual(workflow.git(self.target, "rev-parse", "feature"), source_head)

    def test_divergent_history_preserves_both_branches(self):
        self.commit(self.target, "main change", "main\n", filename="main.txt")
        source_head = workflow.git(self.source, "rev-parse", "HEAD")
        target_head = workflow.git(self.target, "rev-parse", "HEAD")
        self.execute()
        for head in (source_head, target_head):
            workflow.git(self.target, "merge-base", "--is-ancestor", head, "HEAD")
        self.assertEqual(len(workflow.git(self.target, "rev-list", "--parents", "-n", "1", "HEAD").split()), 3)

    def test_conflict_does_not_touch_target_or_remove_worktree(self):
        self.commit(self.target, "main conflict", "main version\n")
        self.commit(self.source, "feature conflict", "feature version\n")
        before = workflow.git(self.target, "rev-parse", "HEAD")
        with self.assertRaises(workflow.WorkflowError):
            self.execute()
        self.assertFalse(self.removed)
        self.assertTrue(self.source.exists())
        self.assertEqual(workflow.git(self.target, "rev-parse", "HEAD"), before)
        self.assertEqual(workflow.git(self.target, "status", "--porcelain"), "")

    def test_dirty_target_is_rejected(self):
        for path in (self.target,):
            for filename in ("file.txt", "untracked.txt"):
                with self.subTest(path=path, filename=filename):
                    before = (path / filename).read_text() if (path / filename).exists() else None
                    (path / filename).write_text("dirty\n")
                    with self.assertRaises(workflow.WorkflowError):
                        workflow.inspect(self.source, self.target)
                    if before is None:
                        (path / filename).unlink()
                    else:
                        (path / filename).write_text(before)
        self.assertFalse(self.removed)

    def test_in_progress_git_operation_is_rejected_even_with_dirty_source(self):
        (self.source / "new.txt").write_text("new\n")
        marker = Path(workflow.git(self.source, "rev-parse", "--git-path", "MERGE_HEAD"))
        marker.write_text(workflow.git(self.target, "rev-parse", "HEAD") + "\n")
        with self.assertRaisesRegex(workflow.WorkflowError, "existing Git operation"):
            self.execute(message="Do not commit during a merge")
        self.assertFalse(self.removed)

    def test_dirty_submodule_contents_must_be_committed_inside_submodule(self):
        subrepo = self.root / "subrepo"
        subrepo.mkdir()
        workflow.git(subrepo, "init", "-b", "main")
        workflow.git(subrepo, "config", "user.name", "Test")
        workflow.git(subrepo, "config", "user.email", "test@example.invalid")
        workflow.git(subrepo, "config", "commit.gpgsign", "false")
        self.commit(subrepo, "submodule base", "base\n")
        workflow.git(self.source, "-c", "protocol.file.allow=always", "submodule", "add", str(subrepo), "sub")
        workflow.git(self.source, "commit", "-m", "Add submodule")
        for filename in ("file.txt", "untracked.txt"):
            with self.subTest(filename=filename):
                file = self.source / "sub" / filename
                old = file.read_text() if file.exists() else None
                file.write_text("dirty\n")
                with self.assertRaisesRegex(workflow.WorkflowError, "inside submodules"):
                    self.execute(message="Cannot commit nested contents")
                if old is None:
                    file.unlink()
                else:
                    file.write_text(old)
        self.assertFalse(self.removed)

    def test_detached_head_and_main_checkout_are_rejected(self):
        with self.assertRaises(workflow.WorkflowError):
            workflow.inspect(self.target, self.target)
        workflow.git(self.source, "checkout", "--detach")
        with self.assertRaises(workflow.WorkflowError):
            workflow.inspect(self.source, self.target)

    def test_foreign_repo_is_rejected(self):
        other = self.root / "other"
        other.mkdir()
        workflow.git(other, "init", "-b", "main")
        with self.assertRaises(workflow.WorkflowError):
            workflow.inspect(self.source, other)

    def test_changed_source_or_target_after_confirmation_is_rejected(self):
        for path in (self.source, self.target):
            with self.subTest(path=path):
                plan = workflow.inspect(self.source, self.target)
                self.commit(path, "concurrent change", "concurrent\n", filename="concurrent.txt")
                with self.assertRaisesRegex(workflow.WorkflowError, "changed since confirmation"):
                    self.execute(plan)
                self.assertFalse(self.removed)

    def test_merge_failure_keeps_checkout(self):
        hook = self.target / ".git/hooks/pre-merge-commit"
        hook.write_text("#!/bin/sh\nexit 1\n")
        hook.chmod(0o755)
        self.commit(self.target, "diverge", "main\n", filename="main.txt")
        with self.assertRaises(workflow.WorkflowError):
            self.execute()
        self.assertFalse(self.removed)
        self.assertTrue(self.source.exists())

    def test_cleanup_failure_keeps_successful_merge(self):
        def fail_remove(*args):
            if args[:3] == ("fake-herdr", "worktree", "remove"):
                raise workflow.WorkflowError("checkout locked")
            return self.herdr(*args)
        plan = workflow.inspect(self.source, self.target)
        with patch.object(workflow, "run", side_effect=fail_remove), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(workflow.WorkflowError, "checkout locked"):
                workflow.merge_and_delete("fake-herdr", self.workspace_id, plan)
        self.assertTrue(self.source.exists())
        workflow.git(self.target, "merge-base", "--is-ancestor", plan.source_head, "HEAD")

    def test_commits_staged_unstaged_and_untracked_then_merges(self):
        (self.source / "file.txt").write_text("staged\n")
        workflow.git(self.source, "add", "file.txt")
        (self.source / "file.txt").write_text("unstaged after staging\n")
        (self.source / "new file.txt").write_text("new\n")
        workflow.git(self.source, "config", "core.excludesFile", str(self.root / "ignore"))
        (self.root / "ignore").write_text("ignored.txt\n")
        (self.source / "ignored.txt").write_text("not committed\n")
        self.execute(message="Finish the feature")
        self.assertTrue(self.removed)
        self.assertEqual(workflow.git(self.target, "log", "-1", "--format=%s"), "Finish the feature")
        self.assertEqual((self.target / "file.txt").read_text(), "unstaged after staging\n")
        self.assertEqual((self.target / "new file.txt").read_text(), "new\n")
        self.assertFalse((self.target / "ignored.txt").exists())

    def test_no_existing_feature_commit_can_commit_and_merge(self):
        workflow.git(self.source, "reset", "--hard", "main")
        (self.source / "new.txt").write_text("first change\n")
        self.assertEqual(workflow.inspect(self.source, self.target).commits_ahead, 0)
        self.execute(message="First feature commit")
        self.assertTrue(self.removed)
        self.assertTrue((self.target / "new.txt").exists())

    def test_clean_already_merged_worktree_needs_no_new_commit(self):
        workflow.git(self.source, "reset", "--hard", "main")
        before = workflow.git(self.target, "rev-parse", "HEAD")
        self.execute()
        self.assertTrue(self.removed)
        self.assertEqual(workflow.git(self.target, "rev-parse", "HEAD"), before)

    def test_dirty_worktree_requires_nonempty_message_without_staging(self):
        (self.source / "new.txt").write_text("new\n")
        before = workflow.git(self.source, "status", "--porcelain")
        for message in (None, "", "  "):
            with self.subTest(message=message), self.assertRaisesRegex(workflow.WorkflowError, "commit message"):
                self.execute(message=message)
            self.assertEqual(workflow.git(self.source, "status", "--porcelain"), before)
            self.assertFalse(self.removed)

    def test_edits_to_already_dirty_files_invalidate_confirmation(self):
        for filename in ("file.txt", "untracked.txt"):
            with self.subTest(filename=filename):
                (self.source / filename).write_text("first\n")
                plan = workflow.inspect(self.source, self.target)
                (self.source / filename).write_text("second\n")
                with self.assertRaisesRegex(workflow.WorkflowError, "changed since confirmation"):
                    self.execute(plan, message="Do not commit changed files")
        self.assertFalse(self.removed)

    def test_untracked_whitespace_names_and_symlinks_are_committed(self):
        (self.source / " leading\nfile ").write_text("new\n")
        (self.source / "link").symlink_to("file.txt")
        self.execute(message="Add unusual filenames")
        self.assertEqual((self.target / " leading\nfile ").read_text(), "new\n")
        self.assertTrue((self.target / "link").is_symlink())

    def test_commit_failure_keeps_worktree_and_target_unchanged(self):
        hook = self.target / ".git/hooks/pre-commit"
        hook.write_text("#!/bin/sh\necho 'commit rejected' >&2\nexit 1\n")
        hook.chmod(0o755)
        before = workflow.git(self.target, "rev-parse", "HEAD")
        (self.source / "new.txt").write_text("new\n")
        with self.assertRaisesRegex(workflow.WorkflowError, "commit rejected"):
            self.execute(message="Rejected")
        self.assertFalse(self.removed)
        self.assertTrue(self.source.exists())
        self.assertEqual(workflow.git(self.target, "rev-parse", "HEAD"), before)
        self.assertIn("A  new.txt", workflow.git(self.source, "status", "--porcelain"))

    def test_hook_changes_after_commit_stop_before_merge(self):
        hook = self.target / ".git/hooks/post-commit"
        hook.write_text("#!/bin/sh\nprintf 'hook change' > file.txt\n")
        hook.chmod(0o755)
        (self.source / "new.txt").write_text("new\n")
        before = workflow.git(self.target, "rev-parse", "HEAD")
        with self.assertRaises(workflow.WorkflowError):
            self.execute(message="Keep this commit")
        self.assertFalse(self.removed)
        self.assertEqual(workflow.git(self.target, "rev-parse", "HEAD"), before)
        self.assertEqual(workflow.git(self.source, "log", "-1", "--format=%s"), "Keep this commit")

    def test_conflict_after_commit_preserves_new_commit(self):
        self.commit(self.target, "main conflict", "main\n")
        (self.source / "file.txt").write_text("feature\n")
        before = workflow.git(self.target, "rev-parse", "HEAD")
        with self.assertRaises(workflow.WorkflowError):
            self.execute(message="Feature conflict")
        self.assertFalse(self.removed)
        self.assertEqual(workflow.git(self.target, "rev-parse", "HEAD"), before)
        self.assertEqual(workflow.git(self.target, "status", "--porcelain"), "")
        self.assertEqual(workflow.git(self.source, "log", "-1", "--format=%s"), "Feature conflict")


if __name__ == "__main__":
    unittest.main()
