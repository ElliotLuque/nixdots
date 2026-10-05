import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("hunk", {
    description: "Open a live Hunk diff in a sibling Herdr pane (/hunk [right|down])",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui") return;
      if (process.env.HERDR_ENV !== "1" || !process.env.HERDR_PANE_ID) {
        ctx.ui.notify("Run Pi inside Herdr to use /hunk. Otherwise run hunk diff --watch in another terminal.", "warning");
        return;
      }
      const direction = args.trim() || "right";
      if (direction !== "right" && direction !== "down") {
        ctx.ui.notify("Usage: /hunk [right|down]", "warning");
        return;
      }
      try {
        const split = await pi.exec("@herdr@", [
          "pane", "split", "--current", "--direction", direction,
          "--cwd", ctx.cwd, "--no-focus",
        ], { timeout: 10000 });
        if (split.code !== 0) throw new Error(split.stderr || split.stdout);
        const pane = JSON.parse(split.stdout).result?.pane?.pane_id;
        if (typeof pane !== "string" || !pane) throw new Error("Herdr did not return a pane ID.");
        const run = await pi.exec("@herdr@", [
          "pane", "run", pane, "@hunk@ diff --watch --agent-notes",
        ], { timeout: 10000 });
        if (run.code !== 0) throw new Error(`Pane ${pane} was created, but Hunk could not start: ${run.stderr || run.stdout}`);
        ctx.ui.notify(`Live Hunk review opened in ${pane}. Pi keeps focus.`, "info");
      } catch (error) {
        ctx.ui.notify(`Could not open Hunk: ${error instanceof Error ? error.message : String(error)}`, "error");
      }
    },
  });
}
