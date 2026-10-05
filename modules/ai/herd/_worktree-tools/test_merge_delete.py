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


class MergeDeleteTests(unittest.TestCase):
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

    def execute(self, plan=None):
        plan = plan or workflow.inspect(self.source, self.target)
        with patch.object(workflow, "run", side_effect=self.herdr), contextlib.redirect_stdout(io.StringIO()):
            workflow.merge_and_delete("fake-herdr", self.workspace_id, plan)

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

    def test_dirty_checkouts_are_rejected(self):
        for path in (self.source, self.target):
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

    def test_missing_explicit_selection_never_uses_focused_workspace(self):
        with patch.dict(os.environ, {}, clear=True), patch("builtins.input", return_value=""), \
                patch.object(workflow, "run") as run, contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(workflow.main(), 1)
            run.assert_not_called()

    def test_cancel_does_not_merge_or_delete(self):
        env = {"HERDR_BIN_PATH": "fake-herdr", "HERDR_MERGE_WORKSPACE_ID": self.workspace_id}
        before = workflow.git(self.target, "rev-parse", "HEAD")
        with patch.dict(os.environ, env), patch("builtins.input", return_value=""), \
                patch.object(workflow, "run", side_effect=self.herdr), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(workflow.main(), 0)
        self.assertEqual(workflow.git(self.target, "rev-parse", "HEAD"), before)
        self.assertFalse(self.removed)


if __name__ == "__main__":
    unittest.main()
