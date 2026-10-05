{ config, ... }:
{
  flake.modules.homeManager.cli = { pkgs, ... }: {
    imports = [ config.flake.modules.homeManager.ssh-client ];
    home.packages = with pkgs; [
      tokei
      termdown
      timr-tui
      btop
      bat
      eza
      fd
      fzf
      ripgrep
      ncdu
      duf
      delta
      zip
      jq
      glow
      pfetch-rs
      nerdfetch
      fastfetch
      nitch
      cowsay
      pipes-rs
      proton-pass-cli
    ];
    home.sessionVariables.PF_INFO = "ascii title os cpu uptime pkgs memory shell";
    programs = {
      bat.enable = true;
      btop.enable = true;
      yazi = {
        enable = true;
        shellWrapperName = "yy";
      };
      zoxide = {
        enable = true;
        enableFishIntegration = true;
        options = [ "--cmd cd" ];
      };
      atuin = {
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
      starship = {
        enable = true;
        enableFishIntegration = true;
        settings.character = {
          success_symbol = " [](bold blue)  [➜](bold green)";
          error_symbol = " [](bold blue)  [➜](bold red)";
        };
      };
      gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };
      lazygit = {
        enable = true;
        enableFishIntegration = true;
        settings.git.diffRenderers = [
          {
            colorArg = "always";
            command = "delta --dark --paging=never";
          }
        ];
      };
      git = {
        enable = true;
        settings = {
          init.defaultBranch = "main";
          pull.rebase = false;
          url."https://github.com/".insteadOf = [
            "gh:"
            "github:"
          ];
        };
      };
      delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          dark = true;
          navigate = true;
          line-numbers = true;
          side-by-side = false;
          syntax-theme = "Catppuccin Mocha";
          hyperlinks = true;
          file-style = "omit";
          hunk-header-style = "file line-number";
          hunk-header-decoration-style = "black box";
          hunk-header-file-style = "blue";
          hunk-header-line-number-style = "magenta";
        };
      };
    };
  };
}
