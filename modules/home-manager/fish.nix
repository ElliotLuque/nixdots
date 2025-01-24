{ host, ... }:
{
  programs.fish = {
    enable = true;
    generateCompletions = true;

    shellAliases = {
      gg = "lazygit";
      ls = "eza -lh --icons";
      lsa = "eza -lah --icons";
      tree = "eza --tree --icons";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      vim = "nvim";
      cat = "bat";
      top = "btop";
      mkdir = "mkdir -p";
      system-rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles/nixdots#${host}";
      wallpaper_random = "bash ~/dotfiles/nixdots/modules/home-manager/hyprland/scripts/swww_randomize.sh ~/dotfiles/nixdots/wallpaper/mocha/";
    };

    plugins = [
      # { name = "sponge"; src = pkgs.fishPlugins.sponge.src; }
    ];

    shellInit = ''
      set fish_greeting
    '';

    interactiveShellInit = ''
      nitch
    '';
  };
}
