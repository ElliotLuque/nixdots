{ ... }:
{
  programs.zen-browser = {
    enable = true;

    profiles."*" = {
      mods = [
        "642854b5-88b4-4c40-b256-e035532109df"
      ];
    };
  };
}
