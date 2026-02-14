{ ... }:
{
  xdg.configFile."opencode/plugins/notification.js" = {
    force = true;
    text = ''
    export const NotificationPlugin = async ({ $ }) => {
      const notify = async (message) => {
        const script = `if command -v notify-send >/dev/null 2>&1; then notify-send "OpenCode" "''${message}"; elif command -v dunstify >/dev/null 2>&1; then dunstify "OpenCode" "''${message}"; fi`
        try {
          await $`sh -lc ''${script}`
        } catch {}
      }

      return {
        event: async ({ event }) => {
          if (event.type === "session.idle") {
            await notify("Respuesta lista")
          }

          if (event.type === "session.error") {
            await notify("OpenCode encontro un error")
          }
        },
      }
    }
    '';
  };
}
