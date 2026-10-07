"""Keyboard-first popup for the merge workflow; Git work stays off the UI thread."""

from textual import work
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, VerticalScroll
from textual.widgets import Button, Input, Label, RichLog, Static

import merge_delete as workflow


class MergeDeleteApp(App):
    TITLE = "Merge & delete worktree"
    ENABLE_COMMAND_PALETTE = False
    BINDINGS = [
        Binding("escape", "cancel", "Cancel", priority=True),
        Binding("ctrl+c", "cancel", "Cancel", priority=True),
        Binding("ctrl+q", "cancel", "Cancel", priority=True),
        Binding("pageup", "review_up", show=False, priority=True),
        Binding("pagedown", "review_down", show=False, priority=True),
        Binding("up", "focus_previous", show=False, priority=True),
        Binding("down", "focus_next", show=False, priority=True),
        Binding("left", "focus_horizontal(-1)", show=False, priority=True),
        Binding("right", "focus_horizontal(1)", show=False, priority=True),
    ]
    CSS = """
    Screen { background: $background; }
    #title { height: auto; padding: 0 1 1 1; text-style: bold; }
    #review { height: 1fr; padding: 0 1; }
    #branches, #summary, #changes, #notice, #commit-help, #result {
        height: auto;
        margin-bottom: 1;
    }
    #branches { padding: 0 1; background: $surface; }
    #summary { text-style: bold; }
    #changes { color: $text; }
    #notice, #commit-help { color: $text-muted; }
    #commit-label { margin-bottom: 1; }
    #message { margin-bottom: 1; }
    #result { color: $text; border: solid $error; padding: 1; }
    #progress { min-height: 8; height: 1fr; border: solid $primary; }
    #actions { height: auto; padding: 0 1; align-horizontal: right; }
    Button { width: auto; min-width: 18; margin-left: 1; }
    #keys { height: auto; padding: 0 1; color: $text-muted; }
    .compact Button { min-width: 8; }
    .compact #confirm { width: 1fr; }
    """

    def __init__(self, herdr, workspace_id):
        super().__init__()
        self.theme = "catppuccin-mocha"
        self.herdr = herdr
        self.workspace_id = workspace_id
        self.plan = None
        self.busy = False
        self.finished = False
        self.exit_code = 0

    def compose(self) -> ComposeResult:
        yield Static(self.TITLE, id="title", markup=False)
        with VerticalScroll(id="review", can_focus=False):
            yield Static("Reading the selected worktree…", id="branches", markup=False)
            yield Static("", id="summary", markup=False)
            yield Static("", id="changes", markup=False)
            yield Static(
                "Keeps commits and the branch. Nothing is pushed.\n"
                "Deletes the checkout, its space, and ignored files.\n"
                "Stop agents and watchers before continuing.",
                id="notice", markup=False,
            )
            yield Static(
                "Commits ALL staged, unstaged, and untracked files.\n"
                "Ignored files excluded. Git hooks still run.",
                id="commit-help", markup=False,
            )
            yield Label("Commit message", id="commit-label")
            yield Input(placeholder="Describe the changes to commit", id="message")
            yield Static("", id="result", markup=False)
            yield RichLog(id="progress", wrap=True, markup=False, auto_scroll=True)
        with Horizontal(id="actions"):
            yield Button("Cancel", id="cancel")
            yield Button("Merge & delete", id="confirm", variant="primary", disabled=True)
        yield Static("Arrows/Tab: focus  Enter: select  Esc: cancel\nPgUp/PgDn: review", id="keys", markup=False)

    def on_mount(self):
        for name in ("summary", "changes", "commit-label", "message", "commit-help", "result", "progress"):
            self.query_one(f"#{name}").display = False
        self.query_one("#cancel", Button).focus()
        self.load_plan()

    def on_resize(self, event):
        self.set_class(event.size.width < 60, "compact")

    @work(thread=True)
    def load_plan(self):
        try:
            if not self.workspace_id:
                raise workflow.WorkflowError("Open this action from a worktree's right-click menu.")
            plan = workflow.inspect(*workflow.workspace(self.herdr, self.workspace_id))
        except (workflow.WorkflowError, OSError, ValueError, KeyError) as error:
            self.call_from_thread(self.show_error, str(error))
        else:
            self.call_from_thread(self.show_plan, plan)

    def show_plan(self, plan):
        self.plan = plan
        self.query_one("#title", Static).update(f"Merge & delete: {plan.source_branch} -> {plan.target_branch}")
        self.query_one("#branches", Static).update(
            f"From  {plan.source_branch}\n{plan.source}\n"
            f"Into  {plan.target_branch}  (main checkout)\n{plan.target}"
        )
        summary = f"{plan.commits_ahead} existing commit(s) to merge."
        if plan.changes:
            lines = plan.changes.splitlines()
            staged = sum(line[:1] not in (" ", "?") for line in lines)
            unstaged = sum(line[1:2] not in (" ", "?") for line in lines)
            untracked = sum(line.startswith("??") for line in lines)
            summary += f"\nChanges: {staged} staged / {unstaged} unstaged / {untracked} untracked."
            self.query_one("#changes", Static).update(plan.changes)
        else:
            summary += "\nWorktree is clean. No new commit is needed."
            if not plan.commits_ahead:
                summary += "\nAlready merged: only the checkout and its space will be removed."
        self.query_one("#summary", Static).update(summary)
        self.query_one("#summary").display = True
        for name in ("changes", "commit-label", "message", "commit-help"):
            self.query_one(f"#{name}").display = bool(plan.changes)
        confirm = self.query_one("#confirm", Button)
        confirm.label = "Commit, merge & delete" if plan.changes else "Merge & delete"
        confirm.refresh(layout=True)
        confirm.disabled = bool(plan.changes)
        # A clean checkout defaults to Cancel; Enter must not delete it accidentally.
        if plan.changes:
            self.call_after_refresh(self.focus_message)

    def focus_message(self):
        message = self.query_one("#message", Input)
        message.focus()
        message.scroll_visible(animate=False, immediate=True)

    def check_action(self, action, parameters):
        # Horizontal arrows edit text inside the input, navigate everywhere else.
        if action == "focus_horizontal" and isinstance(self.focused, Input):
            return False
        return super().check_action(action, parameters)

    def action_focus_horizontal(self, direction):
        if direction < 0:
            self.action_focus_previous()
        else:
            self.action_focus_next()

    def action_review_up(self):
        self.query_one("#review", VerticalScroll).scroll_page_up(animate=False)

    def action_review_down(self):
        self.query_one("#review", VerticalScroll).scroll_page_down(animate=False)

    def on_input_changed(self, event: Input.Changed):
        if self.plan and not self.busy and not self.finished:
            self.query_one("#confirm", Button).disabled = bool(self.plan.changes) and not event.value.strip()

    def on_input_submitted(self, event: Input.Submitted):
        # Enter in the message field advances to the explicit action, not deletion.
        if event.value.strip():
            self.query_one("#confirm", Button).focus()

    def on_button_pressed(self, event: Button.Pressed):
        if event.button.id == "cancel":
            self.action_cancel()
        elif event.button.id == "confirm" and self.plan and not self.busy and not self.finished:
            message = self.query_one("#message", Input).value.strip()
            if self.plan.changes and not message:
                self.query_one("#message", Input).focus()
                return
            self.busy = True
            self.query_one("#confirm", Button).disabled = True
            self.query_one("#cancel", Button).disabled = True
            self.query_one("#message", Input).disabled = True
            self.query_one("#progress").display = True
            self.query_one("#keys", Static).update("Working… keep this panel open until Git and cleanup finish.")
            self.perform_merge(message)

    @work(thread=True)
    def perform_merge(self, message):
        def report(text):
            self.call_from_thread(self.log_progress, text)
        try:
            workflow.merge_and_delete(self.herdr, self.workspace_id, self.plan, message, report)
        except (workflow.WorkflowError, OSError, ValueError, KeyError) as error:
            self.call_from_thread(self.show_error, str(error))
        else:
            self.call_from_thread(self.show_done)

    def log_progress(self, text):
        self.query_one("#progress", RichLog).write(text)

    def show_error(self, error):
        self.finish(1)
        if self.plan is None:
            self.query_one("#branches", Static).update("Cannot prepare this worktree.")
            self.query_one("#notice").display = False
        result = self.query_one("#result", Static)
        result.update(
            f"Stopped: {error}\n\n"
            "No further cleanup was attempted. Any successful commit or merge is kept.\n"
            "Check Git status in both checkouts, fix the problem, then reopen this action."
        )
        result.display = True
        self.call_after_refresh(result.scroll_visible, animate=False)

    def show_done(self):
        self.finish(0)
        self.query_one("#summary", Static).update("Merged successfully. The worktree and its space were removed.")

    def finish(self, code):
        self.busy = False
        self.finished = True
        self.exit_code = code
        self.query_one("#confirm", Button).disabled = True
        self.query_one("#message", Input).disabled = True
        cancel = self.query_one("#cancel", Button)
        cancel.disabled = False
        cancel.label = "Close"
        cancel.focus()
        self.query_one("#keys", Static).update("Enter / Esc: close")

    def action_cancel(self):
        # Git/hook processes cannot be safely canceled midway through mutation.
        if not self.busy:
            self.exit(self.exit_code)
