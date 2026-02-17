{ ... }:
{
  programs.atuin = {
    enable = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://api.atuin.sh";
      search_mode = "fuzzy";
      style = "full";
      inline_height = 20;
    };
    flags = [ "--disable-up-arrow" ];
  };
}
