"""Compact, panel-based TUI; Git work stays off the UI thread."""

from rich.text import Text
from textual import work
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, VerticalScroll
from textual.widgets import Button, Input, RichLog, Static

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
    #review {
        height: 1fr;
        min-height: 4;
        border: round $secondary;
        border-title-color: $secondary;
        border-title-style: bold;
        padding: 0 1;
        scrollbar-size: 1 1;
    }
    #branches, #summary, #changes, #result { height: auto; }
    #branches { margin-bottom: 1; }
    #summary { color: $primary; text-style: bold; }
    #changes { color: $text; }
    #notice { height: auto; color: $text-muted; }
    #message {
        height: 3;
        border: round $secondary;
        border-title-color: $secondary;
        background: $background;
    }
    #message:focus { border: round $primary; border-title-color: $primary; }
    #result { color: $text; }
    #progress { height: 8; background: $background; }
    #actions { height: 1; align-horizontal: right; }
    #actions Button {
        height: 1;
        width: auto;
        min-width: 0;
        margin-left: 1;
        background: $surface;
        color: $text;
        text-style: bold;
    }
    #actions #confirm { color: $success; }
    #actions Button:hover, #actions Button:focus {
        background: $secondary;
        background-tint: transparent;
        color: $background;
        text-style: bold;
    }
    #actions Button:disabled { color: $text-muted; }
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
        with VerticalScroll(id="review", can_focus=False):
            yield Static("Reading the selected worktree…", id="branches", markup=False)
            yield Static("", id="summary", markup=False)
            yield Static("", id="changes", markup=False)
            yield Static("", id="result", markup=False)
            yield RichLog(id="progress", wrap=True, markup=False, auto_scroll=True)
        # The form and actions stay visible even when the review has many files.
        yield Input(placeholder="Describe the changes", id="message")
        yield Static(
            "Deletes checkout, space + ignored files. No push.\n"
            "Keeps branch. Stop agents and watchers first.",
            id="notice", markup=False,
        )
        with Horizontal(id="actions"):
            yield Button("Cancel", id="cancel", compact=True)
            yield Button("Merge & delete", id="confirm", compact=True, disabled=True)

    def on_mount(self):
        review = self.query_one("#review", VerticalScroll)
        review.border_title = "Merge & delete"
        message = self.query_one("#message", Input)
        message.border_title = "Commit message"
        message.border_subtitle = "All non-ignored changes · hooks run"
        self.query_one("#progress", RichLog).can_focus = False
        for name in ("summary", "changes", "message", "result", "progress"):
            self.query_one(f"#{name}").display = False
        self.query_one("#cancel", Button).focus()
        self.load_plan()

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
        routes = Text()
        routes.append(plan.source_branch, "bold #cba6f7")
        routes.append("  →  ", "#a6adc8")
        routes.append(plan.target_branch, "bold #a6e3a1")
        routes.append(f"\nfrom {plan.source}\ninto {plan.target}", "#a6adc8")
        self.query_one("#branches", Static).update(routes)
        self.query_one("#review", VerticalScroll).border_subtitle = plan.target.name
        summary = f"{plan.commits_ahead} commit(s)"
        changes = Text()
        if plan.changes:
            lines = plan.changes.splitlines()
            staged = sum(line[:1] not in (" ", "?") for line in lines)
            unstaged = sum(line[1:2] not in (" ", "?") for line in lines)
            untracked = sum(line.startswith("??") for line in lines)
            summary += f" · {staged} staged · {unstaged} unstaged · {untracked} new"
            for index, line in enumerate(lines):
                if index:
                    changes.append("\n")
                changes.append(line[:2], "#f9e2af" if line.startswith("??") else "#a6e3a1")
                changes.append(line[2:])
        else:
            summary += " · clean"
            changes.append("No new commit needed." if plan.commits_ahead else "Already merged. Remove checkout and space only.", "#a6adc8")
        self.query_one("#summary", Static).update(summary)
        self.query_one("#changes", Static).update(changes)
        self.query_one("#summary").display = True
        self.query_one("#changes").display = True
        self.query_one("#message").display = bool(plan.changes)
        confirm = self.query_one("#confirm", Button)
        confirm.label = "Commit, merge & delete" if plan.changes else "Merge & delete"
        confirm.refresh(layout=True)
        confirm.disabled = bool(plan.changes)
        # A clean checkout defaults to Cancel; Enter must not delete it accidentally.
        if plan.changes:
            self.call_after_refresh(self.focus_message)

    def focus_message(self):
        self.query_one("#message", Input).focus()

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
        panel = (self.query_one("#progress", RichLog) if self.query_one("#progress").display
                 else self.query_one("#review", VerticalScroll))
        panel.scroll_page_up(animate=False)

    def action_review_down(self):
        panel = (self.query_one("#progress", RichLog) if self.query_one("#progress").display
                 else self.query_one("#review", VerticalScroll))
        panel.scroll_page_down(animate=False)

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
                self.focus_message()
                return
            self.busy = True
            self.query_one("#confirm", Button).disabled = True
            self.query_one("#cancel", Button).disabled = True
            self.query_one("#message", Input).disabled = True
            for name in ("branches", "summary", "changes", "message"):
                self.query_one(f"#{name}").display = False
            self.query_one("#review", VerticalScroll).border_title = "Working…"
            self.query_one("#progress").display = True
            self.query_one("#notice", Static).update("Git is running. Keep this panel open until it finishes.")
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
        review = self.query_one("#review", VerticalScroll)
        review.border_title = "Stopped"
        review.styles.border = ("round", "#f38ba8")
        review.styles.border_title_color = "#f38ba8"
        for name in ("branches", "summary", "changes", "progress"):
            self.query_one(f"#{name}").display = False
        result = self.query_one("#result", Static)
        result.update(
            f"{error}\n\n"
            "Any successful commit or merge is kept. No further cleanup was attempted.\n"
            "Check Git status in both checkouts, fix the problem, then reopen this action."
        )
        result.display = True
        self.query_one("#notice", Static).update("The worktree is kept unless removal already succeeded.")
        self.call_after_refresh(result.scroll_visible, animate=False)

    def show_done(self):
        self.finish(0)
        review = self.query_one("#review", VerticalScroll)
        review.border_title = "Merged & removed"
        review.styles.border = ("round", "#a6e3a1")
        review.styles.border_title_color = "#a6e3a1"
        self.query_one("#notice", Static).update("Branch retained. Nothing pushed.")

    def finish(self, code):
        self.busy = False
        self.finished = True
        self.exit_code = code
        self.query_one("#confirm", Button).disabled = True
        self.query_one("#confirm").display = False
        self.query_one("#message", Input).disabled = True
        self.query_one("#message").display = False
        cancel = self.query_one("#cancel", Button)
        cancel.disabled = False
        cancel.label = "Close"
        cancel.refresh(layout=True)
        cancel.focus()

    def action_cancel(self):
        # Git/hook processes cannot be safely canceled midway through mutation.
        if not self.busy:
            self.exit(self.exit_code)
